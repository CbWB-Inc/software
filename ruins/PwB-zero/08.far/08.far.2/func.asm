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
    ;mov ds, bx
    ;mov es, bx

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
    ;mov ax, [baddr]
    ;add ax, msg2
    
    mov ax, msg2
    call disp_str
    
    
;    mov bx, disp_str

;    add bx, 0x2800
    ;call bseg:bx
    ;call disp_str
    ;mov word [.jmp_addr+2], bseg    ; segment

;    mov word [.jmp_addr], bx        ; offset
;    mov word [.jmp_addr+2], 0x07c0    ; segment
;    jmp far [.jmp_addr]


    jmp bseg:main2

.hang:
    hlt
    jmp .hang
;    jmp 0x07c0:main

.jmp_addr:
    dw  0
    dw  0

msg db "It works!", 0x0d, 0x0a, 0x00
msg2 db "It works!!!", 0x0d, 0x0a, 0x00
baddr dw 0

bseg equ 0x07c0
main2           equ 0x2800

;********************************
; disp_word_hex
;       2バイト（1ワード）のデータを表示する
;	（ビッグエンディアン表記）
; param : ax : 表示するword
;********************************
disp_word_hex:

    push ax
    push bx

    mov bx, ax
    mov al, bh
    call disp_byte_hex

    mov al, bl
    call disp_byte_hex

._end:

    pop bx
    pop ax

    ret


;********************************
; disp_byte_hex
;      1バイトの数値を16進で表示する
; param  : al : 表示したい数値
;********************************
disp_byte_hex:
    push ax
    push bx

    call bin_byte_hex
    mov ah, 0x0e
    mov al, bh
    int 0x10
    mov al, bl
    int 0x10

    pop bx
    pop ax

    ret


;********************************
; bin_byte_hex
;       1バイトの数値を16進文字列に変換する
; param  : al : 変換したい数値
; return : bx : 変換した2文字の16進文字
;********************************
bin_byte_hex:
    push cx
    push dx

    mov cl, al
    sar al, 4
    and al, 0x0f
    mov ah, 0
    call bin_nibble_hex
    mov dh, bl

    mov al, cl
    and al, 0x0f
    mov ah, 0
    call bin_nibble_hex
    mov dl, bl

    mov bx, dx

    pop dx
    pop cx

    ret


;********************************
; bin_nibble_hex
;       4bit整数を16進文字に変換する
;       0～15 -> '0'～'f'
; param  : al : 変換する数値
;               16以上を指定すると上位ニブルは無視され、下位ニブルが変換されて返る
;                 e.g. 0x21 -> '1'
; return : bl : 変換された文字
;******************************
bin_nibble_hex:
        and al, 0x0f
        cmp al, 0x09
        ja .gt_9
        add al, 0x30
        jmp .cnv_end
.gt_9:
        add al, 0x37

.cnv_end:
        mov bl, al
        ret


;****************************
; disp_nl
;   改行する
;****************************
disp_nl:

    push ax

;    mov ax, ._s_crlf
;    call disp_str

    mov ah, 0x0e
    mov al, 0x0d
    int 0x10
    mov al, 0x0a
    int 0x10
    



    pop ax
    
    ret

    ._s_crlf:       db 0x0d, 0x0a, 0x00


;********************************
; disp_str
;       display null-terminated string.
; param : ax : addr of mem where string is set.
;********************************
disp_str:

    push ax
    push si

    mov si, ax
    mov ah, 0x0E

._loop:
    lodsb
    or al, al
    jz ._loop_end
    int 0x10
    jmp ._loop

._loop_end:
    pop si
    pop ax

    ret




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

;********************************
; サブルーチンテーブル
;********************************


subrtn_tbl:
  _hlt:         dw 0x0022

;%include "def.asm"

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
