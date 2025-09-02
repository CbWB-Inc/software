// kernel.c
#include <stdint.h>
#include <stddef.h>
#include "handoff.h"
#include "log.h"
#include "common.h"


uint64_t* pml4;
uint64_t* framebuffer_phys = (uint64_t*)0x80000000;
uint64_t* next_sys_page = (uint64_t*)0x3BB8C000;
uint64_t* page_table_base = (uint64_t*)0x3BB8C000;
uintptr_t stack_top, stack_base;
uint64_t* fb_virt = (uint64_t*)0x00400000;         // 物理0x80000000を仮想0x00400000にマップする
uint64_t* fb = (uint64_t*)0x00400000;

void init_paging(void* page_table_base, uint64_t framebuffer_addr);
void show_memmap(handoff_t* info);

void kernel_main(handoff_t* info) {
    // ここでBoot Servicesは死んでいる。なにもかも自前の世界。

    // ログの初期化
    log_init(LOG_DBGCON|LOG_COM1);
    
    // メモリマップの出力（確認）
    show_memmap(info);

    // ページング
    init_paging(page_table_base, info->fb_phys);
  
    // FrameBufferアクセス
    // volatile uint8_t* fb = (volatile uint8_t*)(uintptr_t)info->fb_phys;
    // volatile uint8_t* fb = (volatile uint8_t*)(uintptr_t)0x80000000;
    size_t pitch  = info->fb_pitch;             // bytes/line
    size_t height = info->fb_height;
    size_t sz     = pitch * height;             // total bytes

    uint32_t *p = (uint32_t*)fb;
    for (uint32_t i=0; i<100; i++){
        for (uint32_t j=0; j<100; j++) {
            p[(100 + j )* 1280 + 100 + i] = 0x0000ff00;
        } 
    }

    __asm__ __volatile__("hlt");
}

void init_paging(void* page_table_base, uint64_t framebuffer_addr) {
    ps("Starting paging initialization...\n");
    
    // 複数のページテーブルを使用
    pml4      = alloc_sys_page();
    uint64_t* pdpt      = alloc_sys_page();
    uint64_t* pd        = alloc_sys_page();
    uint64_t* pt_low    = alloc_sys_page();   // 低位アドレス用 (0-2MB)
    uint64_t* pt_high   = alloc_sys_page();   // 高位アドレス用 (2-4MB)
    uint64_t* pt_stack  = alloc_sys_page();   // スタック用 (約512MB)
    uint64_t* pt_fb1    = alloc_sys_page();   // フレームバッファ用 0~2M
    uint64_t* pt_fb2    = alloc_sys_page();   // フレームバッファ用 2~4M
    uint64_t* pt_fb3    = alloc_sys_page();   // フレームバッファ用 4~6M
    uint64_t* pt_fb4    = alloc_sys_page();   // フレームバッファ用 6~8M
    // 全てのエントリをクリア
    for (int i = 0; i < 512; i++) {
        pml4[i] = pdpt[i] = pd[i] = 0;
        pt_low[i] = pt_high[i] = pt_stack[i] = pt_fb1[i] = pt_fb2[i] = pt_fb3[i] = pt_fb4[i] = 0;
    }

    // 低位メモリのマッピング (0x0-0x200000 = 2MB)
    for (uint64_t addr = 0x0; addr < 0x200000; addr += 0x1000) {
        uint64_t page_idx = (addr >> 12) & 0x1FF;
        pt_low[page_idx] = addr | 0b11;
    }
    
    // 高位メモリのマッピング (0x200000-0x400000 = 2MB)
    for (uint64_t addr = 0x200000; addr < 0x400000; addr += 0x1000) {
        uint64_t page_idx = ((addr - 0x200000) >> 12) & 0x1FF;
        pt_high[page_idx] = addr | 0b11;
    }

    // スタック領域のマッピング (0x1FE00000-0x20000000 = 2MB)
    // スタックは 0x1FEFA6C8 付近なので、この範囲をマップ
    stack_base = 0x1FE00000;
    for (uint64_t addr = stack_base; addr < stack_base + 0x200000; addr += 0x1000) {
        uint64_t page_idx = ((addr - stack_base) >> 12) & 0x1FF;
        pt_stack[page_idx] = addr | 0b11;
    }
    stack_top = stack_base + 0x100000;
    // memset(stack_base, 0, 0x200000);
    // asm volatile("mov %0, %%rsp" :: "r"(stack_top));

    // フレームバッファのマッピング
    // 0x400000 (8MB) の仮想アドレスにマップ
    uint64_t fb_size = 0x800000; // 8MB（安全?な範囲）
    for (uint64_t offset = 0; offset < fb_size; offset += 0x1000) {
        uint64_t page_idx = (offset >> 12) & 0x1FF;
        if (offset < 0x200000)
            pt_fb1[page_idx] = (framebuffer_addr + offset) | PAGE_PRESENT | PAGE_RW | PAGE_PWT | PAGE_PCD;
        else
            pt_fb2[page_idx] = (framebuffer_addr + offset) | PAGE_PRESENT | PAGE_RW  | PAGE_PWT | PAGE_PCD;
    }
    // ページディレクトリエントリを設定
    pd[0] = (uint64_t)(uintptr_t)pt_low | PAGE_PRESENT | PAGE_RW ;    // 0-2MB
    pd[1] = (uint64_t)(uintptr_t)pt_high | PAGE_PRESENT | PAGE_RW ;   // 2-4MB
    pd[2] = (uint64_t)(uintptr_t)pt_fb1 | PAGE_PRESENT | PAGE_RW  | PAGE_PWT | PAGE_PCD;     // 4MB-6MB（フレームバッファ）
    pd[3] = (uint64_t)(uintptr_t)pt_fb2 | PAGE_PRESENT | PAGE_RW  | PAGE_PWT | PAGE_PCD;     // 6MB-8MB（フレームバッファ）
    pd[255] = (uint64_t)(uintptr_t)pt_stack | 0b11; // スタック用 (約512MB)

    pdpt[0] = (uint64_t)(uintptr_t)pd | PAGE_PRESENT | PAGE_RW ;
    pml4[0] = (uint64_t)(uintptr_t)pdpt | PAGE_PRESENT | PAGE_RW ;

    // // alloc_page() が使う物理メモリ領域（例: 0x1780000 〜 0x3BB6C000）を仮想に貼る
    // for (uintptr_t addr = 0x1780000; addr < 0x3BB6C000; addr += 0x1000) {
    //     map_page_raw(addr, addr);
    // }
    // page_table_base ページディレクトリ領域
    // for (uintptr_t addr = 0x3BB8C000; addr < 0x3E003000; addr += 0x1000) {
    for (uintptr_t addr = 0x3BB8C000; addr < 0x40000000; addr += 0x1000) {
         map_page_raw(addr, addr);
    }

    // // 4GB以下の領域をidentity mapping for LAPIC
    // // 0xFEE00000 も含まれるように設定(一応大きさと時間の関係もあるので絞ってマップ)
    // for (uint64_t addr = 0xFE000000; addr < 0xFFF00000; addr += 0x1000) {
    //     map_page_raw(addr, addr);
    // }

    uint64_t rsp;
    asm volatile("mov %%rsp, %0" : "=r"(rsp));
    ps("rsp : ");ph(rsp);pc('\n');
    ps("mapped ");if(is_mapped(rsp)) ps("yes\n"); else ps("no\n");

    // uint64_t cr3;
    // asm volatile("mov %%cr3, %0" : "=r"(cr3));
    // // puts("cr3 : ");puthex(cr3);putc('\n');
    // // puts("base: ");puthex(base);putc('\n');
    // // puts("pml4: ");puthex(pml4);putc('\n');

    // // asm volatile("mov %0, %%cr3" :: "r"(base));
    // uint64_t cr3_base = ((uint64_t)(uintptr_t)pml4) & ~0xFFFULL;
    // asm volatile("mov %0, %%cr3" :: "r"(cr3_base) : "memory");

    // ページング有効化
    asm volatile(
        "mov %0, %%cr3\n\t"
        "mov %%cr3, %%rax\n\t"
        "mov %%rax, %%cr3"
        :: "r"(pml4) : "rax", "memory"
    );




    // スタックアクセステスト
    volatile uint64_t test_var = 0x12345678;

    ps("finish paging initialization\n");
}

static inline void put_pixel(uint32_t x, uint32_t y, uint32_t argb,
                             uint8_t *fb, uint32_t pitch) {
    *(uint32_t*)(fb + y * pitch + x * 4) = argb;
 }