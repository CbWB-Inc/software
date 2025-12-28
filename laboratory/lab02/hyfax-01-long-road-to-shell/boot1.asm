[BITS 16]
org 0x8000

%macro PUTC 1
    push ax
    mov  al, %1
    out  0xE9, al
    pop  ax
%endmacro

%include 'hyfax.asm'

jmp start
nop

OEMLabel        db 'MSDOS5.0'       ; 8 bytes
BytesPerSec     dw 0x0200
SecPerClus      db 4                ; 10MB パーティションでは4が妥当
RsvdSecCnt      dw 0x0004           ; mformatのデフォルト
NumFATs         db 2
RootEntCnt      dw 0x0200           ; HDDでは512が一般的
TotSec16        dw 0xf800          ; パーティションサイズ (9MB)
Media           db 0xf8             ; HDD
FATSz16         dw 0x0040           ; FAT16サイズ（要計算）114?
SecPerTrk       dw 0x0020
NumHeads        dw 4
HiddSec         dd 0                ; パーティション開始LBA
TotSec32        dd 0
; ======================================================

start:
    PUTC 'B'
    PUTC '1'
    PUTC ':'

    cli
    mov ax, 0x7000
    mov ss, ax
    mov sp, 0xfff0
    sti

    mov ax, _s_msg_start
    call ps

    mov ax, MON_SEG
    mov es, ax
    mov bx, MON_OFF
    mov ax, _s_target_name
    
    call loadapp

    jmp MON_SEG:MON_OFF

hlt:
    hlt
    jmp hlt

_s_target_name db 'MONITOR BIN', 0x00

%include 'loadapp.asm'
%include 'common.asm'
