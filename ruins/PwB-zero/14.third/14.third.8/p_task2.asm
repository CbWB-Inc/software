org 0x0000
bits 16

;----------------------------------
; スタート
;----------------------------------
setup:
    mov sp, 0x7ff0
    call set_own_ds
    
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
    mov ah, 0x10
    mov al, 0x40
    call set_cursor_pos
    
    cli
    mov al, '2'
    call putc
    mov al, ':'
    call putc
    call get_tick
    call disp_word_hex
    sti


    mov al, '2'     ; '2', '3' に応じて変えて
    call write_log





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
