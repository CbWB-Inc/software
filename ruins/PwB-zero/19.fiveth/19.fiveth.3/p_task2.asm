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
    
    cli

    call set_own_seg
    
    mov ah, 11
    mov al, 30
    mov bx, ._s_msg
    call disp_strd

    call get_tick
    mov bx, ax
    mov ah, 11
    mov al, 33
    call disp_word_hexd

    sti


    mov al, '2'     ; '2', '3' に応じて変えて
    ;call write_log

    ret

._s_msg db 'p2:', 0x00








;----------------------------------
; 共通ルーチンなど（必要に応じて）
;----------------------------------
%include "routine_imp.inc"

%include "routine2.asm"

