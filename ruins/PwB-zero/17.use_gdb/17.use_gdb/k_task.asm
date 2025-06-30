;org 0x0000
bits 16

%include "routine.inc"

;----------------------------------
; スタート
;----------------------------------
global _start

_start:


setup:
    mov sp, 0x7000
    ;call set_own_seg

    mov ax, tick_addr
    mov [tick_ptr], ax

start:
    sti
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
    
    mov ah, 17
    mov al, 30
    call set_cursor_pos
    
    mov al, 'k'
    call putc
    mov al, ' '
    call putc
    mov al, ':'
    call putc

    call get_tick
    call disp_hex
    
    mov al, ':'
    call putc
    mov al, 0x00
    
.no_data:
    
    

.empty_data:
    
    mov ax, bx
    call set_cursor_pos
    
    
    ret

_s_msg: db 'k :', 0x00
_dt_save db 0

;----------------------------------
; 共通ルーチンなど（必要に応じて）
;----------------------------------
