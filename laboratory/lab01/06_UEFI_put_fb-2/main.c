#include <stdint.h>
#include <stddef.h>
#include "log.h"
#include "common.h"

extern uint32_t* fb;


void main(){
    // 矩形表示とかいろいろ

    rectfb(10,20,200,30,0xFFFFFF);
    rectfb(30,10,20,300,0xFF0000);

    pcfb('A', 10, 10, 0xFFFFFF);
    pcfb('Z', 10, 30, 0x00FF00);

    psfb("Hello",40, 40, 0xFF00FF);

    ph2fb(0x12, 100, 20, 0x00ffff);
    
    ph4fb(0x1234, 200, 10, 0xFFffff);

    ph8fb(0x12345678, 200, 60, 0xFFffff);

    phfb(0x123456789abcdef0, 300, 30, 0xFFffff);

    pdfb(0xFFFFFFFF, 500, 50, 0xffffff);
    pdfb(0xFFFF, 500, 80, 0xffffff);

    pdfb(1234567890, 500, 100, 0xffffff);

    pdfb(100, 500, 200, 0xffffff);
}