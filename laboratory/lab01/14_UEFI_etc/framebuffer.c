#include <stdint.h>
#include <stddef.h>
#include "log.h"
#include "common.h"

uint32_t _c_x = 0;
uint32_t _c_y = 0;
uint32_t _color = 0x00FFFFFF;
uint32_t _pitch = 1280;

extern uint32_t* fb;
extern uint8_t _font_table[]; // アセンブラで定義されたフォント
extern uint16_t _scancode_table[]; // アセンブラで定義されたフォント

void rectfb(uint32_t x, uint32_t y, uint32_t width, uint32_t height, uint32_t color){
    uint32_t* row = (uint32_t*)fb;
    for (int yy = y; yy < y + height; yy++) {
        for (int xx = x; xx < x + width; xx++) {
            row[yy * _pitch + xx] = color;  // 矩形
        }
    }

}

void pcfb(char c, uint32_t x, uint32_t y, uint32_t color){
    rectfb(x, y, 8, 16, 0x00);
    if (c < 32 || c > 126) c = ' '; // 範囲外は空白に
    uint8_t* font = _font_table + (c - 32) * 16;
    for (int row = 0; row < 16; row++) {
        uint8_t bits = font[row];
        for (int col = 0; col < 8; col++) {
            if ((bits >> (7 - col)) & 1) {
                int px = x + col;
                int py = y + row;
                fb[py * _pitch + px] = color;
            }
        }
    }
}

void psfb(char* s, uint32_t x, uint32_t y, uint32_t color){
    while (*s) {
        pcfb(*s, x, y, color);
        x += 8;
        s++;
    }
}

void ph2fb(uint64_t v, uint32_t x, uint32_t y, uint32_t color){
    const char *hex = "0123456789ABCDEF";
    uint8_t nib1 = (v >> 4) & 0xF;
    uint8_t nib2 = (v >> 0) & 0xF;
    pcfb(hex[nib1], x + 0 , y, color);
    pcfb(hex[nib2], x + 8 , y, color);
}

void ph4fb(uint64_t v, uint32_t x, uint32_t y, uint32_t color){
    uint8_t b1 = (v >> 8) & 0xFF;
    uint8_t b2 = (v >> 0) & 0xFF;
    ph2fb(b1, x + 0 , y, color);
    ph2fb(b2, x + 16 , y, color);
}

void ph8fb(uint64_t v, uint32_t x, uint32_t y, uint32_t color){
    uint16_t w1 = (v >> 16) & 0xFFFF;
    uint16_t w2 = (v >> 0) & 0xFFFF;
    ph4fb(w1, x + 0 , y, color);
    ph4fb(w2, x + 32 , y, color);
}

void phfb(uint64_t v, uint32_t x, uint32_t y, uint32_t color){
    uint32_t w1 = (v >> 32) & 0xFFFFFFFF;
    uint32_t w2 = (v >> 0) & 0xFFFFFFFF;
    ph8fb(w1, x + 0 , y, color);
    ph8fb(w2, x + 64 , y, color);
}

void pdfb(uint64_t v, uint32_t x, uint32_t y, uint32_t color) {
    uint8_t ret[128];
    int pos = 0;
    for (int i=0; i<128; i++) ret[i]=0;
    while (v != 0) {
        ret[pos] = (v % 10) + '0';
        pos++;
        v = v/10;
    }
    while(pos >= 0){
        pcfb(ret[pos], x, y, color);
        x+=8;
        pos--;
    }
}
