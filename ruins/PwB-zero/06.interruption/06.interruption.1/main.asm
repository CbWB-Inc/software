;>===========================
;>  実験コード
;>===========================

;>===========================
;> main
;>===========================

main:
    org 0x0200
    
    ; ビデオモードの設定
    mov ah, 0x0
    mov al, 0x3    ; 16色テキスト、80x25
    int 0x10

    ; 念のため初期化
    cld




;start:
    ; 画面に "B" を表示（動作確認用）
    mov ah, 0x0e
    mov al, 'B'
    int 0x10

;    cli

    ; PIT 初期化（Mode 2, 約18.2Hz）
    mov al, 0x36
    out 0x43, al
    mov al, 0x00
    out 0x40, al
    mov al, 0x10
    out 0x40, al

    ; 一時的に es=0 にして割り込みベクタを書き換え
    push es
    xor ax, ax
    mov es, ax

    mov ax, irq0_handler
    mov [es:0x20], ax       ; offset for INT 08h
    mov ax, cs
    mov [es:0x22], ax       ; segment

    pop es

    sti

.loop:
    mov ah, 0x0e
    mov al, '.'
    int 0x10
    hlt
    jmp .loop

; --- IRQ0 タイマ割り込みハンドラ ---
irq0_handler:
    push ax
    push bx
    push es

    mov ax, 0xb800
    mov es, ax
    mov bx, [cursor_pos]
    mov byte [es:bx], 'A'
    mov byte [es:bx+1], 0x1f
    add word [cursor_pos], 2
    cmp word [cursor_pos], 4000
    jb .skip_reset
    mov word [cursor_pos], 0
.skip_reset:

    ; EOI（End Of Interrupt）をマスタPICへ送信
    mov al, 0x20
    out 0x20, al

    pop es
    pop bx
    pop ax
    iret

cursor_pos: dw 160      ; 表示位置（80*2で2行目開始）

;>****************************
;> パディング
;>****************************

times 510-($-$$) db 0

;********************************
; ブートセクタシグネチャ
;********************************

db 0x55
db 0xAA
