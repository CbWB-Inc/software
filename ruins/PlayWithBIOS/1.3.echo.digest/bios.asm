;>===========================
;>	BIOSで遊ぼっ！
;>===========================

section .data

    _c_seg          equ 0x07c0
    _c_ex_area_addr equ 0x200

section .text

boot:
    ; set segment register
    mov ax, _c_seg
    mov ds, ax

    jmp main

;>****************************
;> hlt
;>****************************
_hlt:
    hlt
    jmp _hlt

_m_buf_str: times 128 db 0x00

section .text

;****************************
; get_str_ascii
;   キーボードから文字列を取り込んでアドレスをaxに返す
;****************************
get_str_ascii:

    mov si, _m_buf_str

._loop:

    ; キーボードの状態を確認する
    mov ah, 0x11
    int 0x16
    jne ._loop

    ; キーボードから1文字取り込む
    mov ah, 0x10
    int 0x16
    mov bx, ax
    
    ; なんだこれ？
    cmp bl, 0x20
    jg ._skip

    ; Ctrl+Retの場合終了
    cmp bx, 0x1c0a
    je ._exit

    ; Retの場合終了
    cmp bl, 0x0d
    je ._exit

    ; 空白以下ならスキップ
    cmp bl, 0x20
    jle ._skip

    ; ~以上ならスキップ
    cmp bl, 0x7e
    jg ._skip

    mov ax, bx

    cmp si, _m_buf_str
    je ._loop

    mov [si], al
    inc si

    jmp ._loop

._skip:

    mov ax, bx
    
    mov ah, 0x0e
    int 0x10

    mov [si], al
    inc si

    jmp ._loop

._exit:

    mov ax, _m_buf_str 

    ret

;>===========================
;> main
;>===========================

main:
    ; set segment register
    mov ax, _c_seg
    mov ds, ax

    ; 改行を入れて画面を整える
    mov ah, 0x0e
    mov al, 0x0d
    int 0x10
    mov al, 0x0a
    int 0x10

    ; キーボード入力処理
    call get_str_ascii
    mov bx, ax

    ; 返ってきた文字列を表示する
    mov ah, 0x0e
    mov al, 0x0d
    int 0x10
    mov al, 0x0a
    int 0x10

    mov si, bx 

_loop:
    lodsb
    or al, al
    je _exit

    int 0x10

    jmp _loop

_exit:

    ; 処理終了
    jmp _hlt

._bun: db 0x0d, 0x0a, 0x0d, 0x0a, 0x00

times 510-($-$$) db 0
db 0x55
db 0xAA

