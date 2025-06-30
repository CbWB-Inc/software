X86系のレガシーBIOS:ビデオ系と戯れます。
できるかどうかわからないけれど、1行エディタを作ってみようとか
実際にはechoですね。
１行自由に入力して、エンターでその内容を表示する

<Remarks timestamp="2025年5月16日 23:29:29"/>
割り込みを使って定期的に文字を出力する
それだけ



以下はtest2.asm（のはず）

org 0x7c00
bits 16

start:
    ; 画面に "B"
    mov ah, 0x0e
    mov al, 'B'
    int 0x10

    cli
    xor ax, ax
    mov ds, ax
    mov es, ax

    ; PIT 初期化（Mode 2, 約18.2Hz）
    mov al, 0x36
    out 0x43, al
    mov al, 0x00
    out 0x40, al
    mov al, 0x10
    out 0x40, al

    ; 割り込みハンドラを INT 08h（0x20）に設定
    mov ax, irq0_handler
    mov [es:0x20], ax       ; offset
    mov ax, cs
    mov [es:0x22], ax       ; segment

    sti

.loop:
    mov ah, 0x0e
    mov al, '.'
    int 0x10
    hlt
    jmp .loop

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

    ; EOI をマスタPICに通知（IRQ0はマスタ側）
    mov al, 0x20
    out 0x20, al

    pop es
    pop bx
    pop ax
    iret

cursor_pos: dw 160  ; 左上は避ける（SeaBIOSロゴがあるため）

times 510-($-$$) db 0
dw 0xaa55
