org 0x0000
bits 16

;----------------------------------
; スタート
;----------------------------------
setup:
    mov sp, 0x7800
    mov ax, cs
    mov ds, ax
    mov es, ax
start:
    sti
    mov ax, 2
    call _wait
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
    call get_cursor_pos
    mov bx, ax
    mov ah, 0x17
    mov al, 0x40
    call set_cursor_pos
    
    cli
    mov al, 'd'
    call putc
    mov al, ':'
    call putc
    call get_tick
    call disp_word_hex
    sti

    mov ax, bx
    call set_cursor_pos

    ret

;----------------------------------
; 共通ルーチンなど（必要に応じて）
;----------------------------------
%include "routine.asm"

;----------------------------------
; セクション末尾
;----------------------------------
times 2048 - ($ - $$) - 2 db 0
dw 0x5E5E
