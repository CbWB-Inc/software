
#include <stdint.h>
#include <stddef.h>
#include <efi.h>
#include <efilib.h>
#include "handoff.h"
#include "log.h"
#include "common.h"

extern uint64_t *pml4;
extern uint64_t *framebuffer_phys;

void show_memmap(handoff_t* info){

    ps("Memory map:\n");
    uint8_t* ptr = (uint8_t*)info->mmap_phys;
    // puthex(meminfo->map_size);putc('\n');                // 確認
    // puthex(meminfo->descriptor_size);putc('\n');         // 確認
    for (UINTN i = 0; i < info->mmap_size; i += info->mmap_desc_size) {
        EFI_MEMORY_DESCRIPTOR* desc = (EFI_MEMORY_DESCRIPTOR*)(ptr + i);
        // 使えるメモリ領域だけ出力（例: EfiConventionalMemory == 7）
        // puthex(desc->Type);putc('\n');                    // 確認
        if (desc->Type == EfiConventionalMemory) {
            ps("Usable: 0x");
            ph(desc->PhysicalStart);
            ps(" - 0x");
            ph(desc->PhysicalStart + desc->NumberOfPages * 4096);
            ps(" (0x");
            ph(desc->NumberOfPages);
            ps(" pages)\n");
        }
    }
}

// デバッグ用の関数
void test_memory_access(void) {
    ps("=== Memory Access Test ===\n");
    
    // 1. 低位メモリテスト (0x1000)
    ps("Testing low memory (0x1000)...\n");
    volatile uint32_t* test_low = (volatile uint32_t*)0x1000;
    *test_low = 0xDEADBEEF;
    if (*test_low == 0xDEADBEEF) {
        ps("Low memory test: PASS\n");
    } else {
        ps("Low memory test: FAIL\n");
    }
    
    // 2. 高位メモリテスト (0x300000)
    ps("Testing high memory (0x300000)...\n");
    volatile uint32_t* test_high = (volatile uint32_t*)0x300000;
    *test_high = 0xCAFEBABE;
    if (*test_high == 0xCAFEBABE) {
        ps("High memory test: PASS\n");
    } else {
        ps("High memory test: FAIL\n");
    }
    
    // 3. スタックテスト
    ps("Testing stack access...\n");
    volatile uint64_t stack_test = 0x12345678;
    uint64_t rsp;
    asm volatile("mov %%rsp, %0" : "=r"(rsp));
    ps("Current RSP: 0x"); ph(rsp); pc('\n');
    ps("Stack test value: 0x"); ph(stack_test); pc('\n');
    
    // 4. フレームバッファテスト (まだ設定していない場合はスキップ)
    if (framebuffer_phys != 0) {
        ps("Testing framebuffer (0x400000)...\n");
        volatile uint32_t* test_fb = (volatile uint32_t*)0x400000;
        uint32_t old_val = *test_fb;
        *test_fb = 0xFF00FF00;
        if (*test_fb == 0xFF00FF00) {
            ps("Framebuffer test: PASS\n");
        } else {
            ps("Framebuffer test: FAIL\n");
        }
        *test_fb = old_val; // 元に戻す
    }
    
    ps("=== Memory Access Test Complete ===\n");
}

// ページテーブルエントリを表示する関数
void dump_page_table_entry(uint64_t vaddr) {
    uint64_t pml4_idx = (vaddr >> 39) & 0x1FF;
    uint64_t pdpt_idx = (vaddr >> 30) & 0x1FF;
    uint64_t pd_idx = (vaddr >> 21) & 0x1FF;
    uint64_t pt_idx = (vaddr >> 12) & 0x1FF;
    
    ps("Virtual address 0x"); ph(vaddr); ps(":\n");
    ps("  PML4["); ph(pml4_idx); ps("] = 0x"); ph(pml4[pml4_idx]); pc('\n');
    
    if (!(pml4[pml4_idx] & PAGE_PRESENT)) {
        ps("  PML4 entry not present!\n");
        return;
    }
    
    uint64_t* pdpt = (uint64_t*)(pml4[pml4_idx] & ~0xFFF);
    ps("  PDPT["); ph(pdpt_idx); ps("] = 0x"); ph(pdpt[pdpt_idx]); pc('\n');
    
    if (!(pdpt[pdpt_idx] & PAGE_PRESENT)) {
        ps("  PDPT entry not present!\n");
        return;
    }
    
    uint64_t* pd = (uint64_t*)(pdpt[pdpt_idx] & ~0xFFF);
    ps("  PD["); ph(pd_idx); ps("] = 0x"); ph(pd[pd_idx]); pc('\n');
    
    if (!(pd[pd_idx] & PAGE_PRESENT)) {
        ps("  PD entry not present!\n");
        return;
    }
    
    uint64_t* pt = (uint64_t*)(pd[pd_idx] & ~0xFFF);
    ps("  PT["); ph(pt_idx); ps("] = 0x"); ph(pt[pt_idx]); pc('\n');
    
    if (!(pt[pt_idx] & PAGE_PRESENT)) {
        ps("  PT entry not present!\n");
    } else {
        uint64_t phys_addr = pt[pt_idx] & ~0xFFF;
        ps("  Physical address: 0x"); ph(phys_addr); pc('\n');
    }
}

void dump_page_table(uint64_t* pml4) {
    for (size_t i = 0; i < 512; i++) {
        if (!(pml4[i] & PAGE_PRESENT)) continue;
        if (pml4[i] > 0xF000000000000000) {
            ps("PML4["); ph(i); ps("] = "); ph(pml4[i]); pc('\n');
        }

        uint64_t* pdpt = phys_to_virt(pml4[i] & ~0xFFF);
        for (size_t j = 0; j < 512; j++) {
            if (!(pdpt[j] & PAGE_PRESENT)) continue;
            if (pdpt[j] > 0xF000000000000000) {
                ps("  PDPT["); ph(j); ps("] = "); ph(pdpt[j]); pc('\n');
            }

            uint64_t* pd = phys_to_virt(pdpt[j] & ~0xFFF);
            for (size_t k = 0; k < 512; k++) {
                if (!(pd[k] & PAGE_PRESENT)) continue;
                if (pd[k] > 0xF000000000000000) {
                    ps("    PD["); ph(k); ps("] = "); ph(pd[k]); pc('\n');
                }

                uint64_t* pt = phys_to_virt(pd[k] & ~0xFFF);
                for (size_t l = 0; l < 512; l++) {
                    if (!(pt[l] & PAGE_PRESENT)) continue;
                    ps("      PT["); ph(l); ps("] = "); ph(pt[l]); pc('\n');
                }
                ps("      PT end\n");
            }
            ps("    PD end\n");
        }
        ps("  PDPT end\n");
    }
    ps("PML4 end\n");
}
