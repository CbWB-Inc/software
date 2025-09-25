#include <stdint.h>
#include <stddef.h>
#include "log.h"
#include "common.h"

extern uint32_t* fb;
extern uint32_t *lapic_base;
uint64_t lapic_phys;

void remap_pic();
void fix_segments();
void enable_irq1();
void ioapic_redirect(int gsi, uint8_t vector, uint8_t dest_apic);
static inline uint8_t in8(uint16_t port);

void main(){
    // キーボード割り込みを設定して有効にする。
    extern uint64_t* gdt_ptr;
    ph(gdt_ptr[4]);pc('\n');
    ph(gdt_ptr[5]);pc('\n');

    fix_segments();
    
    // キーボード割り込みを設定して有効にする。
    
    // MSRからLAPICベースアドレスを取得
    uint64_t msr_value = rdmsr(0x1B);
    ps("Raw MSR 0x1B value: "); ph(msr_value); pc('\n');
    
    // LAPIC物理アドレスを正しく抽出（ビット35-12のみ使用）
    uint64_t lapic_phys = (msr_value & 0xFFFFF000ULL) & 0xFFFFFFFFULL;
    ps("LAPIC physical address: "); ph(lapic_phys); pc('\n');
    
    // LAPICが有効かチェック
    if (!(msr_value & (1ULL << 11))) {
        ps("LAPIC is disabled in MSR\n");
        // LAPIC有効化
        wrmsr(0x1B, msr_value | (1ULL << 11));
        ps("LAPIC enabled in MSR\n");
    } else {
        ps("LAPIC already enabled in MSR\n");
    }

    // グローバル変数lapic_baseを設定（重要！）
    // 32bit物理アドレスを直接使用（sign extensionを避ける）
    lapic_base = (volatile uint32_t*)(uint32_t)lapic_phys;
    ps("lapic_base set to: "); ph((uint64_t)lapic_base); pc('\n');

    // LAPIC SVRレジスタでLAPIC有効化
    ps("Enabling LAPIC via SVR...\n");
    lapic_w(0x0F0, 0x100 | 0xFF); // SVR: LAPIC enable + spurious vector 0xFF

    // LAPIC IDを読み取り
    ps("Reading LAPIC ID...\n");
    uint32_t lapic_id = (lapic_r(0x20) >> 24) & 0xFF;
    ps("LAPIC ID: "); ph4(lapic_id); pc('\n');
    
    // Task Priority Register (TPR) を0に設定（全割り込みを受け付ける）
    ps("Setting LAPIC TPR to 0...\n");
    lapic_w(0x80, 0x00);
    
    ps2_mouse_init_min();
    
    
    // キーボード割り込み設定
    ps("Setting up keyboard interrupt...\n");
    ioapic_redirect(1, 0x61, lapic_id); // Keyboard (PS/2)
    ioapic_redirect(12, 0x62, lapic_id); // Mouse   (PS/2)
    
    // キーボードバッファクリア
    ps("Clearing keyboard buffer...\n");
    while (in8(0x64) & 0x01) (void)in8(0x60);

    ps("Enabling interrupts...\n");
    

    // uint64_t lapic_phys = rdmsr(0x1B) & ~0xFFFULL;
    // lapic_base = (volatile uint32_t*)(uintptr_t)lapic_phys;


    // if (0xFEE00020) ps("mapped yes\n");


    // uint32_t lapic_id = (lapic_r(0x20) >> 24) & 0xFF;
    // ioapic_redirect(1,  0x61, lapic_id); // Keyboard (PS/2)
    
    // while (in8(0x64) & 0x01) (void)in8(0x60);

    __asm__ volatile("sti");

    for(;;) __asm__ __volatile__("hlt");
}

static inline uint8_t in8(uint16_t port) {
    uint8_t val;
    __asm__ volatile ("inb %1, %0"
                      : "=a"(val)       // 出力: ALに入る
                      : "Nd"(port));    // 入力: DXにポート番号
    return val;
}

void wrmsr(uint32_t msr, uint64_t value) {
    uint32_t lo = value & 0xFFFFFFFF;
    uint32_t hi = value >> 32;
    __asm__ volatile ("wrmsr" :: "a"(lo), "d"(hi), "c"(msr));
}