// log.c (fixed)
#include <stdint.h>
#include "log.h"

static uint32_t g_sinks;

static inline void outb(uint16_t p, uint8_t v){ __asm__ volatile("outb %0,%1"::"a"(v),"Nd"(p)); }
static inline uint8_t inb(uint16_t p){ uint8_t r; __asm__ volatile("inb %1,%0":"=a"(r):"Nd"(p)); return r; }

// ---- debugcon(0xE9) ----
static inline void dbg_putc(char c){ outb(0xE9, (uint8_t)c); }

// ---- COM1(16550) ----
#define COM1 0x3F8
static inline int uart_present(void){
    uint8_t old = inb(COM1+7);     // Scratch Reg
    outb(COM1+7, 0x55); if (inb(COM1+7)!=0x55) { outb(COM1+7,old); return 0; }
    outb(COM1+7, 0xAA); int ok = (inb(COM1+7)==0xAA);
    outb(COM1+7, old); return ok;
}
static void uart_init_hw(void){
    outb(COM1+1,0x00);        // IER=0
    outb(COM1+3,0x80);        // DLAB=1
    outb(COM1+0,0x01);        // Divisor LSB (115200)
    outb(COM1+1,0x00);        // Divisor MSB
    outb(COM1+3,0x03);        // 8N1, DLAB=0
    outb(COM1+2,0xC7);        // FIFO
    outb(COM1+4,0x0B);        // OUT2|RTS|DTR
}
static inline void uart_putc(char c){
    while(!(inb(COM1+5)&0x20)){}  // THR empty
    outb(COM1, (uint8_t)c);
}

void log_init(uint32_t sinks){
    g_sinks = 0;
    if (sinks & LOG_DBGCON) g_sinks |= LOG_DBGCON;
    if ((sinks & LOG_COM1) && uart_present()) { uart_init_hw(); g_sinks |= LOG_COM1; }
}

void log_putc(char c){
    if (g_sinks & LOG_DBGCON) dbg_putc(c);
    if (g_sinks & LOG_COM1)   uart_putc(c);
}

void log_write(const char* s){ while(*s) log_putc(*s++); }

// ---- helpers used by macros ----
void log_put_udec(uint64_t v){
    char buf[21]; int i=0;
    if (!v){ log_putc('0'); return; }
    while (v){ buf[i++] = '0' + (v % 10); v /= 10; }
    while (i--) log_putc(buf[i]);
}
void log_put_hex_fixed(uint64_t v, unsigned w){
    for (int i=(int)w-1; i>=0; --i){
        uint8_t n = (uint8_t)((v >> (i*4)) & 0xF);
        log_putc((char)(n < 10 ? '0'+n : 'A'+(n-10)));
    }
}
void log_put_hex(uint64_t v){
    if (!v){ log_putc('0'); return; }
    unsigned n=0; for (uint64_t t=v; t; t>>=4) ++n;
    log_put_hex_fixed(v, n);
}
void log_put_hex_long(unsigned long v){
    log_put_hex_fixed((uint64_t)v, (unsigned)(sizeof(unsigned long)*2));
}
void log_put_str(const char* s){
    if (!s){ log_write("(null)"); return; }
    log_write(s);
}

// tscタイムスタンプ（rdtsc）
static inline unsigned long long tsc_now(void){
    unsigned int lo, hi;
    __asm__ __volatile__("rdtsc":"=a"(lo),"=d"(hi));
    return ((unsigned long long)hi<<32) | lo;
}

void log_ts(const char* tag){
    pc('['); ps(tag); ps(" ts="); ph(tsc_now()); ps("]\n");
}

// ミニhexdump（16バイト1行）
void hexdump(const void* p, unsigned len){
    const unsigned char* b = (const unsigned char*)p;
    for (unsigned i=0;i<len;i++){
        if ((i&15)==0){ ph4(i); ps(": "); }
        ph2(b[i]); pc((i&15)==15?'\n':' ');
    }
}
