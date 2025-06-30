org 0x0000
bits 16

section .data
state: db 0  ; 進行状態（0〜2）

section .text

start:
    jmp main_loop

; -------------------------------------
; 状態変数（0〜2）を使ってステップ実行
; -------------------------------------

main_loop:
    mov al, [state]
    cmp al, 0
    je .step0
    cmp al, 1
    je .step1
    cmp al, 2
    je .step2
    jmp .loop

.step0:
    call set_cursor_3_10
    mov ah, 0x0e
    mov al, 'X'
    int 0x10
    call pwait
    mov byte [state], 1
    jmp .loop

.step1:
    call set_cursor_3_11
    mov ah, 0x0e
    mov al, 'Y'
    int 0x10
    call pwait
    mov byte [state], 2
    jmp .loop

.step2:
    call set_cursor_3_12
    mov ah, 0x0e
    mov al, 'Z'
    int 0x10
    call pwait
    mov byte [state], 0
    jmp .loop

.loop:
    hlt
    jmp main_loop

; -------------------------------------
; カーソル位置固定ルーチン
; -------------------------------------
set_cursor_3_10:
    mov ah, 0x02
    mov bh, 0
    mov dh, 3
    mov dl, 10
    int 0x10
    ret

set_cursor_3_11:
    mov ah, 0x02
    mov bh, 0
    mov dh, 3
    mov dl, 11
    int 0x10
    ret

set_cursor_3_12:
    mov ah, 0x02
    mov bh, 0
    mov dh, 3
    mov dl, 12
    int 0x10
    ret

pwait:
    mov cx, 0xFFFF
.wloop:
    nop
    loop .wloop
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
