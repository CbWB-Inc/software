;org 0x0000
bits 16

;----------------------------------
; スタート
;----------------------------------
global _start

_start:

section .text
setup:
    call set_own_seg
    
start:

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
    mov ah, 9
    mov al, 30
    call set_cursor_pos
    
    cli
    mov al, 'p'
    call putc
    mov al, '1'
    call putc
    mov al, ':'
    call putc
    call get_tick
    call disp_hex
    ;mov al, ':'
    ;call putc
    ;mov ax, sp
    ;call disp_hex


    mov al, ':'
    call putc
    
    
    call get_key
    jz .skip
    mov bx, ax
    call putc
    mov al, ':'
    call putc
    mov ax, bx
    call disp_hex
.skip:


    sti

    mov ax, bx
    call set_cursor_pos

    mov ax, bx
    call set_cursor_pos

    ret


;----------------------------------
; 共通ルーチンなど（必要に応じて）
;----------------------------------




%include "routine_imp.inc"

