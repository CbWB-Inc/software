// kernel.c
#include <stdint.h>
#include <stddef.h>
#include "handoff.h"

void kernel_main(handoff_t* info) {
    // ここでBoot Servicesは死んでいる。なにもかも自前の世界。


    __asm__ __volatile__("hlt");
}