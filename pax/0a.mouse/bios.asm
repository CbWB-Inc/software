[BITS 16]
[ORG 0x7C00]

start:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax

    ; 画面初期化（80x25）
    mov ax, 0x0003
    int 0x10

    ; INT 0x74 → IRQ12 に割り込みハンドラ設定
    cli
    mov word [0x74 * 4], mouse_irq_handler
    mov word [0x74 * 4 + 2], cs

    ; PIC（マスター＆スレーブ）から IRQ12 を有効化
    in al, 0x21
    and al, 0xEF
    out 0x21, al
    in al, 0xA1
    and al, 0xFB
    out 0xA1, al

    ; マウス初期化
    call enable_mouse

    ; カーソル初期位置
    mov byte [cursor_x], 40
    mov byte [cursor_y], 12
    call draw_cursor

    sti

.loop:
    jmp .loop


; --------------------------------
; マウス初期化ルーチン
; --------------------------------
enable_mouse:
    call wait_input
    mov al, 0xA8       ; マウス有効化
    out 0x64, al

    call wait_input
    mov al, 0x20       ; コントローラ設定読み出し
    out 0x64, al
    call wait_output
    in al, 0x60
    or al, 0x02        ; マウス割り込み有効
    mov ah, al
    call wait_input
    mov al, 0x60
    out 0x64, al
    call wait_input
    mov al, ah
    out 0x60, al

    ; マウスに「有効化」命令送信
    call wait_input
    mov al, 0xD4
    out 0x64, al
    call wait_input
    mov al, 0xF4
    out 0x60, al
    ret

wait_input:
    in al, 0x64
    test al, 2
    jnz wait_input
    ret

wait_output:
    in al, 0x64
    test al, 1
    jz wait_output
    ret


; --------------------------------
; IRQ12 割り込みハンドラ (INT 0x74)
; --------------------------------
mouse_irq_handler:
    pusha

    in al, 0x60
    mov si, [mouse_index]
    mov [mouse_packet + si], al
    inc si
    cmp si, 3
    jne .store
    xor si, si

    ; カーソル更新
    mov al, [mouse_packet + 1]
    cbw
    add [cursor_x], al

    mov al, [mouse_packet + 2]
    neg al
    cbw
    add [cursor_y], al

    ; 範囲補正
    mov al, [cursor_x]
    cmp al, 0
    jl .reset_pos
    cmp al, 79
    jg .reset_pos

    mov al, [cursor_y]
    cmp al, 0
    jl .reset_pos
    cmp al, 24
    jg .reset_pos

    call draw_cursor
    jmp .eoi

.reset_pos:
    mov byte [cursor_x], 40
    mov byte [cursor_y], 12

.store:
    mov [mouse_index], si

.eoi:
    ; 割り込み終了通知（PIC）
    mov al, 0x20
    out 0xA0, al
    out 0x20, al

    popa
    iret


; --------------------------------
; カーソル描画（毎回画面を消して描画）
; --------------------------------
draw_cursor:
    call clear_screen

    mov al, [cursor_y]
    xor ah, ah
    mov bx, 160
    mul bx
    mov bx, ax
    mov al, [cursor_x]
    shl ax, 1
    add bx, ax
    mov di, bx

    mov ax, 0xB800
    mov es, ax
    mov byte [es:di], '*'
    mov byte [es:di+1], 0x1F
    ret

clear_screen:
    mov ax, 0xB800
    mov es, ax
    xor di, di
    mov cx, 80*25
.clear_loop:
    mov byte [es:di], ' '
    mov byte [es:di+1], 0x07
    add di, 2
    loop .clear_loop
    ret


; --------------------------------
; データ領域
; --------------------------------
cursor_x: db 40
cursor_y: db 12
mouse_packet: times 3 db 0
mouse_index: dw 0


; --------------------------------
; ブートセクタ署名
; --------------------------------
times 510 - ($ - $$) db 0
dw 0xAA55
