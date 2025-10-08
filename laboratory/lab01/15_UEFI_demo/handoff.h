// handoff.h
#include <stdint.h>
typedef struct {
    // UEFI Memory Map
    uint64_t mmap_phys;   // 物理アドレス
    uint64_t mmap_size;
    uint64_t mmap_desc_size;
    uint32_t mmap_desc_version;

    // Graphics (GOP)
    uint64_t fb_phys;
    uint32_t fb_width, fb_height, fb_pitch; // pitch=bytes/line
    uint32_t fb_size;                       // bits per pixel
    uint32_t fb_bpp;                        // bits per pixel

    // ACPI
    uint64_t rsdp_phys;

    // Misc
    uint64_t uefi_system_table;  // 参照したければ
    uint64_t reserved[8];
} handoff_t;
