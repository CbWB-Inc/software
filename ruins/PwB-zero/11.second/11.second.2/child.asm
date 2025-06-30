; task1.asm
org 0x0000
bits 16

jmp start

; context 保存領域（sp, ss, cs, ip）
task1_ctx:
    dw 0          ; sp
    dw 0          ; ss
    dw 0x3000     ; cs
    dw context    ; ip

;>********************************
;> 開始
;>********************************
start:
    cli
    mov ax, 0x3000
    mov ds, ax
    mov es, ax
    ;mov ss, ax
    ;mov sp, 0x6c00
    sti

    ; 表示してループ
context:
    call disp_a

    ;jmp 0x9000:0x00af
    retf

;.loop:
;    hlt
;    jmp .loop

disp_a:
    mov ah, 0x0e
    mov al, 'A'
    int 0x10
    ret

;>********************************
;> 外部ファイル読み込み
;>********************************

%include "routine.asm"

;-------------------------------
; セクションシグネチャ
;-------------------------------
times 2048 - ($ - $$) - 2 db 0
dw 0x5E5E
