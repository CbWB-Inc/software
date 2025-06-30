;>===========================
;>	BIOSで遊ぼっ！
;>===========================

org 0x7c00
bits 16

_c_seg          equ 0x07c0
_c_ex_area_addr equ 0x200

boot:
    cli

    ; セグメント設定
    mov ax, _c_seg
    mov ds, ax
    mov es, ax
    mov ss, ax
    ;mov sp, 0x7c00 ; 必要なら有効に

    ;===========================
    ; 画面に 'B' を表示（起動確認用）
    ;===========================
    mov ah, 0x0e
    mov al, 'B'
    int 0x10

    ;===========================
    ; main.bin 読み込み（0x200 に）
    ; セクタ 2〜 （合計 0x20 セクタ = 約16KB）
    ;===========================
    mov bx, _c_ex_area_addr

    mov ah, 0x02          ; BIOS read
    mov al, 0x07          ; 32セクタ（0x20）
    mov ch, 0x00          ; Cylinder
    mov cl, 0x02          ; セクタ2（1 origin）
    mov dh, 0x00          ; Head
    mov dl, 0x80          ; First HDD

    int 0x13
jc disk_error      ; CF=1（キャリーフラグ）ならエラー

jmp continue

disk_error:
    mov ah, 0x0e
    mov al, 'E'
    int 0x10
    cli
    hlt

continue:
    
    ;===========================
    ; func.asm 読み込み（0x7000 に）
    ; セクタ 9（BIOSではCL = 0x09）
    ;===========================
    mov bx, 0x7000

    mov ah, 0x02
    mov al, 0x01          ; 1セクタ
    mov ch, 0x00
    mov cl, 0x19          ; セクタ9（Makefile上でfunc.binの位置）
    mov dh, 0x00
    mov dl, 0x80

    int 0x13
jc disk_error      ; CF=1（キャリーフラグ）ならエラー

jmp continue2

disk_error2:
    mov ah, 0x0e
    mov al, 'F'
    int 0x10
    cli
    hlt

continue2:
    
    ;===========================
    ; func2.asm 読み込み（0x6800 に）
    ; セクタ 11（CL = 0x0B）
    ;===========================
    mov bx, 0x6800

    mov ah, 0x02
    mov al, 0x01
    mov ch, 0x00
    mov cl, 0x1b          ; セクタ11
    mov dh, 0x00
    mov dl, 0x80

    int 0x13
jc disk_error3      ; CF=1（キャリーフラグ）ならエラー

jmp continue3

disk_error3:
    mov ah, 0x0e
    mov al, 'G'
    int 0x10
    cli
    hlt

continue3:
    
    ;===========================
    ; メインへジャンプ
    ;===========================
    jmp _c_seg:0x200

;===========================
; hltループ（未使用）
;===========================
_hlt:
    hlt
    jmp _hlt

;===========================
; ブートローダパディング
;===========================

times 510-($-$$) db 0
db 0x55
db 0xAA
