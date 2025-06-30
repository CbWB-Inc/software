;org 0x0000
bits 16

;----------------------------------
; スタート
;----------------------------------
global _start

_start:

setup:
    mov ax, cs
    mov ss, ax
    mov sp, 0x7ff0
    
    call set_own_seg
    
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
    mov ah, 11
    mov al, 30
    call set_cursor_pos
    
    cli
    mov al, 'p'
    call putc
    mov al, '2'
    call putc
    mov al, ':'
    call putc
    call get_tick
    call disp_word_hex
    sti


    mov al, '2'     ; '2', '3' に応じて変えて
    ;call write_log

    mov ax, bx
    call set_cursor_pos



    ret










;----------------------------------
; 共通ルーチンなど（必要に応じて）
;----------------------------------
%include "routine_imp.inc"

