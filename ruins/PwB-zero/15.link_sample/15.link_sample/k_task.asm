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
    mov ax, cs
    mov ds, ax
    mov es, ax




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
    mov ax, cs
    mov ds, ax
    
    mov al, '!'
    call putc
    
    ret

;----------------------------------
; 共通ルーチンなど（必要に応じて）
;----------------------------------
;%include "routine.asm"

;----------------------------------
; セクション末尾
;----------------------------------
times 2048 - ($ - $$) - 2 db 0
dw 0x5E5E
