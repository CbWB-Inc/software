org 0x0000
bits 16

;----------------------------------
; スタート
;----------------------------------
setup:
    mov sp, 0x7000
    mov ax, cs
    mov ds, ax
    mov es, ax

start:
    sti
    mov ax, 2
    call _wait
    call task_body
    sti
    hlt
    jmp start

;----------------------------------
; 処理本体（単純な表示など）
;----------------------------------
task_body:
    mov ax, cs
    mov ds, ax
    
    call get_cursor_pos
    mov cx, ax
    mov ah, 0x15
    mov al, 0x40
    call set_cursor_pos
    
    mov al, 'k'
    call putc
    mov al, '_'
    call putc
    mov al, 't'
    call putc
    mov al, 'a'
    call putc
    mov al, 's'
    call putc
    mov al, 'k'
    call putc    
    mov ah, 0x16
    mov al, 0x41
    call set_cursor_pos
    call get_tick
    call disp_word_hex

    mov ax, cx
    call set_cursor_pos
    sti
    ret

;global _s_p_msg
;_s_p_msg db 'p_task', 0x00

_w_test dw 0x705f

;----------------------------------
; 共通ルーチンなど（必要に応じて）
;----------------------------------
%include "routine.asm"

;----------------------------------
; セクション末尾
;----------------------------------
times 2048 - ($ - $$) - 2 db 0
dw 0x5E5E
