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
exp_func_table:
    
    mov ax, ._c_msg3
    call disp_str
    
    
    mov al, 0x00
    call ._call_func_by_index

._exit:
    
    ret

._c_msg3: db 'func table check start', 0x0d, 0x0a, 0x00

._call_func_by_index:
    push bx
    
    push ax
    mov ax, ._c_msg4
    call disp_str
    call ._func1
    call ._func2
    mov ax, [._func_table]
    mov bx, 0x10
    call disp_mem
    mov ax, ._func1
    call disp_mem
    mov ax, ._func2
    call disp_mem
    
    pop ax
    
    ; BX = 関数テーブルアドレス
    mov bx, ._func_table
    ; 各エントリは2バイト（16bitアドレス）
    ; AX = インデックス * 2
    mov ah, 0
    mov al, 1
    shl ax, 1
    add bx, ax

    ;push ._call_func_exit

    ; 関数ポインタを取り出してジャンプ
    ;jmp word [bx]
    jmp word bx
    ;call word [bx]
    ;call 0x026B
    
    ;mov bx, [._func1]
    ;call word bx

    ;mov ax, bx
    ;mov bx, 0x10
    ;call disp_mem


._call_func_exit:

    pop bx
    
    ret

._c_msg4: db 'func table execute', 0x0d, 0x0a, 0x00



._func1:
    push ax
    mov ax, ._c_msg1
    call disp_str
    pop ax
    ret

._c_msg1: db 'Function One Called!', 0x0a, 0x0d, 0x00

._func2:
    push ax
    mov ax, ._c_msg2
    call disp_str
    pop ax
    ret

._c_msg2: db 'Function two Called!', 0x0a, 0x0d, 0x00

._func_table:
    dw ._func1
    dw ._func2



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



start:
    mov ax, 0              ; index = 0
    call call_func_by_index
    jmp $


._loop:

    call one_line_editer

    call command

    jmp ._loop


    jmp exit


._s_blank: db ' '


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
    shl cx, 4
    mov bx, _c_command
    add bx, cx

    cmp byte [bx], 0x00
    je ._exit
    call str_cmp
    cmp cl, 0x00
    jne  ._loop

    ; cls
    mov cx, dx
    cmp cx, 0x00
    jne ._next
    call cls
    ret

._next:    

    ; exit
    mov cx, dx
    cmp cx, 0x01
    jne ._next2
    call exit
    ret

._next2:    

    ; exec
    mov cx, dx
    cmp cx, 0x02
    jne ._next3
    call exp_func_table
    ret

._next3:    

    ; help
    mov cx, dx
    cmp cx, 0x03
    jne ._next4
    call _cmd_help
    ret

._next4:

._exit:

    mov bx, _s_one_line_buf
    cmp bl, 0x00
    je ._exit2
    mov ax, bx
    call disp_str

._exit2
    call disp_nl

    ret
    

_s_one_line_buf: times 128 db 0
_s_cmp_buf: times 128 db 0
_b_x: db 0x00
_b_y: db 0x00
_b_len: db 0x00
_b_pos: db 0x00

_c_command:
_c_cls:  db 'cls',  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
_c_exit: db 'exit', 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
_c_exec: db 'exec', 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
_c_help: db 'help', 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
_c_end : db         0x00, 0x00, 

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
._c_exec: db '  exec', 0x0d, 0x0a
._c_exit: db '  exit', 0x0d, 0x0a
._c_help: db '  help', 0x0d, 0x0a
._c_nl2:  db           0x0d, 0x0a, 0x00


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
    ;call exp_get_vbe_info
    ;jmp _end


    call _hlt
    ret

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


%include "routine.asm"

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
