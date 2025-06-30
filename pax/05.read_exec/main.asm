;>===========================
;>  実験コード
;>===========================

;>===========================
;> main
;>===========================

main:
    org 0x0200

    ; set segment register
;    mov ax, _c_seg
;    mov ds, ax

    ; ビデオモードの設定
    mov ah, 0x0
    mov al, 0x3    ; 16色テキスト、80x25
    int 0x10

    ; 念のため初期化
    cld

    jmp main2

;==============================================================
; mainの末端
;==============================================================
    times 0x0200-($-$$)-2 db 0
    

;********************************
; セクションシグネチャ
;********************************

db 0x55
db 0xAA

;>===========================
;> サブルーチンの実体
;>===========================

%include "routine.asm"

;==============================================================
; サブルーチンの末端
;==============================================================
    times 0x2200 -($-$$)-2 db 0
    

;********************************
; セクションシグネチャ
;********************************

db 0x55
db 0xAA


;********************************
; main2
;********************************

main2:

._loop:
    call one_line_editer
    
    call command

    jmp ._loop

    jmp _hlt

exp_read_exec1:
    
    mov ax, 0x3000
    mov bl, 0x19
    call read_exec
    
    ret

exp_read_exec2:

    mov ax, 0x3800
    mov bl, 0x19
    call read_exec
    
    ret

exp_read_exec3:

    mov ax, 0x3400
    mov bl, 0x19
    call read_exec
    
    ret

exp_read_exec4:

    mov ax, 0x3000
    mov bl, 0x1d
    call read_exec
    
    ret

exp_read_exec5:

    mov ax, 0x3400
    mov bl, 0x1d
    call read_exec
    
    ret
;>****************************
;> hlt
;>****************************
_hlt:
    hlt
    jmp _hlt

;********************************
; read_exec
;       実行する
; param : ax : 読み込むアドレス
; return: 
;********************************
read_exec:

    mov [_w_ax], ax
    mov [_b_bl], bl
    mov bx, ax
    ;
    ; disk read
    ;     read to es:bx
    ;
    mov ax, _c_seg
;    sub ax, 0x200
    mov es, ax

    mov ah, 0x02 ; Read Sectors From Drive
    mov dl, 0x80 ; Drive
    mov al, 0x02 ; Sectors To Read Count ;
    mov ch, 0x00 ; Cylinder
    mov cl, [_b_bl] ; Sector(starts from 1, not 0) ; set 2. becouse not need MBR
    mov dh, 0x00 ; Head

    int 0x13     ; Execute disk read

    ;jmp 0x07c0:0x3200
    
    mov ax, _c_seg
    mov es, ax
    mov bx, [_w_ax]
    push word es     ; セグメント
    push word bx     ; オフセット
    retf             ; far return → jmp es:bx と同じ意味

    
    ret

._test_reg: dw 0x07c0

;********************************
; command
;       実行する
; param : ax : 入力された文字列を格納するバッファのアドレス
;              オーバーフロー注意
;              暫定ルーチン。テスト用かな。
; return: 
;********************************
command:

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


    mov dx, -1

._loop:
    inc dx
    mov ax, _s_cmp_buf
    mov cx, dx
    shl cx, 3
    mov bx, _c_command
    add bx, cx

    cmp byte [bx], 0x00
    je ._exit
    call str_cmp
    cmp cx, 0x00
    jne  ._loop

    mov bx, dx
    cmp bx, 0x07
    jg ._exit


    mov bx, _c_cmd_tbl
    mov ax, dx
    mov ah, 0x00
    shl ax, 1
    add bx, ax
    call word [bx]
    
    jmp ._exit2


._exit:

    mov bx, _s_one_line_buf
    cmp bh, 0x00
    je ._exit2
    mov ax, bx
    call disp_str
    call disp_nl

._exit2:

    ret
    

_s_one_line_buf: times 128 db 0
_s_cmp_buf: times 128 db 0
_b_x: db 0x00
_b_y: db 0x00
_b_len: db 0x00
_b_pos: db 0x00

_c_command:
_c_cls:  db 'cls',  0x00, 0x00, 0x00, 0x00, 0x00
_c_exit: db 'exit', 0x00, 0x00, 0x00, 0x00
_c_exec1:db '3000', 0x00, 0x00, 0x00, 0x00
_c_help: db 'help', 0x00, 0x00, 0x00, 0x00
_c_exec2:db '3800', 0x00, 0x00, 0x00, 0x00
_c_exec3:db '3400', 0x00, 0x00, 0x00, 0x00
_c_exec4:db '3002', 0x00, 0x00, 0x00, 0x00
_c_exec5:db '3402', 0x00, 0x00, 0x00, 0x00
;_c_end : db         0x00, 0x00, 

_c_cmd_tbl:
    dw cls
    dw exit
    dw exp_read_exec1
    dw _cmd_help
    dw exp_read_exec2
    dw exp_read_exec3
    dw exp_read_exec4
    dw exp_read_exec5
    dw 0x0000

;********************************
; _cmd_help
;       実行する
; param : ax : ヘルプ表示
;              暫定ルーチン。動作確認用とかかしら。
; return: 
;********************************
_cmd_help:

    push ax
    push si
    

    mov ah, 0x0e
    mov si, ._c_msg
    
._loop:
    lodsb
    or al, al
    jz ._exit
    int 0x10
    jmp ._loop
    
    
._exit:
    pop si
    pop ax

    ret

._c_msg:
._c_nl:   db           0x0d, 0x0a
._c_cls:  db '  cls',  0x0d, 0x0a
._c_3000: db '  3000', 0x0d, 0x0a
._c_3400: db '  3400', 0x0d, 0x0a
._c_3800: db '  3800', 0x0d, 0x0a
._c_S000: db '  3002', 0x0d, 0x0a
._c_S400: db '  3402', 0x0d, 0x0a
._c_help: db '  help', 0x0d, 0x0a
._c_exit: db '  exit', 0x0d, 0x0a
._c_nl2:  db           0x0d, 0x0a, 0x00


no_ope:
    push si
    ret


    call _hlt
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


;==============================================================
; mainの末端
;==============================================================
_padding2:
    times 0x2E00-($-$$)-2 db 0
    

;********************************
; セクションシグネチャ
;********************************

db 0x55
db 0xAA

