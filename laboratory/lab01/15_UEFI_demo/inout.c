#include <efi.h>
#include <efilib.h>
#include <stdint.h>
#include <stddef.h>
#include "log.h"
#include "common.h"

#define KEYBUF_SIZE 32
#define KEY_BUF_SIZE 128
#define KEY_HIS_BUF_SIZE 32

char _h_buf[KEY_HIS_BUF_SIZE][KEY_BUF_SIZE];    // Key Histry Buf
int8_t _h_pos = 0;
int8_t _h_m_pos = 0;

extern uint16_t _scancode_table[];
// extern uint16_t _font_table[];
extern uint8_t keybuf[KEYBUF_SIZE];
extern int keybuf_w;
extern int keybuf_r;
extern uint32_t _c_x, _c_y, _color;
extern uint32_t* fb;

void scrollfb() {
    int screen_width = 1280;
    int screen_height = 800;
    int line_height = 16;
    int char_width = 8;

    uint32_t* fb_virtual = fb;

    // コピー元: 1行下から
    uint32_t* src = fb_virtual + (line_height * screen_width);
    // コピー先: 最上段
    uint32_t* dst = fb_virtual;

    // 上へスクロール（49行分）
    for (int y = 0; y < screen_height - line_height; y++) {
        for (int x = 0; x < screen_width; x++) {
            dst[y * screen_width + x] = src[y * screen_width + x];
        }
    }

    // 最下行を消去
    for (int y = screen_height - line_height; y < screen_height; y++) {
        for (int x = 0; x < screen_width; x++) {
            dst[y * screen_width + x] = 0x00000000; // 黒
        }
    }
}

void locate(uint32_t x, uint32_t y){
    rectfb( _c_x * 8, _c_y * 16, 8*3 , 16,0x00);
    _c_x = x;
    _c_y = y;
    pcfb(']', _c_x * 8, _c_y * 16, 0xf0f0f0);
    pcfb('[', (_c_x + 1) * 8, _c_y * 16, 0xf0f0f0);
}

int has_keycode(void) {
    return keybuf_w != keybuf_r;
}

int get_keycode(void) {
    if (!has_keycode()) return -1;
    uint8_t code = keybuf[keybuf_r];
    keybuf_r = (keybuf_r + 1) % KEYBUF_SIZE;
    return code;

}


uint16_t scancode_decord(uint16_t keycode){
    uint8_t cond = (keycode >> 8) & 0xff;
    uint8_t key = (keycode &  0x00ff);
    uint8_t nbc = key & 0x7f; 
    if (nbc == 0x36 || nbc == 0x2a){    // 右シフトと左シフト Bit 7
        if (key & 0x80) {       // break
            if (!(cond & 0x6e)) {
                cond &= 0x7e; // 寝かす
            } else {
                cond &= 0x7f; // 寝かす
            }
            key = 0x00;
        } else {                // mark
            cond |= 0x81; // 立てる
            key = 0x00;
        }
        keycode = (cond << 8) | key;
    } else if (nbc == 0x1d) {           // ctrl Bit6
        if (key & 0x80) {       // break
            if (!(cond & 0xae)) {
                cond &= 0xbe; // 寝かす
            } else {
                cond &= 0xbf; // 寝かす
            }
            key = 0x00;
        } else {                // mark
            cond |= 0x41; // 立てる
            key = 0x00;
        }
        keycode = (cond << 8) | key;
    } else if (nbc == 0x38) {           // alt Bit5
        if (key & 0x80) {       // break
            if ( !(cond & 0xce) ) {
                cond &= 0xde; // 寝かす
            } else {
                cond &= 0xdf; // 寝かす
            }
            key = 0x00;
        } else {                // mark
            cond |= 0x21; // 立てる
            key = 0x00;
        }
        keycode = (cond << 8) | key;
    } else if (nbc == 0x46) {           // scroll lock  Bit4
        if (key & 0x80) {       // break
            if (cond & 0xee) {       // break
                cond &= 0xef; // 寝かす
            } else {
                cond &= 0xee; // 寝かす
            }
        } else {                // mark
            cond |= 0x11; // 立てる
        }
        key = 0x00;
        keycode = (cond << 8) | key;
    } else if (nbc == 0x45) {           // num lock bit3
        if (key & 0x80) {       // break
            if (cond & 0xf6) {
                cond &= 0xf7; // 寝かす
            } else {
                cond &= 0xf6; // 寝かす
            }
        } else {                // mark
            cond |= 0x09; // 立てる
        }
        key = 0x00;
        keycode = (cond << 8) | key;
    } else if (nbc == 0x45) {           // caps lock    bit2
        if (key & 0x80) {       // break
            if (cond & 0xfa) {
                cond &= 0xfa; // 寝かす
            } else {
                cond &= 0xfb; // 寝かす
            }
        } else {                // mark
            cond |= 0x05; // 立てる
        }
        key = 0x00;
        keycode = (cond << 8) | key;
    } else {
        uint16_t matchkey = _scancode_table[0];
        uint16_t searchkey = ((cond & 0x80) << 8 ) | key;
        int asc = 0x20;
        int cnt2 = 0;
        while (matchkey != 0xffff){
            if (matchkey == searchkey) {
                asc =  _scancode_table[cnt2 * 2 + 1];
                break;
            }
            cnt2++;
            matchkey = _scancode_table[cnt2 * 2];
        }
        keycode = (cond << 8) | asc;
        if (key & 0x80) {       // break
            //if (!(cond & 0xe0)) {
                keycode &= 0xfeff;
            //}
        }
    }
    return keycode;
}

void line_input(uint8_t *str_buf){
    uint32_t* fb_virtual = fb;


    for (int i = 0; i < 128; i++) str_buf[i] = 0;
    uint16_t _pos = 0;
    uint16_t keycode = 0;
    while(1) {

        // int code = getkeyp(keycode);
        int code = get_keycode();
        if (!(code >0)) continue;
        keycode = (keycode & 0xff00) | code;
        keycode = scancode_decord(keycode);
        uint8_t asc = keycode & 0xff;

        // puthexb(code);putc(' ');


        if (keycode & 0x0100){
            //puthexfb(keycode, _c_x * 8, (_c_y + 3) * 16, _color, (uint32_t *) fb_virtual, 1280);
            if ((keycode & 0x00ff) == 0x0d){        // lfの場合(CR)
                if (_c_y + 1 == 50) {
                    _c_y = 48;
                    scrollfb(fb_virtual);
                } 
                locate(0, _c_y + 1);
                if (strlen(str_buf)>0) {
                    strcpy(_h_buf[_h_pos], str_buf);
                    _h_pos++;
                    if(_h_pos > _h_m_pos) {
                        _h_m_pos = _h_pos;
                    } else {
                        // _h_m_pos++;
                    }
                    if (_h_pos > KEY_HIS_BUF_SIZE) _h_pos = 0;
                    
                }
                break;
            } else if ((keycode & 0x00ff) == 0x08){ // BSの場合
                _c_x--;
                str_buf[_pos] = 0x00;
                str_buf[_pos - 1] = 0x00;
                _pos--;
                locate(_c_x, _c_y);
            } else if ((keycode & 0x00ff) == 0x11){ // ↑の場合
                int len = strlen(str_buf);
                _c_x =0;
                rectfb( _c_x * 8, _c_y * 16, (_c_x + len) * 8  + 8 * 2, _c_y * 16 + 16, 0x00);
                _h_pos--;
                if (_h_pos < 0) _h_pos = _h_m_pos; 
                // if (_h_pos > _h_m_pos) _h_pos = 0; 
                
                strcpy(str_buf, _h_buf[_h_pos]);
                psfb((uint8_t *)str_buf, _c_x * 8, _c_y * 16, _color);
                _c_x += strlen(str_buf);
                locate(_c_x, _c_y);
                //putsfb((uint8_t *)_h_buf[_h_c_pos], _c_x * 8, (_c_y + 1) * 16, _color, (uint32_t *) fb_virtual, 1280);
            } else if ((keycode & 0x00ff) == 0x12){ // ↓の場合
                int len = strlen(str_buf);
                _c_x = 0;
                rectfb(_c_x * 8, _c_y * 16, (_c_x + len) * 8 + 8 * 2 , _c_y * 16 + 16, 0x00);
                _h_pos++;
                // if (_h_pos < 0) _h_pos = _h_m_pos; 
                if (_h_pos > _h_m_pos) _h_pos = 0; 
                
                strcpy(str_buf, _h_buf[_h_pos]);
                psfb((uint8_t *)str_buf, _c_x * 8, _c_y * 16, _color);
                _c_x += strlen(str_buf);
                locate(_c_x, _c_y);
                //putsfb((uint8_t *)_h_buf[_h_c_pos], _c_x * 8, (_c_y + 1) * 16, _color, (uint32_t *) fb_virtual, 1280);
            } else if ((keycode & 0x00ff) == 0x13){ // ←の場合
            } else if ((keycode & 0x00ff) == 0x14){ // →の場合
            } else if ((keycode & 0x00ff) == 0x1b){ // ESCの場合
            } else if ((keycode & 0x00ff) == 0x09){ // TABの場合
            } else if ((keycode & 0x00ff) == 0x7f){ // DELの場合
            } else if ((keycode & 0x00ff) == 0x0f){ // 漢字の場合
            } else if (!((keycode & 0xfe00) && (asc == 0x00))){
                pcfb(asc, _c_x * 8, _c_y * 16, _color);
                _c_x++;
                str_buf[_pos] = asc;
                _pos++;
                locate(_c_x, _c_y);
            }
        }
    }
}

