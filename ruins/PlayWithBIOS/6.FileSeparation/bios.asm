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

section .text

%include "routine.asm"

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

._msg: db 'end', 0x0d, 0x0a, 0x00 


;********************************
; ビデオモード 
;********************************
exp_set_vmode:

    ;mov al, 0x00     ; テキスト（モノクロ）    16色 40x25 320x200
    ;mov al, 0x01     ; テキスト（カラー）      16色 40x25 320x200
    ;mov al, 0x02     ; テキスト（モノクロ）    16色 80x25 640x200
    mov al, 0x03     ; テキスト（カラー）      16色 80x25 640x200
    ;mov al, 0x04     ; グラフィック（カラー）   4色 40x25 320x200
    ;mov al, 0x05     ; グラフィック（モノクロ） 4色 40x25 320x200
    ;mov al, 0x06     ; グラフィック（モノクロ） 2色 80x25 640x200
    ;mov al, 0x07     ; グラフィック（モノクロ）      80x25 720x350

    ;mov al, 0x0d     ; グラフィック  16色 40x25 320x200
    ;mov al, 0x0e     ; グラフィック  16色 80x25 640x200
    ;mov al, 0x0f     ; グラフィック      80x25 640x350
    ;mov al, 0x10     ; グラフィック  16色 80x25 640x350
    ;mov al, 0x11     ; グラフィック   2色 80x30 640x480
    ;mov al, 0x12     ; グラフィック  16色 80x30 640x480
    ;mov al, 0x13     ; グラフィック 256色 40x20 320x200

    ;mov al, 0x6a      ; 800x600x4bitカラー（ビデオカードによってはサポートされない）
    ;mov al, 0x6b      ; 800x600x4bitカラー（ビデオカードによってはサポートされない）

    int 0x10

;call get_cursor_pos
;call disp_word_hex


    mov bl, 0x0a
    mov ax, ._s_msg
    call disp_str_g

ret

    call get_cursor_pos
    mov dx, ax

    mov ah, 0x09
    mov al, 0x41
    mov bh, 0x00
    mov bl, 0x0a
    mov cx, 0x01
    int 0x10

    ;inc ah 
    mov ah, 0x00
    mov al, 0x01
    call set_cursor_pos

    mov al, 0x42
    mov ah, 0x09
    mov al, 0x42
    mov bh, 0x00
    mov bl, 0x0a
    mov cx, 0x01
    int 0x10

    ;int 0x10

    ret

._s_msg: db 'set video mode', 0x0d, 0x0a, 0x00


chg_disp_color:
    
    mov al, al

    push ax
    push bx
    push cx

    mov ah, 0x09
    mov al, 0x00
    mov bh, 0x00
    mov bl, 0x0a
    mov cx, 0x01
    int 0x10

    pop cx
    pop bx
    pop ax

    ret


;********************************
; disp_str_g
; 0ターミネートされた文字列を表示する
; parameter : ax : 文字列のアドレス
; return    : なし
;********************************
disp_str_g:

    push ax
    push bx
    push cx
    push dx
    push si

    mov si, ax
    mov [._b_attr], bl

    call get_cursor_pos
    mov [._b_row], ah
    mov [._b_col], al

    ;mov bl, bl

._loop:
    lodsb
    or al, al
    jz ._loop_end

    mov [._b_chr], al
    mov ah, [._b_row]
    mov al, [._b_col]
    call set_cursor_pos

    mov al, [._b_chr]
    cmp al, 0x0a
    jne ._skip1
    mov bl, 0x00
    mov [._b_chr], bl
    mov bl, [._b_row]
    inc bl
    mov [._b_row], bl

    mov ah, 0x09
    mov al, [._b_chr]
    mov bl, [._b_attr]
    mov bh, 0x00
    mov dh, [._b_row]
    mov dl, [._b_col]
    jmp ._loop

._skip1:

    mov al, [._b_chr]
    cmp al, 0x0d
    jne ._skip2
    mov bl, 0x00
    mov [._b_chr], bl
    mov [._b_col], bl

    mov ah, 0x09
    mov al, [._b_chr]
    mov bl, [._b_attr]
    mov bh, 0x00
    mov dh, [._b_row]
    mov dl, [._b_col]
    jmp ._loop

._skip2:
    mov ah, 0x09
    mov al, [._b_chr]
    mov bl, [._b_attr]
    mov bh, 0x00
    mov dh, [._b_row]
    mov dl, [._b_col]
    int 0x10

    mov bl, [._b_col]
    inc bl
    mov [._b_col], bl
    jmp ._loop

._loop_end:
    pop si
    pop dx
    pop cx
    pop bx
    pop ax

    ret

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

;********************************
; 確認用
;********************************
exp_test:

    call exp_set_vmode




    ;call exp_bin_strm_hex

    ret


    ; 終了したテスト
    ;call exp_disp_word_hex
    ;call exp_test_read_disk
    ;call exp_test_write_disk
    ;call exp_set_mem
    ;call exp_copy_mem
    ;call exp_get_mem
    ;call exp_bin_byte_ascii
    ;call exp_bin_nibble_hex
    ;call exp_bin_byte_hex
    ; テスト未作成
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
    ; set segment register
    mov ax, _c_seg
    mov ds, ax

    ; ビデオモードの設定
    mov ah, 0x0
    mov al, 0x3    ; 16色テキスト、80x25
    ; mov al, 0x6a  ; 800x600x4bitカラー（ビデオカードによってはサポートされない）
    int 0x10

    ; 念のため初期化
    cld

    ; テストの実行
    call exp_test

    ; 処理終了
    call disp_nl
    call disp_nl
    mov ax, ._s_msg
    call disp_str
    call get_key
    call power_off

    ret

._s_msg: db 'hit any key to power off', 0x0d, 0x0a, 0x00

;********************************
;   暫定実行コード
;********************************
;    call exp_test
;
;    ret

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


_test: db 0x33, 0x00

;==============================================================
; ファイル長の調整
;==============================================================
_padding:
    times 0x100000-($-$$) db 0

