#include <stdint.h>
#include <stddef.h>
#include "log.h"
#include "common.h"


extern uint32_t* fb;
extern uint32_t _c_y, _c_x, _color, _pitch;


void main(){

    _color= 0x00;
    clsfb();
    _color= 0x00ffffff;
    
    __asm__ volatile("sti");  

    for (;;) {

        uint8_t buf[128];
        line_input(buf);


    }

    for(;;) __asm__ __volatile__("hlt");
}


