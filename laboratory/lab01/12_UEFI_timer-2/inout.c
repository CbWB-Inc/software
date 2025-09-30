#include <efi.h>
#include <efilib.h>
#include <stdint.h>
#include <stddef.h>
#include "log.h"
#include "common.h"

extern uint16_t _scancode_table[];

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