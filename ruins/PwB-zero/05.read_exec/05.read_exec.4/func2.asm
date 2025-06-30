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
    add ax, msg
    call bseg:disp_str

    jmp bseg:main2

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
    times 0x0400-($-$$)-2 db 0


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

%include "def.asm"

;==============================================================
; ファイル長の調整
;==============================================================
_padding4:
    times 0x0800-($-$$)-2 db 0

;********************************
; セクションシグネチャ
;********************************

db 0x55
db 0xAA
