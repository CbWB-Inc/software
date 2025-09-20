#include <stdint.h>
#include <stddef.h>
#include "log.h"
#include "common.h"

extern uint32_t* fb;

void remap_pic();
void fix_segments();
void enable_irq1();

void main(){
    // IRQ1(キーボード)を設定して割り込みを有効にする。

    remap_pic();
    fix_segments();
    enable_irq1();

    __asm__ volatile("sti");

    for(;;) __asm__ __volatile__("hlt");
}
