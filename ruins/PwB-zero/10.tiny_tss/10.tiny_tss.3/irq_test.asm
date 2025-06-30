org 0x7c00
bits 16

start:
    cli

    ; VGA動作確認
    mov ah, 0x0e
    mov al, 'S'
    int 0x10        ; 画面に 'S' が出る → 起動OK

    ; PIT (IRQ0) 初期化
    mov al, 0x36
    out 0x43, al
    mov ax, 0x4E20
    out 0x40, al
    mov al, ah
    out 0x40, al

    ; 一時的に es=0 にして割り込みベクタを書き換え
    push es
    xor ax, ax
    mov es, ax

    ; 割り込みハンドラのオフセット設定
    xor ax, ax
    mov es, ax

    ; IRQ0 の割り込みベクタ番地 = 0x08 * 4 = 0x20
    mov bx, 0x20

    ; 元のハンドラ退避（offset, segment）
    ;mov ax, [es:bx]
    ;mov [old_irq0_ptr], ax
    ;mov ax, [es:bx+2]
    ;mov [old_irq0_ptr+2], ax

    mov ax, cs
    mov [es:0x22], ax
    mov word [es:0x20], irq0_handler
    ; 2742
    
    ; PIC マスク解除 ← これを追加！
    mov al, 0x00
    out 0x21, al

    pop es

; ====================================
; PIC 初期化（標準的な 8086 向け）
; ====================================
    ; マスタ PIC（0x20〜0x21）初期化
    mov al, 0x11         ; ICW1: エッジトリガ、ICW4あり
    out 0x20, al
    mov al, 0x08         ; ICW2: 割り込みベクタの先頭（IRQ0 = INT 08h）
    out 0x21, al
    mov al, 0x04         ; ICW3: スレーブ PIC は IRQ2 に接続
    out 0x21, al
    mov al, 0x01         ; ICW4: 8086 モード
    out 0x21, al

    ; スレーブ PIC（0xA0〜0xA1）初期化（使わない場合も必要）
    mov al, 0x11
    out 0xA0, al
    mov al, 0x70         ; ICW2: 割り込みベクタの先頭（IRQ8 = INT 70h）
    out 0xA1, al
    mov al, 0x02         ; ICW3: スレーブは IRQ2 に接続
    out 0xA1, al
    mov al, 0x01         ; ICW4: 8086 モード
    out 0xA1, al

    ; 割り込みマスク解除（IRQ0 のみ有効）
;    mov al, 0b11111110   ; IRQ0 を許可
;    out 0x21, al
;    mov al, 0xFF         ; 全部マスク（今回はスレーブ使わない）
;    out 0xA1, al
    
    ; 無効化
    ;in  al, 0x21
    ;or  al, 0x01
    ;out 0x21, al

    ; 有効化
    in  al, 0x21
    and al, 0xFE
    out 0x21, al
    

    sti

.halt:
    hlt
    jmp .halt

irq0_handler:
    mov al, '!'
    mov ah, 0x0e
    int 0x10

    ;mov ax, 0x1000
    ;out 0x40, al
    ;mov al, ah
    ;out 0x40, al

    mov al, 0x20
    out 0x20, al

    sti

    iret

times 510-($-$$) db 0
dw 0xAA55
