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
    mov es, ax

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
exp_one_line_editer:

    mov ah, 0   
    mov [_b_x], ah
    mov [_b_y], ah

._loop:

    call one_line_editer

    call cmd_exe

    jmp ._loop


._exit:
    
    ret

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


    call exp_one_line_editer


    jmp exit


._s_blank: db ' '




;********************************
; cmd_exe
;       実行する
; param : ax : 入力された文字列を格納するバッファのアドレス
;              オーバーフロー注意
; return: 
;********************************
cmd_exe:

    ;
    ;   入力値をバッファに退避
    ;
    push di
    push si
    mov si, ax
    mov di, _s_cmp_buf

._cpy_loop:
    lodsb
    or al, al
    jz ._cpy_skip
    mov [di], al
    inc di
    jmp ._cpy_loop

._cpy_skip:
    pop si
    pop di

    ;
    ; 小文字に変換
    ;
    mov ax, _s_cmp_buf
    call lcase
    
    ;
    ; clsの場合
    ;
._cmd_cls:
    mov ax, _s_cmp_buf
    mov bx, _c_cls
    call str_cmp
    cmp cl, 0x00
    jne  ._cmd_exit
    call cls
    ;mov bx, _s_one_line_buf
    mov si, ax
    mov byte [si], 0x00
    jmp ._exit

    ;
    ; exitの場合
    ;
._cmd_exit:
    mov bx, _c_exit
    call str_cmp
    cmp cl, 0x00
    jne  ._cmd_none
    call exit
    jmp ._exit

._cmd_none:
    call str_len
    or bx, 0x00
    jz ._skip
    call disp_str
._skip:
    call disp_nl



._exit:


    ret
    

_s_one_line_buf: times 128 db 0
_s_cmp_buf: times 128 db 0
_b_x: db 0x00
_b_y: db 0x00
_b_len: db 0x00
_b_pos: db 0x00
_c_cls: db 'cls', 0x00
_c_exit: db 'exit', 0x00


;********************************
; clear_line
;       cursor行をクリアする
; param : 
; return: 
;********************************
clear_line:
    push ax
    push bx
    
    mov ah, 0x0E
    mov bl, 79
    mov al, ' '
._clear_start:
    int 0x10
    dec bl
    or bl, bl
    jnz ._clear_start
    
    mov al, 0x0d
    int 0x10

    pop bx
    pop ax
    
    ret


exit:
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

