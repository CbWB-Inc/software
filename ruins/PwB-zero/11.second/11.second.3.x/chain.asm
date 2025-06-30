org 0x0000
bits 16

;----------------------------------
; スタート
;----------------------------------
start:

    ;cli
    ;mov ax, 0x3000
    ;mov ds, ax
    ;mov es, ax
    ;sti

    ; 実行地点を保存（初回のみ）
    ;call save_context

    ; 表示など処理
    ;call task_body

    ; 処理後復帰
    ;iret


.loop:
    call task_body
    hlt
    jmp .loop

;----------------------------------
; 処理本体（単純な表示など）
;----------------------------------
task_body:
    mov ah, 0x0E
    mov al, 'B'
    int 0x10
    ret

;----------------------------------
; context 保存ルーチン
;----------------------------------
save_context:
    pushf
    push cs
    push save_return      ; ← 直接 push する

    ; ip / cs / flags を context に保存
    pop ax
    mov [context + 0], ax     ; ip
    pop ax
    mov [context + 2], ax     ; cs
    pop ax
    mov [context + 4], ax     ; flags

    ; 汎用レジスタ類
    mov [context + 6], ax     ; ax
    mov [context + 8], bx
    mov [context +10], cx
    mov [context +12], dx
    mov [context +14], si
    mov [context +16], di
    mov [context +18], bp

    mov ax, ds
    mov [context +20], ax
    mov ax, es
    mov [context +22], ax
    mov ax, ss
    mov [context +24], ax
    mov ax, sp
    mov [context +26], ax

save_return:
    ret


;----------------------------------
; コンテキスト構造体（フル）
;----------------------------------
context:
    dw 0      ; ip
    dw 0      ; cs
    dw 0      ; flags
    dw 0      ; ax
    dw 0      ; bx
    dw 0      ; cx
    dw 0      ; dx
    dw 0      ; si
    dw 0      ; di
    dw 0      ; bp
    dw 0      ; ds
    dw 0      ; es
    dw 0      ; ss
    dw 0      ; sp

context_size equ 28


;----------------------------------
; 共通ルーチンなど（必要に応じて）
;----------------------------------
%include "routine.asm"

;----------------------------------
; セクション末尾
;----------------------------------
times 2048 - ($ - $$) - 2 db 0
dw 0x5E5E
