; common.inc

%define PIC1_CMD  0x20
%define PIC1_DATA 0x21

; ----------------------------
; IRQ0 フック（INT 08h）
; ----------------------------
hook_irq0:
    cli
    push ax
    push bx
    push dx
    push ds

    mov ax, 0x9000        ; main.bin+irq0.asm をロードしたセグメント
    mov bx, irq0_handler  ; ハンドラのオフセット

    mov dx, 0x0000
    mov ds, dx            ; ベクタテーブルは物理アドレス0にある

    mov [0x20], bx        ; INT 0x08 offset
    mov [0x22], ax        ; INT 0x08 segment

    ; （デバッグ用にダンプしたい場合はここで call far [disp_mem_ptr]）

    pop ds
    pop dx
    pop bx
    pop ax
    sti
    ret
; ----------------------------
; PIT 初期化（Channel 0）
; ----------------------------
init_pit:


    ; 0x36: square wave generator, LSB then MSB
    mov al, 0x36
    out 0x43, al

    ; 1193182 / N = 周波数。ここでは 0x1000 = 約18Hz
    mov ax, 0x1000
    out 0x40, al
    mov al, ah
    out 0x40, al
    ret

; ----------------------------
; PIT 初期化（Channel 0）
; ----------------------------
; ----------------------------
; PIC 初期化（IRQ0 を使う）
; ----------------------------
init_pic:
    mov al, 0x11
    out 0x20, al
    out 0xA0, al

    mov al, 0x08
    out 0x21, al
    mov al, 0x70
    out 0xA1, al

    mov al, 0x04
    out 0x21, al
    mov al, 0x02
    out 0xA1, al

    mov al, 0x01
    out 0x21, al
    out 0xA1, al

    ; IRQ0（PIT）だけ有効
    mov al, 0b11111110
    out 0x21, al

    ; スレーブ全部無効
    mov al, 0xFF
    out 0xA1, al

    ; 無効化
    ;in  al, 0x21
    ;or  al, 0x01
    ;out 0x21, al

    ; 有効化
    ;in  al, 0x21
    ;and al, 0xFE
    ;out 0x21, al

	ret
