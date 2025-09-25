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

#define IOREGSEL 0x00
#define IOWIN    0x10

#define LAPIC_TIMER_VEC 0xE0

#define LAPIC_REG_ID        0x020
#define LAPIC_REG_TPR       0x080
#define LAPIC_REG_EOI       0x0B0
#define LAPIC_REG_SVR       0x0F0
#define LAPIC_REG_LVT_TIMER 0x320
#define LAPIC_REG_INIT_CNT  0x380
#define LAPIC_REG_CUR_CNT   0x390
#define LAPIC_REG_DIV       0x3E0

#define DELIV_FIXED   (0u<<8)
#define DEST_PHYS     (0u<<11)
#define POL_HIGH      (0u<<13)
#define TRIG_EDGE     (0u<<15)
#define MASKED        (1u<<16)
#define UNMASKED      (0u<<16)


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

// 位置
static int cur_x = 50, cur_y = 50;
static const uint8_t CUR_W=8, CUR_H=12;
static const uint8_t cursor_bits[12] = {
    0b10000000,
    0b11000000,
    0b11100000,
    0b11110000,
    0b11111000,
    0b11111100,
    0b11111110,
    0b11111100,
    0b11011000,
    0b10011000,
    0b00011000,
    0b00001000,
};
static volatile int mouse_dx_acc = 0;
static volatile int mouse_dy_acc = 0;


extern void kbd_isr_stub();
extern void mouse_isr_stub();

volatile uint32_t *lapic_base = NULL;
volatile uint32_t* ioapic = (volatile uint32_t*)0xFEC00000; // identity map前提

uint16_t scancode_decord(uint16_t keycode);
int mouse_cmd(uint8_t cmd);

// --- I/Oポート出力 ---
static inline void outb(uint16_t port, uint8_t val) {
    asm volatile ("outb %0, %1" : : "a"(val), "Nd"(port));
}
static inline unsigned char inb(unsigned short port) {
    unsigned char ret;
    asm volatile("inb %1, %0" : "=a"(ret) : "Nd"(port));
    return ret;
}

static inline uint8_t in8(uint16_t port) {
    uint8_t val;
    __asm__ volatile ("inb %1, %0"
                      : "=a"(val)       // 出力: ALに入る
                      : "Nd"(port));    // 入力: DXにポート番号
    return val;
}

static inline void out8(uint16_t port, uint8_t val) {
    __asm__ volatile ("outb %0, %1"
                      :
                      : "a"(val), "Nd"(port));
}

static inline void wait_ibf_clear(void){ while (in8(0x64) & 0x02) ; } // IBF=0まで
static inline void wait_obf_set(void){  while (!(in8(0x64) & 0x01)) ; } // OBF=1まで
static inline void kbc_cmd(uint8_t c){ wait_ibf_clear(); out8(0x64,c); }
static inline void kbc_data(uint8_t d){ wait_ibf_clear(); out8(0x60,d); }
static inline uint64_t rdtsc(void){
    uint32_t lo, hi;
    __asm__ volatile("rdtsc" : "=a"(lo), "=d"(hi));
    return ((uint64_t)hi<<32) | lo;
}

void lapic_w(uint32_t off, uint32_t val){ 
    lapic_base[off/4] = val; 
    (void)lapic_base[0x20/4];  // fence
} // fence

static inline void ioapic_write(uint8_t reg, uint32_t val){
    ioapic[IOREGSEL/4] = reg;
    ioapic[IOWIN/4]    = val;
}

// __attribute__((interrupt))
void kbd_isr_c(){
    // キーボードからのデータを読み取り
    static uint16_t keycode;
    for (int i = 0; i < 32; i++) {          // 過剰ループ防止
        uint8_t st = in8(0x64);
        if (!(st & 0x01)) break;            // OBF=0 → もう無い
        // if (st & (1<<5)) return;            // AUX=1 → これはマウス由来、触らない
        if (st & (1<<5)) break;            // AUX=1 → これはマウス由来、触らない
        uint8_t sc = in8(0x60);             // キーボード由来を消費
        keycode = (keycode & 0xff00) | sc;
        keycode = scancode_decord(keycode);
        uint8_t asc = keycode & 0xff;
        if (keycode & 0x100) pc(asc);
    }
    lapic_w(LAPIC_REG_EOI, 0);
}

// __attribute__((interrupt))
void mouse_isr_c(void){
    pc('*'); // 任意のトレース
    static uint8_t pkt[3];
    static int idx = 0;

    for (int n=0; n<16; n++){                  // 安全のため上限
        uint8_t st = in8(0x64);
        if (!(st & 0x01)) break;               // OBF=0 → もう無い
        if (!(st & 0x20)) { (void)in8(0x60); continue; } // キーボード由来は捨てる or バッファへ

        uint8_t b = in8(0x60);                 // AUX=1 → マウスバイト
        if (idx==0 && (b & 0x08)==0) continue; // 同期ビット無しは捨てて同期取り直し
        pkt[idx++] = b;
        if (idx==3){
            idx = 0;
            int dx = (int8_t)pkt[1];
            int dy = (int8_t)pkt[2];
            mouse_dx_acc += dx;
            mouse_dy_acc -= dy;                // 画面座標都合で反転
        }
    }
    lapic_w(LAPIC_REG_EOI, 0);
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

    // set_idt_entry(0x21, (uint64_t)(uintptr_t)irq1_handler, 0x08, 1, 0x8e);

    set_idt_entry(0x61, (uint64_t)kbd_isr_stub, 0x08, 0, 0x8E); // Key Bord
    set_idt_entry(0x62, (uint64_t)mouse_isr_stub, 0x08, 0, 0x8E); // Key Bord

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

uint32_t lapic_r(uint32_t off){
    return lapic_base[off/4]; 
}

uint64_t rdmsr(uint32_t msr) {
    uint32_t lo, hi;
    __asm__ volatile ("rdmsr" : "=a"(lo), "=d"(hi) : "c"(msr));
    return ((uint64_t)hi << 32) | lo;
}

void ioapic_redirect(int gsi, uint8_t vector, uint8_t dest_apic){
    uint8_t low = 0x10 + 2*gsi;
    uint8_t high= low + 1;

    uint32_t lo =
        vector | DELIV_FIXED | DEST_PHYS | POL_HIGH | TRIG_EDGE | UNMASKED;
    uint32_t hi = ((uint32_t)dest_apic) << 24;

    // まずマスクしてから書き換え → 最後にアンマスク派でもOK
    ioapic_write(low,  (lo | MASKED));
    ioapic_write(high, hi);
    ioapic_write(low,  lo); // アンマスク
}

int ps2_mouse_init_min(void)
{
    // 0) まずキーボード側で翻訳/IRQ等を有効にしてある前提ならOK
    //    （もしここでやるなら、下の “コマンドバイト更新” のみで済みます）

    // 1) AUX（マウス）ポートを有効化
    kbc_cmd(0xA8);  // Enable AUX port

    // 2) コマンドバイトを読み→ビット加工→書き戻し
    //    - bit0: IRQ1 (keyboard) enable
    //    - bit1: IRQ12 (mouse)   enable
    //    - bit4: keyboard clock disable (0で有効)
    //    - bit5: mouse clock    disable (0で有効)
    //    ※ ここで“余計な二度読み”はしない。OBFの1バイトだけ読む。
    kbc_cmd(0x20);                       // Read command byte
    uint8_t cb = 0;
    if (kbc_wait_obf_tmo(2000, 0, &cb) == 0) return -1;

    cb |=  (1u<<0) | (1u<<1);            // IRQ1/IRQ12 を有効に
    cb &= ~((1u<<4) | (1u<<5));          // 両クロック有効化
    // （翻訳 bit6 はポリシー次第。必要ならここで set/clear）

    kbc_cmd(0x60);                       // Write command byte
    kbc_data(cb);

    kbd_host_set1_via_translation();

    // 入出力バッファの残滓を軽く掃除（やりすぎない）
    kbc_flush_soft(32, 2000);

    // 3) マウス本体を既定値にして、データレポートON
    //    ACK(0xFA) は mouse_cmd() が待ってくれる前提
    if (mouse_cmd(0xF6) != 0) return -2; // Set defaults
    if (mouse_cmd(0xF4) != 0) return -3; // Enable data reporting

    // 必要なら解像度/サンプルレート/1:1スケーリング等を追加
    //   mouse_cmd(0xE6);               // Scaling 1:1
    //   mouse_cmd(0xE8); mouse_cmd(0x03); // Resolution = 8 counts/mm
    //   mouse_cmd(0xF3); mouse_cmd(0x28); // Sample rate = 40

    return 0;
}

static inline void cpuid(uint32_t leaf, uint32_t *a, uint32_t *b, uint32_t *c, uint32_t *d){
    __asm__ volatile("cpuid" : "=a"(*a),"=b"(*b),"=c"(*c),"=d"(*d) : "a"(leaf), "c"(0));
}

int mouse_cmd(uint8_t cmd)
{
    const int MAX_RETRY = 3;
    for (int attempt = 0; attempt <= MAX_RETRY; ++attempt) {
        kbc_cmd(0xD4);
        kbc_data(cmd);

        uint8_t resp = 0;
        if (kbc_wait_obf_tmo(20000, /*want_aux=*/1, &resp) == 0) return -1;

        if (resp == 0xFA) return 0;       // ACK
        if (resp == 0xFE) continue;       // RESEND
        if (resp == 0xFC) return -2;      // ERROR
        return -4;                        // unknown
    }
    return -3;
}

static uint64_t tsc_hz_via_cpuid(void){
    uint32_t a,b,c,d;

    // CPUID.0x15: a=denom, b=num, c=core crystal Hz
    cpuid(0x15, &a,&b,&c,&d);
    if (a && b && c){                 // すべて非ゼロ必須
        // TSC_Hz = crystal_Hz * (b/a)
        return (uint64_t)c * (uint64_t)b / (uint64_t)a;
    }

    // CPUID.0x16: a=base MHz（参考値）
    cpuid(0x16, &a,&b,&c,&d);
    if (a) return (uint64_t)a * 1000000ULL;

    // 最終手段：仮置き（環境に合わせて好みで）
    return 3690000000ULL; // 3.69 GHz
}


// 追加：OBFを待つ（必要ならAUX限定）。成功1/失敗0。
inline int kbc_wait_obf_tmo(uint32_t timeout_us, int require_aux, uint8_t *out){
    uint64_t t0 = rdtsc();
    uint64_t tsc_hz = tsc_hz_via_cpuid();
    uint64_t deadline = t0 + (tsc_hz/1000000ULL) * timeout_us;
    while (rdtsc() < deadline) {
        uint8_t st = in8(0x64);
        if (st & 0x01) {                 // OBF
            uint8_t d = in8(0x60);
            if (!require_aux || (st & (1<<5))) { if (out) *out = d; return 1; }
            // AUX必須なのにKBD由来→捨てて継続
        }
        __asm__ volatile("pause");
    }
    return 0; // timeout
}

int kbd_host_set1_via_translation(void) {
    // Read command byte
    kbc_cmd(0x20);
    uint8_t cb = 0;
    if (kbc_wait_obf_tmo(2000, /*want_aux=*/0, &cb) == 0) return -1;

    cb |=  (1u<<6) | (1u<<0);   // 翻訳ON, IRQ1 ON
    cb &= ~(1u<<4);             // キーボードクロック有効
    cb |=  (1u<<6) | (1u<<0) | (1u<<1);  // 翻訳ON, IRQ1/IRQ12 ON
    cb &= ~((1u<<4) | (1u<<5));          // KB/Mouse clock 有効

    // Write command byte
    kbc_cmd(0x60);
    kbc_data(cb);

    return 0;
}

// 追加：KBCの出力を最大Nバイト/タイムアウトで捨てる
inline void kbc_flush_soft(uint32_t max_bytes, uint32_t timeout_us){
    uint64_t t0 = rdtsc();
    uint64_t tsc_hz = tsc_hz_via_cpuid();
    uint64_t deadline = t0 + (tsc_hz/1000000ULL) * timeout_us;
    uint32_t n = 0;
    while (n < max_bytes && rdtsc() < deadline) {
        uint8_t st = in8(0x64);
        if (!(st & 0x01)) break;      // 空なら終了
        (void)in8(0x60);              // 1バイト捨てる
        n++;
        __asm__ volatile("pause");
    }
}

