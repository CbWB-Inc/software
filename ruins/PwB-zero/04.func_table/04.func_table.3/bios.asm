;>===========================
;>	BIOSで遊ぼっ！
;>===========================
section .data

	_c_seg          equ 0x07c0
	_c_ex_area_addr equ 0x200

section .text


boot:
    org 0x7C00

    ; set segment register
    mov ax, _c_seg
;    mov ds, ax
    mov es, ax
;    mov cs, ax
;    mov ss, ax



;    mov ah, 0x0e
    ;
    ; disk read
    ;     read to es:bx
    ;
    mov bx, _c_ex_area_addr

    mov ah, 0x02 ; Read Sectors From Drive
    mov dl, 0x80 ; Drive
    mov al, 0x20 ; Sectors To Read Count ;
    mov ch, 0x00 ; Cylinder
    mov cl, 0x02 ; Sector(starts from 1, not 0) ; set 2. becouse not need MBR
    mov dh, 0x00 ; Head

    int 0x13     ; Execute disk read

;    jmp main


start:

    mov ax, 0              ; index = 0
    call call_func_by_index
    jmp $

call_func_by_index:
    mov bx, func_table
    shl ax, 1              ; index * 2
    add bx, ax
    call word [bx]         ; 関数ポインタ呼び出し
    ret

print_hello:
    mov ah, 0x0E
    mov al, 'H'
    int 0x10
    mov al, 'i'
    int 0x10
    mov al, '!'
    int 0x10
    ret

func_table:
    dw print_hello


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




;>===========================
;>  BIOSコール 実験コード
;>===========================
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


;%include "routine.asm"

;==============================================================
; 仮バイオスの末端
;==============================================================
_padding2:
    times 0x4000-($-$$)-2 db 0


;********************************
; セクションシグネチャ
;********************************

db 0x55
db 0xAA

;==============================================================
; ファイル長の調整
;==============================================================
_padding3:
    times 0x100000-($-$$)-2 db 0

;********************************
; セクションシグネチャ
;********************************

db 0x55
db 0xAA
