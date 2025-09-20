#include <stdint.h>
#include "common.h"
#include "log.h"

#define IDT_SIZE 256

#define PIC1_COMMAND 0x20
#define PIC1_DATA    0x21
#define PIC2_COMMAND 0xA0
#define PIC2_DATA    0xA1

#define ICW1_INIT    0x10
#define ICW1_ICW4    0x01
#define ICW4_8086    0x01


struct interrupt_frame {
    uint64_t rip;
    uint64_t cs;
    uint64_t rflags;
    uint64_t rsp;
    uint64_t ss;
} __attribute__((packed));

struct IDTR {
    uint16_t limit;
    uint64_t base;
} __attribute__((packed));

struct IDTEntry {
    uint16_t offset_low;
    uint16_t selector;
    uint8_t  ist;
    uint8_t  type_attr;
    uint16_t offset_mid;
    uint32_t offset_high;
    uint32_t zero;
} __attribute__((packed));

struct IDTEntry* idt = NULL;


// --- I/Oポート出力 ---
static inline void outb(uint16_t port, uint8_t val) {
    asm volatile ("outb %0, %1" : : "a"(val), "Nd"(port));
}
static inline unsigned char inb(unsigned short port) {
    unsigned char ret;
    asm volatile("inb %1, %0" : "=a"(ret) : "Nd"(port));
    return ret;
}

__attribute__((interrupt))
void irq1_handler(struct interrupt_frame* frame) {

    uint8_t sc;
    if (inb(0x64) & 1) {
        sc = inb(0x60);    // スキャンコードを取得
        ph2(sc);pc(' ');
    } 
    
    outb(0x20, 0x20);

}

__attribute__((interrupt))
// GP例外ハンドラー - エラーコードは別パラメータで受け取る
void gp_handler(struct interrupt_frame* frame, uint64_t error_code) {
    static int fixed = 0;

    ps("GP EXCEPTION!\n");

        // エラーコード詳細解析
    uint16_t selector_index = (error_code >> 3) & 0x1FFF;
    uint8_t table = (error_code >> 2) & 1;
    uint8_t rpl = error_code & 3;
    uint16_t selector = selector_index << 3 | rpl;
    
    ps("Selector Index: ");ph(selector_index);pc('\n');
    ps("Table         : ");ps(table ? "LDT" : "GDT");pc('\n');
    ps("RPL           : ");ph(rpl);pc('\n');
    ps("Full Selector : ");ph(selector);pc('\n');
    
    ps("RIP           : ");ph(frame->rip);pc('\n');
    ps("Frame CS      : ");ph(frame->cs);pc('\n');
    ps("Frame SS      : ");ph(frame->ss);pc('\n');
    
    // 問題の命令を確認
    uint8_t* code = (uint8_t*)frame->rip;
    ps("Instruction: ");
    for (int i = 0; i < 4; i++) {
        ph4(code[i]);pc(' ');
    }
    pc('\n');
    
    // 現在のGDTサイズ確認
    struct {
        uint16_t limit;
        uint64_t base;
    } __attribute__((packed)) gdtr;
    
    asm volatile("sgdt %0" : "=m"(gdtr));
    ps("GDT entries   : ");ph4((gdtr.limit + 1) / 8);pc('\n');
    // ps("Accessing GDT[");ph4(selector_index);ps("] - OUT OF BOUNDS!\n");
    uint16_t entries = (gdtr.limit + 1) / 8;
    if (selector_index >= entries) {
        ps("Accessing GDT["); ph4(selector_index); ps("] - OUT OF BOUNDS!\n");
    }
    

    ps("GP! Error: ");ph(error_code);pc('\n');
    ps("Frame CS:");ph(frame->cs);ps(" SS:");ph(frame->ss);pc('\n');
    
    ps("GP - HALT\n");
    while(1) { asm("cli; hlt"); }
}


__attribute__((interrupt))
static void stub_err(struct interrupt_frame* frame, uint64_t error_code)  {
    ps("IN STUB_HANDLER\n\0");
    ps("RIP: 0x");ph8(frame->rip);pc('\n');
    ps("Error Code: 0x");ph8(error_code);pc('\n');
    
    // CR2レジスタ = フォルトを起こしたアドレス
    uint64_t fault_addr;
    asm volatile("mov %%cr2, %0" : "=r"(fault_addr));
    ps("Fault Address: 0x");ph8(fault_addr);pc('\n');
    
    // エラーコードの解析
    ps("Present: ");ps( (error_code & 1) ? "Yes" : "No");pc('\n');
    ps("Write: ");ps( (error_code & 2) ? "Yes" : "No");pc('\n');
    ps("User: ");ps( (error_code & 4) ? "Yes" : "No");pc('\n');
    while (1) asm volatile("hlt");
}

__attribute__((interrupt))
static void stub_noerr(struct interrupt_frame* frame) {
    ps("IN STUB_NOERROR\n");
    ps("RIP: 0x"); ph8(frame->rip); pc('\n');
    for(;;) asm volatile("cli; hlt");
}

__attribute__((interrupt))
void stub_handler4dbg(struct interrupt_frame* frame) {
    ps("IN STUB_HANDLER 4dbg\n\0");
    while (1) asm volatile("hlt");
}
__attribute__((interrupt))
void divide_error_handler(struct interrupt_frame* frame)  {
    ps("divide error!\n");
    ps("RIP: 0x");ph8(frame->rip);pc('\n');
    
    // CR2レジスタ = フォルトを起こしたアドレス
    uint64_t fault_addr;
    asm volatile("mov %%cr2, %0" : "=r"(fault_addr));
    ps("Fault Address: 0x");ph8(fault_addr);pc('\n');
    
    while(1) { asm("cli; hlt"); }
}

__attribute__((interrupt))
void double_fault_handler(struct interrupt_frame* frame, uint64_t error_code) {
    ps("DOUBLE FAULT!\n");
    ps("RIP: 0x");ph8(frame->rip);pc('\n');
    ps("Error Code: 0x");ph8(error_code);pc('\n');
    
    // CR2レジスタ = フォルトを起こしたアドレス
    uint64_t fault_addr;
    asm volatile("mov %%cr2, %0" : "=r"(fault_addr));
    ps("Fault Address: 0x");ph8(fault_addr);pc('\n');
    
    // エラーコードの解析
    ps("Present: ");ps( (error_code & 1) ? "Yes" : "No");pc('\n');
    ps("Write: ");ps( (error_code & 2) ? "Yes" : "No");pc('\n');
    ps("User: ");ps( (error_code & 4) ? "Yes" : "No");pc('\n');

    while(1) { asm("cli; hlt"); }
}

__attribute__((interrupt))
void page_fault_handler(struct interrupt_frame* frame, uint64_t error_code) {
    ps("PAGE FAULT!\n");
    ps("RIP: 0x");ph8(frame->rip);pc('\n');
    ps("Error Code: 0x");ph8(error_code);pc('\n');
    
    // CR2レジスタ = フォルトを起こしたアドレス
    uint64_t fault_addr;
    asm volatile("mov %%cr2, %0" : "=r"(fault_addr));
    ps("Fault Address: 0x");ph8(fault_addr);pc('\n');
    
    // エラーコードの解析
    ps("Present: ");ps( (error_code & 1) ? "Yes" : "No");pc('\n');
    ps("Write: ");ps( (error_code & 2) ? "Yes" : "No");pc('\n');
    ps("User: ");ps( (error_code & 4) ? "Yes" : "No");pc('\n');

    while(1) { asm("cli; hlt"); }
}

__attribute__((interrupt))
void Invalid_Opcode_handler(struct interrupt_frame* frame){
    uint64_t error_code = 0;
    ps("INVALID OPECODE EXCEPTION!\n");
    ps("RIP: 0x");ph8(frame->rip);pc('\n');
    ps("Error Code: 0x");ph8(error_code);pc('\n');
    
    // CR2レジスタ = フォルトを起こしたアドレス
    uint64_t fault_addr;
    asm volatile("mov %%cr2, %0" : "=r"(fault_addr));
    ps("Fault Address: 0x");ph8(fault_addr);pc('\n');
    
    // エラーコードの解析
    ps("Present: ");ps( (error_code & 1) ? "Yes" : "No");pc('\n');
    ps("Write: ");ps( (error_code & 2) ? "Yes" : "No");pc('\n');
    ps("User: ");ps( (error_code & 4) ? "Yes" : "No");pc('\n');

    while(1) { asm("cli; hlt"); }
}

__attribute__((interrupt))
void Virtualization_handler(struct interrupt_frame* frame, uint64_t error_code) {
    error_code = 0;
    ps("VIRTUALIZATION EXCEPTION!\n");
    ps("RIP: 0x");ph8(frame->rip);pc('\n');
    ps("Error Code: 0x");ph8(error_code);pc('\n');
    
    // CR2レジスタ = フォルトを起こしたアドレス
    uint64_t fault_addr;
    asm volatile("mov %%cr2, %0" : "=r"(fault_addr));
    ps("Fault Address: 0x");ph8(fault_addr);pc('\n');
    
    // エラーコードの解析
    ps("Present: ");ps( (error_code & 1) ? "Yes" : "No");pc('\n');
    ps("Write: ");ps( (error_code & 2) ? "Yes" : "No");pc('\n');
    ps("User: ");ps( (error_code & 4) ? "Yes" : "No");pc('\n');

    while(1) { asm("cli; hlt"); }
}


void set_idt_entry(int vec, uint64_t handler,
                    uint16_t selector, uint8_t ist, uint8_t type_attr){
    uint64_t addr = (uint64_t)handler;
    
    idt[vec].offset_low  = addr & 0xFFFF;
    idt[vec].selector    = selector;            // GDTのコードセグメント
    idt[vec].ist         = ist & 0x7;           // 0で通常動作
    idt[vec].type_attr   = type_attr;           // Interrupt gate, present
    idt[vec].offset_mid  = (addr >> 16) & 0xFFFF;
    idt[vec].offset_high = (addr >> 32) & 0xFFFFFFFF;
    idt[vec].zero        = 0;
   
}

void setup_idt() {
    idt = (struct IDTEntry*)alloc_page();  // identity mapped な領域（重要！）
    memset(idt, 0, sizeof(struct IDTEntry) * IDT_SIZE);

    for (int v = 0; v < 0x20; v++) {
        set_idt_entry(v, (uint64_t)(uintptr_t)stub_noerr, 0x08, 0, 0x8e);
    }
    // エラーコードを“必ず”押す例外だけ上書き
    const int err_vecs[] = {8,10,11,12,13,14,17,20,21,30};
    for (unsigned i=0;i<sizeof(err_vecs)/sizeof(err_vecs[0]);++i){
        set_idt_entry(err_vecs[i], (uint64_t)(uintptr_t)stub_err, 0x08, 1, 0x8e);
    }
    set_idt_entry(6, (uint64_t)(uintptr_t)Invalid_Opcode_handler, 0x08, 1, 0x8e);
    set_idt_entry(8, (uint64_t)(uintptr_t)double_fault_handler, 0x08, 2, 0x8e);
    set_idt_entry(13, (uint64_t)(uintptr_t)gp_handler, 0x08, 1, 0x8e);
    set_idt_entry(14, (uint64_t)(uintptr_t)page_fault_handler, 0x08, 1, 0x8e);
    set_idt_entry(20, (uint64_t)(uintptr_t)Virtualization_handler, 0x08, 1, 0x8e);
    set_idt_entry(0, (uint64_t)(uintptr_t)divide_error_handler, 0x08, 1, 0x8e);
    
    // set_idt_entry(6, (uint64_t)(uintptr_t)stub_handler4dbg, 0x08, 1, 0x8e);

    set_idt_entry(0x21, (uint64_t)(uintptr_t)irq1_handler, 0x08, 1, 0x8e);

    
    struct IDTR idtr = {
        .limit = sizeof(struct IDTEntry) * IDT_SIZE - 1,
        .base  = (uint64_t)(uintptr_t)idt  // 仮想=物理 の identity map が前提
    };

    asm volatile("lidt %0" :: "m"(idtr));
}

void enable_irq1() {
    outb(0x21, inb(0x21) & ~(1 << 1)); // PICマスク解除
}

void remap_pic() {
    outb(PIC1_COMMAND, ICW1_INIT | ICW1_ICW4);
    outb(PIC2_COMMAND, ICW1_INIT | ICW1_ICW4);

    outb(PIC1_DATA, 0x20); // PIC1 IRQ base: 0x20
    outb(PIC2_DATA, 0x28); // PIC2 IRQ base: 0x28

    outb(PIC1_DATA, 0x04); // PIC1 tells PIC2 at IRQ2
    outb(PIC2_DATA, 0x02); // PIC2 tells PIC1 it’s cascade identity

    outb(PIC1_DATA, ICW4_8086);
    outb(PIC2_DATA, ICW4_8086);

    // マスク
    outb(PIC1_DATA, 0xFF);  // 全マスク
    outb(PIC2_DATA, 0xFF);
}

// セグメントレジスタを正しい値に修正
void fix_segments(void) {
    ps("Fixing segment registers...\n");
    
    // 現在の値を確認
    uint16_t cs, ds, ss;
    asm volatile("mov %%cs, %0" : "=r"(cs));
    asm volatile("mov %%ds, %0" : "=r"(ds));
    asm volatile("mov %%ss, %0" : "=r"(ss));
    
    // puts("Before - CS:");puthex(cs);puts(" DS:");puthex(ds);puts(" SS:");puthex(ss);putc('\n');
    
    // データセグメントを0x10に設定
    asm volatile(
        "mov $0x10, %%ax\n\t"
        "mov %%ax, %%ds\n\t"
        "mov %%ax, %%es\n\t"
        "mov %%ax, %%fs\n\t"
        "mov %%ax, %%gs\n\t"
        "mov %%ax, %%ss"
        : : : "ax"
    );
    
    // コードセグメントを0x08に設定（far jump）
    asm volatile(
        "pushq $0x08\n\t"       // 新しいCS
        "leaq 1f(%%rip), %%rax\n\t"
        "pushq %%rax\n\t"       // 戻り先アドレス
        "lretq\n\t"             // far return（CS:RIPをスタックから復元）
        "1:\n\t"
        : : : "rax", "memory"
    );
    
    // 修正後の値を確認
    asm volatile("mov %%cs, %0" : "=r"(cs));
    asm volatile("mov %%ds, %0" : "=r"(ds));
    asm volatile("mov %%ss, %0" : "=r"(ss));
    
    // puts("After - CS:");puthex(cs);puts(" DS:");puthex(ds);puts(" SS:");puthex(ss);putc('\n');
}
