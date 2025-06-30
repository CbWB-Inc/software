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
    mov ah, 0x16
    mov al, 0x40
    call set_cursor_pos
    
    cli
    mov al, 'd'
    call putc
    mov al, ':'
    call putc
    
    
    mov ax, 2
    call _wait
    call read_log
    call putc
    

    ;push ds
    ;push es
    ;mov ax, c_data_seg
    ;mov ds, ax
    ;mov es, ax
    ;call get_c_msg_off
    ;mov di, ax
    ;call read_log_str
    ;mov ax, di
    ;call disp_word_hex
    ;pop es
    ;pop ds


    sti

    mov ax, bx
    call set_cursor_pos

    ret

;----------------------------------
; 共通ルーチンなど（必要に応じて）
;----------------------------------
%include "routine.asm"


buf:
    times 64 db 0

;----------------------------------
; セクション末尾
;----------------------------------
times 2048 - ($ - $$) - 2 db 0
dw 0x5E5E
