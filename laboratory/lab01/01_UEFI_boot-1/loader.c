#include <efi.h>
#include <efilib.h>
#include <stdint.h>

#include "handoff.h"

#define KERNEL_ADDR 0x100000

static EFI_GUID ACPI2_GUID = ACPI_20_TABLE_GUID;
static EFI_GUID ACPI_GUID  = ACPI_TABLE_GUID;

typedef struct {
    handoff_t h;
    // mmapバッファを後ろに置くと便利
    UINT8 mmap_buf[128*1024];
} LOADER_PACK;

typedef void (*KernelEntry)(handoff_t*);

static BOOLEAN pick_direct_fb_mode(EFI_GRAPHICS_OUTPUT_PROTOCOL* gop) {
    for (UINT32 m = 0; m < gop->Mode->MaxMode; m++) {
        EFI_GRAPHICS_OUTPUT_MODE_INFORMATION *info; UINTN sz;
        if (EFI_ERROR(uefi_call_wrapper(gop->QueryMode, 4, gop, m, &sz, &info))) continue;
        if (info->PixelFormat != PixelBltOnly) {                 // ←直書き可
            if (m != gop->Mode->Mode) uefi_call_wrapper(gop->SetMode, 2, gop, m);
            return TRUE;
        }
    }
    return FALSE; // 直書き不可モードしかない（Blt専用）
}

EFI_STATUS EFIAPI efi_main(EFI_HANDLE image, EFI_SYSTEM_TABLE *st) {

    InitializeLib(image, st);
    Print(L"UEFI bootloader start\n");
    Print(L"ST=%lx BS=%lx Sig=%lx Rev=%x\n",
          (unsigned long)(UINTN)st,
          (unsigned long)(UINTN)st->BootServices,
          (unsigned long)st->Hdr.Signature, st->Hdr.Revision);

    // 作業バッファ確保
    LOADER_PACK *pack;
    uefi_call_wrapper(BS->AllocatePool, 3, EfiLoaderData,
                      sizeof(LOADER_PACK), (void**)&pack);
    ZeroMem(pack, sizeof(*pack));

    // GOP 取得
    EFI_GRAPHICS_OUTPUT_PROTOCOL *gop = NULL;
    EFI_GUID gopGuid = EFI_GRAPHICS_OUTPUT_PROTOCOL_GUID;
    EFI_STATUS status = uefi_call_wrapper(BS->LocateProtocol, 3, &gopGuid, NULL, (void**)&gop);
    if (EFI_ERROR(status)) {
        Print(L"GOP not found\n");
        return status;
    }
    BOOLEAN direct_ok = pick_direct_fb_mode(gop);
    Print (L"direct_fb_mode : %x\n", direct_ok);

    pack->h.fb_phys   = gop->Mode->FrameBufferBase;
    pack->h.fb_size   = gop->Mode->FrameBufferSize;
    pack->h.fb_width  = gop->Mode->Info->HorizontalResolution;
    pack->h.fb_height = gop->Mode->Info->VerticalResolution;
    pack->h.fb_pitch  = gop->Mode->Info->PixelsPerScanLine * 4; // BGRA32前提
    pack->h.fb_bpp    = 32;
    Print(L"FrameBufferBase = 0x%lx\n", gop->Mode->FrameBufferBase);

    // ACPI RSDP
    void *rsdp = NULL;
    for (UINTN i=0;i<st->NumberOfTableEntries;i++){
        EFI_CONFIGURATION_TABLE *t = &st->ConfigurationTable[i];
        if (CompareGuid(&t->VendorGuid, &ACPI2_GUID) ||
            CompareGuid(&t->VendorGuid, &ACPI_GUID)) {
            rsdp = t->VendorTable;
            break;
        }
    }
    pack->h.rsdp_phys = (UINT64)(UINTN)rsdp;
    pack->h.uefi_system_table = (UINT64)(UINTN)st;

    // --- カーネルファイル読み込み ---
    EFI_FILE_IO_INTERFACE *io;
    EFI_FILE_HANDLE root, kernel_file;
    EFI_GUID sfsp_guid = EFI_SIMPLE_FILE_SYSTEM_PROTOCOL_GUID;
    EFI_GUID lip_guid  = EFI_LOADED_IMAGE_PROTOCOL_GUID;

    EFI_LOADED_IMAGE *loaded_image;
    status = uefi_call_wrapper(BS->HandleProtocol, 3,
        image, &lip_guid, (void**)&loaded_image);
    if (EFI_ERROR(status)) {
        Print(L"Failed to get loaded image: %r\n", status);
        return status;
    }

    status = uefi_call_wrapper(BS->HandleProtocol, 3,
        loaded_image->DeviceHandle, &sfsp_guid, (void**)&io);
    if (EFI_ERROR(status)) {
        Print(L"Failed to get filesystem protocol: %r\n", status);
        return status;
    }

    status = uefi_call_wrapper(io->OpenVolume, 2, io, &root);
    if (EFI_ERROR(status)) {
        Print(L"Failed to open volume: %r\n", status);
        return status;
    }

    status = uefi_call_wrapper(root->Open, 5, root,
        (void**)&kernel_file, L"\\kernel.bin", EFI_FILE_MODE_READ, 0);
    if (EFI_ERROR(status)) {
        Print(L"Failed to open kernel.bin: %r\n", status);
        return status;
    }

    // --- サイズ取得 ---
    EFI_FILE_INFO *info;
    UINTN info_size = sizeof(EFI_FILE_INFO) + 100;
    status = uefi_call_wrapper(BS->AllocatePool, 3, EfiLoaderData, info_size, (void**)&info);
    if (EFI_ERROR(status)) return status;

    status = uefi_call_wrapper(kernel_file->GetInfo, 4,
        kernel_file, &gEfiFileInfoGuid, &info_size, info);
    if (EFI_ERROR(status)) {
        Print(L"GetInfo failed: %r\n", status);
        return status;
    }

    UINTN kernel_size = info->FileSize;
    Print(L"kernel size = %d bytes\n", kernel_size);

    EFI_PHYSICAL_ADDRESS kernel_phys = KERNEL_ADDR;
    UINTN pages = (kernel_size + 0xFFF) >> 12;
    status = uefi_call_wrapper(BS->AllocatePages, 4,
        AllocateAddress, EfiLoaderCode, pages, &kernel_phys);
    if (EFI_ERROR(status)) { Print(L"Alloc kernel @1M failed: %r\n", status); return status; }

    // --- カーネル読み込み ---
    void* kernel_buf = (void*)(UINTN)kernel_phys;
    status = uefi_call_wrapper(kernel_file->Read, 3, kernel_file, &kernel_size, kernel_buf);
    if (EFI_ERROR(status)) {
        Print(L"Failed to read kernel: %r\n", status);
        return status;
    }

    Print(L"Copied kernel to %x\n", KERNEL_ADDR);

   // --- GetMemoryMap（ExitBootServicesの直前に“最新”を取る）
    UINTN mmap_size = sizeof(pack->mmap_buf);
    UINTN map_key   = 0;
    UINTN desc_size = 0;
    UINT32 desc_ver = 0;

    // --- メモリマップ取得（余裕を持たせる） ---
    UINTN mem_map_size = 0;

    status = uefi_call_wrapper(BS->GetMemoryMap, 5,
        &mem_map_size, NULL, &map_key, &desc_size, &desc_ver);
    if (status != EFI_BUFFER_TOO_SMALL) {
        Print(L"Failed to get memory map size: %r\n", status);
        return status;
    }

    UINTN buffer_size = mem_map_size + desc_size * 8;
    UINTN num_pages = (buffer_size + 0xFFF) / 0x1000;
    EFI_PHYSICAL_ADDRESS mem_map_phys = 0;
    status = uefi_call_wrapper(BS->AllocatePages, 4,
        AllocateAddress, EfiLoaderData, num_pages, &mem_map_phys);
    if (EFI_ERROR(status)) {
        Print(L"Failed to allocate mem_map: %r\n", status);
        return status;
    }
    EFI_MEMORY_DESCRIPTOR* mem_map = (EFI_MEMORY_DESCRIPTOR*)(UINTN)mem_map_phys;

    Print(L"Bye UEFI BIOS & boot ver 0.6.5 !!\n");

retry_getmap:
    {
        EFI_STATUS s = uefi_call_wrapper(BS->GetMemoryMap, 5,
            &mmap_size, (EFI_MEMORY_DESCRIPTOR*)pack->mmap_buf,
            &map_key, &desc_size, &desc_ver);
        if (s == EFI_BUFFER_TOO_SMALL) {
            // まれに足りない時がある。余白を少し要求し直す
            mmap_size += 4096;
            goto retry_getmap;
        } else if (EFI_ERROR(s)) {
            Print(L"GetMemoryMap failed: %r\n", s);
            return s;
        }
    }

    pack->h.mmap_phys       = (UINT64)(UINTN)pack->mmap_buf;
    pack->h.mmap_size       = mmap_size;
    pack->h.mmap_desc_size  = desc_size;
    pack->h.mmap_desc_version = desc_ver;
 
    // 後始末（BootServices が生きているうちに）
    // kernel_file->Close(kernel_file);
    // root->Close(root);
    // uefi_call_wrapper(BS->FreePool, 1, info);

    // --- BootServices 終了 ---
    status = uefi_call_wrapper(BS->ExitBootServices, 2, image, map_key);
    if (EFI_ERROR(status)) {
        Print(L"Failed to exit boot services: %r\n", status);
        return status;
    }

    KernelEntry entry = (KernelEntry)KERNEL_ADDR;
    entry(&pack->h);
    return EFI_SUCCESS;

}
