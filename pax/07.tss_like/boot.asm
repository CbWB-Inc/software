[org 0x7c00]
[bits 16]

start:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax

    ; IRQ0 割り込みベクタを 0x0000:irq0_handler に設定
    mov word [0x20], irq0_handler      ; offset
    mov word [0x22], 0x0000            ; segment

    ; 割り込みマスクを解除（全許可）
    mov al, 0x00
    out 0x21, al

    ; 割り込み許可
    sti

.loop:
    hlt
    jmp .loop

;---------------------------------
; IRQ0 割り込みハンドラ
;---------------------------------
irq0_handler:
    push ax
    mov ah, 0x0e
    mov al, 'Z'        ; Zを表示して確認
    int 0x10
    pop ax
    mov al, 0x20      ; EOI を PIC に送る
    out 0x20, al
    iret

; ブートセクタ末尾パディング

times 510-($-$$) db 0

dw 0xaa55
