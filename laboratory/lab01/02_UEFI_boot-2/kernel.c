// kernel.c
#include <stdint.h>
#include <stddef.h>
#include "handoff.h"
#include "log.h"

void kernel_main(handoff_t* info) {
    // ここでBoot Servicesは死んでいる。なにもかも自前の世界。

    // とりあえず何か出力できるようにする。

    log_init(LOG_DBGCON|LOG_COM1);
    
    log_putc('A');pc('\n');
    
    
    uint64_t val = 0xFFFFFFFFFFFFFFFF;

    ph(val);pc('\n');
    ph2(val);pc('\n');
    ph4(val);pc('\n');
    ph8(val);pc('\n');

    pd(val);pc('\n');

    uint8_t c = 'A';

    pc(c);pc('\n');

    uint8_t *s = "hello world!";

    ps(s);pc('\n');

    ts(s);


    __asm__ __volatile__("hlt");
}