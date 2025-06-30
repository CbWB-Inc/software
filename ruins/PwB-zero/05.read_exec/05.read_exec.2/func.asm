org 0x0000  ; どこに読まれても問題ないように0で書く（後で動的に補正）

start:
    ; 自分の現在の CS:IP を取得
    add bx, 0x05
    call bx
    pop si         ; SI = return address（IPに相当）
    mov ax, cs
    mov ds, ax     ; DSをCSに合わせる
    mov es, ax

    sub bx, 0x05
    mov [baddr], bx

    mov ah, 0x0e
    mov al, 'H'
    int 0x10
    mov al, 'i'
    int 0x10
    mov al, '!'
    int 0x10
    mov al, 0x0a
    int 0x10
    mov al, 0x0d
    int 0x10

    ; 以降の文字列やデータ参照は DS:SI 相対で処理可能
    mov ax, [baddr]
    add ax, msg2
    ;call 0x07c0:disp_str
    call bseg:disp_str

    jmp bseg:main2

    ; 表示処理（BIOS）
    mov ax, [baddr]
    mov ds, ax
    mov si, ds:msg
    mov ah, 0x0e
.print:
    lodsb          ; AL ← DS:SI
    or al, al
    jz .hang
    int 0x10
    jmp .print

.hang:
;    hlt
;    jmp .hang
    jmp 0x07c0:main

msg db "It works!", 0x0d, 0x0a, 0x00
msg2 db "It works!!!", 0x0d, 0x0a, 0x00
baddr dw 0

bseg equ 0x07c0


;==============================================================
; 仮バイオスの末端
;==============================================================
_padding3:
    times 0x3200-($-$$)-2 db 0


;********************************
; セクションシグネチャ
;********************************

db 0x55
db 0xAA

db 'TEST AREA', 0x00, 0x00

test_rtn2:

    mov ax, ._c_msg
    call disp_str

    ret

._c_msg: db 'test message', 0x0a, 0x0d, 0x00


;********************************
; サブルーチンテーブル
;********************************


subrtn_tbl:
  _hlt:         dw 0x0022
;  main:         dw 0x0200
;  main2:        dw 0x022B
;  disp_word_hex: dw 0x2391
;  disp_nl:       dw 0x23A2
;  disp_str:      dw 0x230F

  main equ 0x0200
  main2 equ 0x0206
  disp_word_hex equ 0x2391
  disp_nl equ 0x230F
  no_ope equ 0x0468
  disp_str equ 0x23A2 


;  disp_str: 
;    dw 0x23A2
;    dw 0x07c0


;==============================================================
; ファイル長の調整
;==============================================================
_padding4:
    times 0x3D00-($-$$)-2 db 0

;********************************
; セクションシグネチャ
;********************************

db 0x55
db 0xAA
