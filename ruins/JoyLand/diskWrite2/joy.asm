;>===========================
;>	JoyLand
;>===========================
section .text

boot:
    ; set segment register
    mov ax, _c_seg
    mov ds, ax

    ;
    ; disk read
    ;
    mov ax, _c_seg
    mov es, ax
    mov bx, _c_ex_area_addr

    mov ah, 0x02 ; Read Sectors From Drive
    mov dl, 0x80 ; Drive
    mov al, 0x40 ; Sectors To Read Count ;
    mov ch, 0x00 ; Cylinder
    mov cl, 0x02 ; Sector(starts from 1, not 0) ; set 2. becouse not need MBR
    mov dh, 0x00 ; Head
    int 0x13     ; Execute disk read

    jmp main

;>****************************
;> hlt
;>****************************
_hlt:
    hlt
    jmp _hlt

;>********************************
;> definition of variables
;>********************************

    _c_seg          equ 0x07c0
    _c_ex_area_addr equ 0x200

    _c_true         equ '1'
    _c_false        equ '0'

    _b_true         equ 1
    _b_false        equ 0

    _s_crlf:       db 0x0d, 0x0a, 0x00

    _s_buf: times 128 db 0 

    _b_rt_sts:     db 0

    _w_ax:
    _b_al:    db 0
    _b_ah:    db 0

    _w_bx:
    _b_bl:    db 0
    _b_bh:    db 0

    _w_cx:
    _b_cl:    db 0
    _b_ch:    db 0

    _w_dx:
    _b_dl:    db 0
    _b_dh:    db 0

    _w_x:
    _b_xl:    db 0
    _b_xh:    db 0

    _w_y:
    _b_yl:    db 0
    _b_yh:    db 0

    _w_i:
    _b_il:    db 0
    _b_ih:    db 0

    _w_j:
    _b_jl:    db 0
    _b_jh:    db 0

    _w_k:
    _b_kl:    db 0
    _b_kh:    db 0

    _s_true:  db 'TRUE ', 13, 10, 0

    _s_false: db 'FALSE', 13, 10, 0

    _b_isTest: db 0

    section .text

section .text

;>****************************
;> ブートローダパディング
;>****************************
;times 510-($-$$) db 0
times (0x200 - 2)-($-$$) db 0

;********************************
; ブートセクタシグネチャ
;********************************
db 0x55
db 0xAA

%include "routine.asm"

;>===========================
;>  試験コード
;>===========================
;********************************
; dump_mem
;    axで指定されたアドレスからbxで指定されたサイズ分ダンプする
;    いったん撤収。最初から作り直す。何が何だかわからなくなった
;********************************
dump_mem:

    push bx
    push ax
    push si
    push dx

    mov si, ax

._loop:
    mov di, ._s_buf

    mov cx, 0x0000

    mov al, 0x30
    mov [di], al
    inc di

    mov al, 0x78
    mov [di], al
    inc di

mov ax, si
mov bx, ._s_cv_buf
mov word [bx], ax 
inc bx
inc bx
mov byte [bx], 0x00

mov ax, ._s_cv_buf
call disp_nl
call disp_word_hex
call disp_nl

jmp ._debug

    mov al, 0x20
    mov [di], al
    inc di

._debug:
mov byte [di], 0x00
mov ax, ._s_buf
call disp_str
mov ax, ._s_cv_buf
call disp_str
ret

._body_loop:
    lodsb
    or al, al
    je ._loop_end
    inc cx

    call bin_byte_hex
    mov [di], al
    inc di
    
    mov ax, cx
    and ax, 15
    jne ._skip
    
    inc di
    mov al, 0x00
    mov [di], al
    inc di
    
    mov ax, ._s_buf
    call disp_str
    mov di, ._s_buf
    jmp ._loop

._skip:

    call bin_byte_hex
    mov [di], al
    inc di

    jmp ._loop
    
._body_loop_end:
    
._loop_end:

    inc di
    mov al, 0x00
    mov [di], al
    inc di
    call disp_str
    mov di, ._s_buf

    ret

._s_buf: times 256 db 0x00
._s_cv_buf times 10 db 0x00

;********************************
; rv_mem
;    axで指定されたアドレスからbxで指定されたサイズ分逆順に並び替える
;    必要性が微妙なので放置
;********************************
rv_mem:
    push ax
    push bx

    mov [._w_size], bx

    mov si, ax

    mov cx, ax
    add cx, bx

    mov bx, ._s_buf

._loop:
    cmp cx, si
    jg ._loop_end

    mov dl, [si]
    mov [bx], dl
    inc si
    inc bx

._loop_end:

    ; mov ax, ax
    ; mov bx, bx
    mov cx, [._w_size]
    call copy_mem

    pop bx
    pop ax

    ret

._s_buf: times 256 db 0x00

._w_size: dw 0x0000


;********************************
; word_hex
;       2バイト（1ワード）のデータを表示する
;	（ビッグエンディアン表記）
; param : ax : 表示するword
; return : bx : 変換した文字列
;********************************
bin_word_hex:

    push ax
    push cx

    mov cx, ax
    mov al, ch
    call bin_byte_hex
    mov bh, al

    mov al, cl
    call disp_byte_hex
    mov bl, al

._end:

    pop cx
    pop ax

    ret

;********************************
; hex_binの確認
;********************************
exp_hex_bin:


    ret


;********************************
; hex_nibbleの確認
;********************************
exp_hex_nibble:


    ret

;********************************
; hex_str_binの確認
;********************************
exp_hex_str_bin:


    ret


;********************************
; dec_binの確認
;********************************
exp_dec_bin:


    ret


;********************************
; dec_str_binの確認
;********************************
exp_dec_str_bin:


    ret


;********************************
; 確認用
;********************************
exp_test:





    ; 終了したテスト
    ;call exp_disp_word_hex
    ;call exp_test_read_disk
    ;call exp_test_write_disk
    ;call exp_set_mem
    ;call exp_copy_mem
    ;call exp_get_mem
    ;call exp_bin_byte_ascii
    ; テスト未作成
    ;call exp_bin_nibble_hex
    ;call exp_bin_byte_hex
    ;call exp_bin_word_hex
    ;call exp_bin_strm_hex
    ;call exp_set_mem
    ;call exp_fill_mem
    ;call exp_get_mem
    ;call exp_copy_mem
    ;call exp_bin_byte_ascii
    ;call exp_bin_strm_ascii
    ;call exp_test_read_disk
    ;call exp_test_write_disk
    ;call exp_disp_word_hex

    ret

    ; 未作成
    ;call_exp_disp_nl
    ;call exp_disp_dec
    ;call exp_disp_byte_hex
    ;call exp_disp_mem
    ;call exp_call_word_hex
    ;call exp_disp_str
    ;call exp_get_str_ascii
    ;call exp_power_down
    ;call exp_dump_mem
    ;call exp_bin_word_hex
    ;call exp_div
    ;call exp_nul
    ;call ex_rv_mem


._s_buf: times 256 db 0x00

;>===========================
;> main
;>===========================

main:

    ; ビデオモードの設定
    mov ah, 0x0
    mov al, 0x3    ; 16色テキスト、80x25
    ; mov al, 0x6a  ; 800x600x4bitカラー（ビデオカードによってはサポートされない）
    int 0x10

    ; 念のため初期化
    cld

;********************************
;   確認コードの実行
;********************************
    call exp_test

    ; 処理終了
    call disp_nl
    call disp_nl
    mov ax, ._s_msg
    call disp_str
    call get_key
    call power_off

    call _hlt
    ret

._s_msg: db 'hit any key to power off', 0x0d, 0x0a, 0x00

_bye: db 'bye', 0x0d, 0x0a, 0x00

_test: db 0x33, 0x00



    times 0x4000 -($-$$) db 0
;==============================================================
; ファイル長の調整
;==============================================================
_sixth_sector:
    db 'forth gate open!', 0x0d, 0x0a, 0x00

    times 0x4200 -($-$$) db 0

_seventh_sector:
    db 'Quickly!', 0x0d, 0x0a, 0x00

    times 0x4400-($-$$) db 0

_eighth_sector:
    db 'All out!', 0x0d, 0x0a, 0x00

    times 0x5000 -($-$$) db 0
