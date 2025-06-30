;>===========================
;>	BIOSで遊ぼっ！
;>===========================

section .data

	_c_seg          equ 0x07c0
	_c_ex_area_addr equ 0x200

	_c_true         equ '1'
	_c_false        equ '0'

	_b_true         equ 1
	_b_false        equ 0


section .text

boot:
    ; set segment register
    mov ax, _c_seg
    mov ds, ax

    mov ah, 0x0e
    ;
    ; disk read
    ;     read to es:bx
    ;
    mov ax, _c_seg
    mov es, ax
    mov bx, _c_ex_area_addr

    mov ah, 0x02 ; Read Sectors From Drive
    mov dl, 0x80 ; Drive
    mov al, 0x20 ; Sectors To Read Count ;
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


_m_isTest:       db 0


;>****************************
;> ブートローダパディング
;>****************************


times 510-($-$$) db 0

;********************************
; ブートセクタシグネチャ
;********************************

db 0x55
db 0xAA


section .text

;>===========================
;>  実験コード
;>===========================
;>===========================
;> main
;>===========================

main:
    ; set segment register
    mov ax, _c_seg
    mov ds, ax

    ; ビデオモードの設定
    mov ah, 0x0
    mov al, 0x3    ; 16色テキスト、80x25
    int 0x10

    ; 念のため初期化
    cld

    ; 初期カーソル位置 (x=40, y=12)
    mov dh, 12   ; Y座標
    mov dl, 40   ; X座標
    call set_cursor

main_loop:
    ; キー入力待ち
    mov ah, 0x00
    int 0x16  ; キー入力を待つ

    ; 矢印キー判定
    cmp ah, 0x48  ; ↑キー
    je move_up
    cmp ah, 0x50  ; ↓キー
    je move_down
    cmp ah, 0x4B  ; ←キー
    je move_left
    cmp ah, 0x4D  ; →キー
    je move_right

    jmp main_loop  ; 他のキーならループ

move_up:
    cmp dh, 0   ; 画面上端か？
    je main_loop
    dec dh      ; Y座標を減少
    jmp update_cursor

move_down:
    cmp dh, 24  ; 画面下端か？
    je main_loop
    inc dh      ; Y座標を増加
    jmp update_cursor

move_left:
    cmp dl, 0   ; 画面左端か？
    je main_loop
    dec dl      ; X座標を減少
    jmp update_cursor

move_right:
    cmp dl, 79  ; 画面右端か？
    je main_loop
    inc dl      ; X座標を増加
    jmp update_cursor

update_cursor:
    call set_cursor
    jmp main_loop

set_cursor:
    ; カーソル位置を設定
    mov ah, 0x02
    mov bh, 0x00  ; ページ0
    int 0x10
    ret

._exit:
    ; 処理終了
    call disp_nl
    call disp_nl
    mov ax, ._s_msg
    call disp_str
    call get_key
    call power_off

    ret
._s_msg: db 'hit any key to power off', 0x0d, 0x0a, 0x00

_debug:
    push ax
    mov ax, ._s_debug
    call disp_str
    pop ax

    ret

._s_debug db 'OK!', 0x00

;********************************
;   0x00    Read Keyboard Inputの実験
;********************************
    ;call exp_read_key

;********************************
;   0x01    Return Keyboard Statusの実験
;********************************
    ;call exp_get_kb_sts

;********************************
;   0x02    Return Shift Flag Statusの実験
;********************************
    ;call exp_get_kb_cond

;********************************
;   0x03    Set Typematic Rateの実験
;********************************
    ;call exp_set_kb_tr

;********************************
;   0x10    Enhanced Read Keyboardの実験
;********************************
    ;call exp_enh_read_key

;********************************
;   0x11    nhanced Read Keyboard StatuSの実験
;********************************
    ;call exp_enh_get_kb_sts

;********************************
;   0x12    Enhanced Read Keyboard Flagsの実験
;********************************
    ;call exp_enh_get_kb_cond

;********************************
;   0x03    Set Typematic Rateの実験
;********************************
    ;call exp_enh_get_kb_cond

;********************************
;   0xF0    Set CPU Speedの実験
;********************************
    ;call exp_set_cpu_speed

;********************************
;   0xF1    Get CPU Speedの実験
;********************************
    ;call exp_get_cpu_speed


;********************************
;   0xF1    Get CPU Speedの実験
;********************************
    call exp_get_vbe_info
    ;jmp _end


    call _hlt
    ret

;>===========================
;>  BIOSコール 実験コード
;>===========================
;********************************
; VBE情報を取得する
;********************************
exp_get_vbe_info:

    mov ax, _c_seg
    mov ds, ax
    mov ax, 0x0400
    mov di, ax
    call get_vbe_info
    
    mov ax, 0x0400
    mov bx, 16
    call disp_mem

    call disp_nl
    call disp_nl

    mov ax, 0x0400
    mov [_w_x], ax
    mov word [_w_i], 0x0020
    mov si, ax
_loop1:
    lodsb
    cmp al, 0x20
    jge _over
    mov al, 0x2e
    mov ah, 0x0e
    int 0x10
    jmp _loop_end
_over:
    cmp ah, 0x7f
    jg _more_over
    mov ah, 0x0e
    int 0x10
    jmp _loop_end
_more_over:
    mov al, 0x2e
    mov ah, 0x0e
    int 0x10
_loop_end:
    inc si
    mov ax, [_w_i]
    dec ax
    mov [_w_i], ax
    cmp ax, 0x00
    je _loop1 

    call disp_nl
    mov ax, ._msg
    call disp_str

    ret
._msg db 0x0d, 0x0a, 0x00



._b_attr: db 0x00
._b_chr: db 0x00
._b_col: db 0x00
._b_row:  db 0x00



;********************************
; get_cursor_pos
; カーソル位置取得
; paramater : なし
; return    : ah : 現在の行（0オリジン）
;           : al : 現在の列（0オリジン）
;********************************
get_cursor_pos:

    push ax
    push bx
    push cx
    push dx

    mov ah, 0x03
    mov al, 0x00
    mov bh, 0x00    ; 当面0ページ固定で様子を見る
    mov bl, 0x00    ; 当面0ページ固定で様子を見る
    int 0x10

    mov ax, dx
    mov bx, cx

    pop dx
    pop cx
    pop bx
    pop ax

    ret


;********************************
; set_cursor_pos
; カーソル位置設定
; parameter : ah : 設定する行（0オリジン）
;           : al : 設定する列（0オリジン）
; return : 事実上なし
;********************************
set_cursor_pos:

    push ax
    push bx

    mov dx, ax
    mov ah, 0x02
    mov al, 0x00
    mov bh, 0x00    ; 当面０ページで固定
    mov bl, 0x00    ; 当面０ページで固定
    int 0x10

    pop bx
    pop ax

    ret

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

    _s_success: db 'SUCCESS!! (^^)b ', 13, 10, 0
    _s_fail:    db 'fail (T_T) ', 13, 10, 0


_test: db 0x33, 0x00


%include "routine.asm"

