org 0x7e00
bits 16

;extern task_switch
;extern tss1
;extern tss2

main:
    ; 画面に 'M' 表示
    mov ah, 0x0e
    mov al, 'M'
    int 0x10

    cli

    ; セグメント設定
    mov ax, 0x07c0
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7c00

    ; IRQ0の割り込みベクタをtask_switchに設定
    mov ax, cs
    mov [0x0022], ax         ; CS
    mov word [0x0020], task_switch

    ; PIT設定（約18.2Hz）
    mov al, 0x36
    out 0x43, al
    mov ax, 0x4e20           ; 0x4e20 = 20000
    out 0x40, al
    mov al, ah
    out 0x40, al

    ; IRQ0マスク解除
    in al, 0x21
    and al, 0b11111110
    out 0x21, al

    ; TSS初期化
    mov word [tss1 + 0], 0x0000    ; IP
    mov word [tss1 + 2], 0x7000    ; CS
    mov word [tss1 + 4], 0x7000    ; SP
    mov word [tss1 + 6], 0x07c0    ; SS
    mov word [tss1 + 8], 0x0200    ; FLAGS

    mov word [tss2 + 0], 0x0000
    mov word [tss2 + 2], 0x6800
    mov word [tss2 + 4], 0x6800
    mov word [tss2 + 6], 0x07c0
    mov word [tss2 + 8], 0x0200

    sti

    ; 最初のタスクへジャンプ
    push word [tss1 + 8]
    push word [tss1 + 2]
    push word [tss1 + 0]
    iret

; セクション終端パディング
_padding:
    times 0x0400-($-$$)-2 db 0

db 0x55
db 0xAA


%include "task.asm"

