#pragma once
// log.h (add prototypes)
#include <stdint.h>
enum { LOG_DBGCON=1<<0, LOG_COM1=1<<1 };

void log_init(uint32_t sinks);
void log_putc(char c);
void log_write(const char* s);

// macrosが呼ぶ関数の宣言を足す
void log_put_str(const char* s);
void log_put_udec(uint64_t v);
void log_put_hex(uint64_t v);
void log_put_hex_fixed(uint64_t v, unsigned width);
void log_put_hex_long(unsigned long v);
void log_ts(const char* tag);
void hexdump(const void* p, unsigned len);

#define pc(c)  (log_putc((char)(c)))
#define ps(s)  (log_put_str((s)))
#define pd(v)  (log_put_udec((uint64_t)(v)))
#define ph(v)  (log_put_hex((uint64_t)(v)))
#define ph2(v) (log_put_hex_fixed((uint64_t)(v) & 0xFFu,   2u))
#define ph4(v) (log_put_hex_fixed((uint64_t)(v) & 0xFFFFu, 4u))
#define ph8(v) (log_put_hex_fixed((uint64_t)(v) & 0xFFFFFFFFu, 8u))
#define ts(s)  (log_ts((s)))
