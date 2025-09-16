#include <stdint.h>
#include <stddef.h>
#include "log.h"
#include "common.h"

extern uint32_t* fb;

void main(){
    // 画面にAを表示してみる
    
    uint8_t font_A[]      = {0x00, 0x00, 0x10, 0x38, 0x6C, 0xC6, 0xC6, 0xFE, 0xC6, 0xC6, 0xC6, 0xC6, 0x00, 0x00, 0x00, 0x00};
    uint8_t font_period[] = {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x18, 0x18, 0x00, 0x00, 0x00, 0x00};
    uint32_t x, y;

    x = y = 90;
    uint32_t screen_width = 1280;
    for (int row = 0; row < 16; row++) {
        uint8_t bits = font_A[row];
        for (int col = 0; col < 8; col++) {
            if ((bits >> (7 - col)) & 1) {
                int px = x + col;
                int py = y + row;
                fb[py * screen_width + px] = 0x00ffffff;
            }
        }
    }

    x = y = 100;
    for (int row = 0; row < 16; row++) {
        uint8_t bits = font_period[row];
        for (int col = 0; col < 8; col++) {
            if ((bits >> (7 - col)) & 1) {
                int px = x + col;
                int py = y + row;
                fb[py * screen_width + px] = 0x00ff0000;
            }
        }
    }

}