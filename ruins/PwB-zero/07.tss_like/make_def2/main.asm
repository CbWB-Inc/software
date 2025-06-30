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
    times 0x2600 -($-$$)-2 db 0
    

;********************************
; セクションシグネチャ
;********************************

db 0x55
db 0xAA

main2:
;>===========================
;> 色々確認
;>===========================

    jmp ._skip24
    
    mov ax, __get_key
    mov bx, get_key
    call ._make_def

    mov ax, __get_kb_sts
    mov bx, get_kb_sts
    call ._make_def

    mov ax, __get_kb_cond
    mov bx, get_kb_cond
    call ._make_def

    mov ax, __set_kb_tr
    mov bx, set_kb_tr
    call ._make_def

    mov ax, __set_kb_buf
    mov bx, set_kb_buf
    call ._make_def

    mov ax, __enh_get_key
    mov bx, enh_get_key
    call ._make_def

    mov ax, __enh_get_kb_sts
    mov bx, enh_get_kb_sts
    call ._make_def

    mov ax, __enh_get_kb_cond
    mov bx, enh_get_kb_cond
    call ._make_def

    mov ax, __read_disk
    mov bx, read_disk
    call ._make_def

    mov ax, __write_disk
    mov bx, write_disk
    call ._make_def

    mov ax, __get_cpu_speed
    mov bx, get_cpu_speed
    call ._make_def

    mov ax, __get_vbe_info
    mov bx, get_vbe_info
    call ._make_def

    mov ax, __get_cursor_pos
    mov bx, get_cursor_pos
    call ._make_def

    mov ax, __set_cursor_pos
    mov bx, set_cursor_pos
    call ._make_def

    mov ax, __bin_nibble_hex
    mov bx, bin_nibble_hex
    call ._make_def

    mov ax, __bin_byte_hex
    mov bx, bin_byte_hex
    call ._make_def

    mov ax, __bin_strm_hex
    mov bx, bin_strm_hex
    call ._make_def

    mov ax, __fill_mem
    mov bx, fill_mem
    call ._make_def

    mov ax, __copy_mem
    mov bx, copy_mem
    call ._make_def

    mov ax, __cmp_mem
    mov bx, cmp_mem
    call ._make_def

    mov ax, __get_mem
    mov bx, get_mem
    call ._make_def

    mov ax, __set_mem
    mov bx, set_mem
    call ._make_def

    mov ax, __str_len
    mov bx, str_len
    call ._make_def

    mov ax, __str_cmp
    mov bx, str_cmp
    call ._make_def

._skip24:

;    call _hlt

    mov ax, __main
    mov bx, main
    call ._make_def

    mov ax, __main2
    mov bx, main2
    call ._make_def

    mov ax, __ucase
    mov bx, ucase
    call ._make_def

    mov ax, __lcase
    mov bx, lcase
    call ._make_def

    mov ax, __hex_bin
    mov bx, hex_bin
    call ._make_def

    mov ax, __hex_nibble
    mov bx, hex_nibble
    call ._make_def

    mov ax, __hex_str_bin
    mov bx, hex_str_bin
    call ._make_def

    mov ax, __dec_bin
    mov bx, dec_bin
    call ._make_def

    mov ax, __dec_str_bin
    mov bx, dec_str_bin
    call ._make_def

    mov ax, __cls
    mov bx, cls
    call ._make_def

    mov ax, __debug_print
    mov bx, debug_print
    call ._make_def

    mov ax, __disp_nl
    mov bx, disp_nl
    call ._make_def

    mov ax, __disp_dec
    mov bx, disp_dec
    call ._make_def

    mov ax, __disp_byte_hex
    mov bx, disp_byte_hex
    call ._make_def

    mov ax, __disp_mem
    mov bx, disp_mem
    call ._make_def

    mov ax, __disp_word_hex
    mov bx, disp_word_hex
    call ._make_def

    mov ax, __disp_str
    mov bx, disp_str
    call ._make_def

    mov ax, __bin_strm_ascii
    mov bx, bin_strm_ascii
    call ._make_def

    mov ax, __bin_byte_ascii
    mov bx, bin_byte_ascii
    call ._make_def

    mov ax, __one_line_editer
    mov bx, one_line_editer
    call ._make_def

    mov ax, __get_str_ascii
    mov bx, get_str_ascii
    call ._make_def

    mov ax, __power_off
    mov bx, power_off
    call ._make_def

    mov ax, __print
    mov bx, print
    call ._make_def

    mov ax, __exit
    mov bx, exit
    call ._make_def

    mov ax, __hlt
    mov bx, _hlt
    call ._make_def

;._skip48:

._loop:
    call one_line_editer
    
    call command

    jmp ._loop

    jmp _hlt

._make_def:
    call disp_str
    mov ax, bx
    call disp_word_hex
    call disp_nl
    
    ret

__main db 'main equ 0x', 0x00
__main2 db 'main2 equ 0x', 0x00


__get_key db 'get_key equ 0x', 0x00
__get_kb_sts db 'get_kb_sts equ 0x', 0x00
__get_kb_cond db 'get_kb_cond equ 0x', 0x00
__set_kb_tr db 'set_kb_tr equ 0x', 0x00
__set_kb_buf db 'set_kb_buf equ 0x', 0x00
__enh_get_key db 'enh_get_key equ 0x', 0x00
__enh_get_kb_sts db 'enh_get_kb_sts equ 0x', 0x00
__enh_get_kb_cond db 'enh_get_kb_cond equ 0x', 0x00
__read_disk db 'read_disk equ 0x', 0x00
__write_disk db 'write_disk equ 0x', 0x00
__get_cpu_speed db 'get_cpu_speed equ 0x', 0x00
__get_vbe_info db 'get_vbe_info equ 0x', 0x00
__get_cursor_pos db 'get_cursor_pos equ 0x', 0x00
__set_cursor_pos db 'set_cursor_pos equ 0x', 0x00
__bin_nibble_hex db 'bin_nibble_hex equ 0x', 0x00
__bin_byte_hex db 'bin_byte_hex equ 0x', 0x00
__bin_strm_hex db 'bin_strm_hex equ 0x', 0x00
__fill_mem db 'fill_mem equ 0x', 0x00
__copy_mem db 'copy_mem equ 0x', 0x00
__cmp_mem db 'cmp_mem equ 0x', 0x00
__get_mem db 'get_mem equ 0x', 0x00
__set_mem db 'set_mem equ 0x', 0x00
__str_len db 'str_len equ 0x', 0x00
__str_cmp db 'str_cmp equ 0x', 0x00
__ucase db 'ucase equ 0x', 0x00
__lcase db 'lcase equ 0x', 0x00
__hex_bin db 'hex_bin equ 0x', 0x00
__hex_nibble db 'hex_nibble equ 0x', 0x00
__hex_str_bin db 'hex_str_bin equ 0x', 0x00
__dec_bin db 'dec_bin equ 0x', 0x00
__dec_str_bin db 'dec_str_bin equ 0x', 0x00
__cls db 'cls equ 0x', 0x00
__debug_print db 'debug_print equ 0x', 0x00
__disp_nl db 'disp_nl equ 0x', 0x00
__disp_dec db 'disp_dec equ 0x', 0x00
__disp_byte_hex db 'disp_byte_hex equ 0x', 0x00
__disp_mem db 'disp_mem equ 0x', 0x00
__disp_word_hex db 'disp_word_hex equ 0x', 0x00
__disp_str db 'disp_str equ 0x', 0x00
__bin_strm_ascii db 'bin_strm_ascii equ 0x', 0x00
__bin_byte_ascii db 'bin_byte_ascii equ 0x', 0x00
__one_line_editer db 'one_line_editer equ 0x', 0x00
__get_str_ascii db 'get_str_ascii equ 0x', 0x00
__power_off db 'power_off equ 0x', 0x00
__print db 'print equ 0x', 0x00
__exit db 'exit equ 0x', 0x00
__hlt db '_hlt equ 0x', 0x00




exp_read_exec1:
    
    mov ax, 0x3000
    call read_exec
    
    ret

exp_read_exec2:

    mov ax, 0x3800
    call read_exec
    
    ret

exp_read_exec3:

    mov ax, 0x3400
    call read_exec
    
    ret

;********************************
; read_exec
;       実行する
; param : ax : 読み込むアドレス
; return: 
;********************************
read_exec:

    mov bx, ax
    mov [_w_bx], ax
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
    mov cl, 0x19 ; Sector(starts from 1, not 0) ; set 2. becouse not need MBR
    mov dh, 0x00 ; Head

    int 0x13     ; Execute disk read

    ;jmp 0x07c0:0x3200
    
    mov ax, _c_seg
    mov es, ax
    mov bx, [_w_bx]
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
    shl cx, 4
    mov bx, _c_command
    add bx, cx

    cmp byte [bx], 0x00
    je ._exit
    call str_cmp
    cmp cl, 0x00
    jne  ._loop


    mov bx, dx
    cmp bx, 0x05
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
    

_c_command:
_c_cls:  db 'cls',  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
_c_exit: db 'exit', 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
_c_exec1:db '3000', 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
_c_help: db 'help', 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
_c_exec2:db '3800', 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
_c_exec3:db '3400', 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
_c_end : db         0x00, 0x00, 

_c_cmd_tbl:
    dw cls
    dw exit
    dw exp_read_exec1
    dw _cmd_help
    dw exp_read_exec2
    dw exp_read_exec3

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
._c_help: db '  help', 0x0d, 0x0a
._c_nl2:  db           0x0d, 0x0a, 0x00


no_ope:
    push si
    ret


    call _hlt
    ret


;==============================================================
; パディング
;==============================================================
    times 0x2e00 -($-$$)-2 db 0

;********************************
; セクションシグネチャ
;********************************

db 0x55
db 0xAA
