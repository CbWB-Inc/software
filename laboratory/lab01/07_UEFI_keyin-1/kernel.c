// kernel.c
#include <stdint.h>
#include <stddef.h>
#include "handoff.h"
#include "log.h"
#include "common.h"

static struct {
    uint16_t limit;
    uint64_t base;
} __attribute__((packed, aligned(16))) gdtr;

__attribute__((aligned(16)))struct TSS {
    uint32_t reserved0;
    uint64_t rsp0;
    uint64_t rsp1;
    uint64_t rsp2;
    uint64_t reserved1;
    uint64_t ist1;
    uint64_t ist2;
    uint64_t ist3;
    uint64_t ist4;
    uint64_t ist5;
    uint64_t ist6;
    uint64_t ist7;
    uint64_t reserved2;
    uint16_t reserved3;
    uint16_t iopb_offset;
} __attribute__((packed));

uint64_t* pml4;
uint64_t* framebuffer_phys  = (uint64_t*)0x80000000;
uint64_t* next_free_page    = (uint64_t*)0x01780000;
uint64_t* max_free_page     = (uint64_t*)0x3BB6C000;
uint64_t* next_sys_page     = (uint64_t*)0x3BB8C000;
uint64_t* page_table_base   = (uint64_t*)0x3BB8C000;
uintptr_t  stack_top, stack_base;
uint64_t* fb_virt = (uint64_t*)0x00400000;         // 物理0x80000000を仮想0x00400000にマップする
uint64_t* fb = (uint64_t*)0x00400000;
uint64_t* gdt_ptr;
struct TSS* tss;

void setup_gdt(void);
void setup_tss(void* kernel_stack_top);
void init_paging(void* page_table_base, uint64_t framebuffer_addr);
void setup_idt();
void main();


void kernel_main(handoff_t* info) {
    // ここでBoot Servicesは死んでいる。なにもかも自前の世界。

    // ログの初期化
    ps("log initialize\n");
    log_init(LOG_DBGCON|LOG_COM1);
    
    // ページング
    ps("virtual memory mapping\n");
    init_paging(page_table_base, info->fb_phys);

    // スタックの設定
    asm volatile("mov %0, %%rsp" :: "r"(stack_top) : "memory");
  
    // gdtセットアップ
    ps("setup gdt\n");
    setup_gdt();

    // tssセットアップ
    ps("setup tss\n");
    setup_tss((uint64_t*)stack_top);

    // idtセットアップ
    ps("setup idt\n");
    setup_idt();

    ps("\nkernel initialize complete\n\n");
    
    main();

    // __asm__ __volatile__("hlt");
}


int64_t* gdt_mem = NULL;
void setup_gdt(void) {
    gdt_mem = alloc_page();  // 仮想=物理の領域を前提とする

    // GDTエントリ構築（6エントリ分）
    gdt_mem[0] = 0x0000000000000000;         // null
    gdt_mem[1] = 0x00A09A000000FFFF;
    gdt_mem[2] = 0x008092000000FFFF;         // data
    // gdt_mem[1] = 0x00AF9A000000FFFF;         // 64-bit code segment (Ring 0)
    // gdt_mem[2] = 0x00AF92000000FFFF;         // 64-bit data segment (Ring 0)    gdt_mem[3] = 0x0000000000000000;         // 未使用
    gdt_mem[4] = 0x0000000000000000;         // TSS前半
    gdt_mem[5] = 0x0000000000000000;         // TSS後半
    gdt_mem[6] = 0x008092000000FFFF;  // データセグメント（GDT[2]と同じ）
    gdt_mem[7] = 0x008092000000FFFF;  // データセグメント
    gdt_mem[8] = 0x0000000000000000;         // 未使用
    // GDTRの設定
    gdtr.limit = sizeof(uint64_t) * 9 - 1;
    gdtr.base  = (uint64_t)(uintptr_t)gdt_mem;  // identity mapped であること！
    asm volatile("lgdt %0" :: "m"(gdtr));

    // 後で TSS descriptor を setup_tss() 側で gdt_mem[4] に書くので、
    // gdt_mem へのポインタを保存しておく（グローバル変数として）
    extern uint64_t* gdt_ptr;
    gdt_ptr = gdt_mem;
}


void setup_tss(void* kernel_stack_top) {
    tss = (struct TSS*)alloc_page();
    memset(tss, 0, sizeof(struct TSS));
    if (((uint64_t)tss) & 0x7) {
        ps("TSS is not 8-byte aligned!\n");
    }

    tss->rsp0 = ((uint64_t)kernel_stack_top - 0x200) & ~0xF;
    tss->rsp1 = ((uint64_t)alloc_pages(10) + 4096 * 10 - 0x200) & ~0xF;
    tss->rsp2 = ((uint64_t)alloc_pages(10) + 4096 * 10 - 0x200) & ~0xF;
    tss->iopb_offset = sizeof(struct TSS);
    uint8_t* iopb = (uint8_t*)tss + sizeof(struct TSS);
    memset(iopb, 0x00, 0x800);  // 65536 / 8 = 8KB max、でも仮で数百バイトあれば十分
    
    // alloc_pages(100);
    tss->ist1 = ((uint64_t)(alloc_pages(10) + 4096 * 10 ) & ~0xF) - 0x100;
    tss->ist2 = ((uint64_t)(alloc_pages(4) + 4096 * 4 ) & ~0xF) - 0x100;
    tss->ist3 = ((uint64_t)(alloc_pages(4) + 4096 * 4 ) & ~0xF) - 0x100;
    tss->ist4 = ((uint64_t)(alloc_pages(4) + 4096 * 4 ) & ~0xF) - 0x100;
    tss->ist5 = ((uint64_t)(alloc_pages(4) + 4096 * 4 ) & ~0xF) - 0x100;
    tss->ist6 = ((uint64_t)(alloc_pages(4) + 4096 * 4 ) & ~0xF) - 0x100;
    tss->ist7 = ((uint64_t)(alloc_pages(4) + 4096 * 4 ) & ~0xF) - 0x100;

    uint64_t base = (uint64_t)tss;
    // uint64_t limit = sizeof(struct TSS) - 1;
    uint64_t limit = sizeof(struct TSS) - 1;

    uint64_t lo = 0;
    lo |= (limit & 0xFFFFu);                      // limit[15:0]
    lo |= (base  & 0xFFFFull) << 16;              // base[15:0]
    lo |= ((base >> 16) & 0xFFull) << 32;         // base[23:16]
    lo |= 0x89ull << 40;                          // type=0x89 (Avail TSS, P=1)
    lo |= ((limit >> 16) & 0xFull) << 48;         // limit[19:16]
    lo |= 0ull << 52;                             // ★ flags( G=0 他0 )
    lo |= ((base >> 24) & 0xFFull) << 56;         // base[31:24]

    uint64_t hi = ((base >> 32) & 0xFFFFFFFFull); // base[63:32] （上位32bit）

    gdt_ptr[4] = lo;
    gdt_ptr[5] = hi;                              // 上位Qword。上位32bitは 0 のままでOK


    asm volatile ("ltr %%ax" :: "a"(0x20));  // 4 * 8 = 0x20

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

    // alloc_page() が使う物理メモリ領域（例: 0x1780000 〜 0x3BB6C000）を仮想に貼る
    for (uintptr_t addr = 0x1780000; addr < 0x3BB6C000; addr += 0x1000) {
        map_page_raw(addr, addr);
    }
    // page_table_base ページディレクトリ領域
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