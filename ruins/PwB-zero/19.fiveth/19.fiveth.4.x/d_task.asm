;org 0x0000
bits 16

;----------------------------------
; スタート
;----------------------------------
global _start

_start:

setup:
    mov sp, 0x7800
    mov ax, cs
    mov ds, ax
    mov es, ax
    ;call cls
    mov ah, 0x0
    mov al, 0x0
    call set_cursor_pos
    
start:
    sti
    ;mov ax, 2
    ;call _wait
    ;mov ax, 1
    ;call sleep
    call task_body
    sti
    hlt
    jmp start

;----------------------------------
; 処理本体（単純な表示など）
;----------------------------------
task_body:
    
    cli
    call set_own_seg
    
    mov ah, 15
    mov al, 30
    mov bx, ._s_msg
    call disp_strd

    call get_tick
    mov bx, ax
    mov ah, 15
    mov al, 33
    call disp_word_hexd


    sti

    ret

._s_msg db 'd :', 0x00

;----------------------------------
; 共通ルーチンなど（必要に応じて）
;----------------------------------
%include "routine_imp.inc"

%include "routine2.asm"

buf:
    times 64 db 0

