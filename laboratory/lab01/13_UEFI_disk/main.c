#include <stdint.h>
#include <stddef.h>
#include "log.h"
#include "common.h"

extern uint32_t* fb;

void test_ahci();

void main(){

    // Diskアクセスのテスト
    test_ahci();

    
    __asm__ volatile("sti");  

    for(;;) __asm__ __volatile__("hlt");
}


