#include <stdint.h>
#include "common.h"
#include "log.h"

#define IDT_SIZE 256

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
        set_idt_entry(v, (uint64_t)(uintptr_t)stub_noerr, 0x08, 1, 0x8e);
    }
    // エラーコードを“必ず”押す例外だけ上書き
    const int err_vecs[] = {8,10,11,12,13,14,17,20,21,30};
    for (unsigned i=0;i<sizeof(err_vecs)/sizeof(err_vecs[0]);++i){
        set_idt_entry(err_vecs[i], (uint64_t)(uintptr_t)stub_err, 0x08, 1, 0x8e);
    }
    set_idt_entry(8, (uint64_t)(uintptr_t)double_fault_handler, 0x08, 2, 0x8e);
    set_idt_entry(0x0D, (uint64_t)(uintptr_t)gp_handler, 0x08, 1, 0x8e);
    set_idt_entry(14, (uint64_t)(uintptr_t)page_fault_handler, 0x08, 1, 0x8e);
    set_idt_entry(21, (uint64_t)(uintptr_t)Virtualization_handler, 0x08, 1, 0x8e);
    set_idt_entry(0, (uint64_t)(uintptr_t)divide_error_handler, 0x08, 1, 0x8e);
    
    // set_idt_entry(0, (uint64_t)(uintptr_t)stub_handler4dbg, 0x08, 1, 0x8e);

    
    struct IDTR idtr = {
        .limit = sizeof(struct IDTEntry) * IDT_SIZE - 1,
        .base  = (uint64_t)(uintptr_t)idt  // 仮想=物理 の identity map が前提
    };

    asm volatile("lidt %0" :: "m"(idtr));
}
