;org 0x0000
bits 16

;----------------------------------
; スタート
;----------------------------------
global _start

_start:

section .text
setup:
    call set_own_seg
    
start:

    call task_body
    sti
    hlt
    jmp start

;----------------------------------
; 処理本体（単純な表示など）
;----------------------------------
task_body:
    
    cli
    call set_own_seg
    
    mov ah, 11
    mov al, 10
    mov bx, ._s_msg
    call disp_strd

    call get_tick
    mov bx, ax
    mov ah, 11
    mov al, 13
    call disp_word_hexd
    
    mov ah, 11
    mov al, 25
    mov bh, 7
    mov bl, ':'
    call putcd
    
    call get_key
    jz .skip
    mov cx, ax
    mov ah, 11
    mov al, 26
    mov bh, 7
    mov bl, cl
    call putcd
    mov [._w_chr], cx
    mov al, 27
    mov bl, ':'
    call putcd
    mov ah, 11
    mov al, 28
    mov bx, cx
    call disp_word_hexd
.skip:

    ; メッセージ関連処理
    mov bx, 0x0000
    mov dx, 0x0000
    call recv_message
    jz ._msg_not_me
    mov cx, ax
    mov dx, bx
    mov ah, 11
    mov al, 18
    mov bh, 0x07
    mov bl, '('
    call putcd
    
    mov ah, 11
    mov al, 19
    mov bh, 0x07
    mov bl, ch
    add bl, '0'
    call putcd
    
    mov ah, 11
    mov al, 20
    mov bh, 0x07
    mov bl, ')'
    call putcd
    
    mov ah, 11
    mov al, 21
    mov bx, dx
    call disp_word_hexd

._msg_end:
._msg_not_me:

    mov bx, [._w_chr]
    and bh, 0xfe
    call line_edit
    mov bx, 0x0000
    mov [._w_chr], bx


    ; heartbeatの更新
    
    mov ax, ctx_p_task1_id
    call set_ctx_heartbeat

    sti

    ret

._s_msg db 'p1:', 0x00
._w_chr dw 0

;----------------------------------
; 共通ルーチンなど（必要に応じて）
;----------------------------------
line_edit:

    cmp bl, 0x00
    jne ._not_null
    ret
._not_null:
    cmp bl, 0x0d            ; CRの場合
    jne ._not_CR

    call get_cursor_pos     ; 1段落とし
    mov al, 79
    call next_pos
    call set_cursor_pos
    mov bx, _line_buf      ; バッファの表示
    call disp_strd
    mov ax, _line_buf
    mov si, ax
    cmp byte [si], 0x00     ; 空改行の場合なにもしない
    je .skip

    call exec_cmd

    call get_cursor_pos
    mov al, 79
    call next_pos
    call set_cursor_pos
.skip:
    mov word [._line_pos], 0
    mov ax, _line_buf
    mov bx, 128
    call mem_clear
    jmp ._exit

._not_CR:                       ; 普通の文字列
    call get_cursor_pos
    mov [._b_x], ah
    mov [._b_y], al
    mov bh, 0x07
    call putcd
    mov cx, bx
    mov si, _line_buf
    mov bx, [._line_pos]
    mov [si + bx], cl
    inc bx
    mov [._line_pos], bx
    call next_pos
    call set_cursor_pos

;    mov bx, _line_buf
;    call disp_strd
._exit:

    
    ret

._b_x db 0
._b_y db 0
._line_pos dw 0
_line_buf times 128 db 0


exec_cmd:
    push ax
    push bx
    push cx

    mov [._ax], ax
    call parse_cmd

    mov ax, _s_parse_buf1
    mov bx, ._s_help
    call str_cmp
    cmp cl, 0x00
    je ._cmd_help
    
    mov ax, _s_parse_buf1
    mov bx, ._s_locate
    call str_cmp
    cmp cl, 0x00
    je ._cmd_locate
    
    mov ax, _s_parse_buf1
    mov bx, ._s_cls
    call str_cmp
    cmp cl, 0x00
    je ._cmd_cls
    
    mov ax, _s_parse_buf1
    mov bx, ._s_mem
    call str_cmp
    cmp cl, 0x00
    je ._cmd_mem
    
    jmp ._not_hit

._cmd_help:
    call disp_help
    jmp ._skip

._cmd_locate:
    ;mov ax, [._ax]
    call exec_locate
    jmp ._skip

._cmd_cls:
    call cls
    mov ah, 17
    mov al, 0
    call set_cursor_pos
    jmp ._skip

._cmd_mem:
    call exec_mem
    jmp ._skip

._not_hit:
    mov ax, [._ax]
    call get_cursor_pos
    inc ah
    mov bx, ._s_uk
    call disp_strd
    call set_cursor_pos

._skip:
    pop cx
    pop bx
    pop ax
    
    ret

._ax dw 0
._b_pos db 0
._s_sep db ' ', 0x00
._s_help db 'help', 0x00
._s_locate db 'locate', 0x00
._s_cls db 'cls', 0x00
._s_mem db 'mem', 0x00
._s_uk db '    unknown command', 0x00
._s_cmd times 128 db 0

atoi:
    sub al, 0x30
    ret
exec_locate:


    mov si, _s_parse_buf2
    mov bx, 10
    mov ax, 0
._loop1:
    cmp byte [si], 0x00
    je ._exit_loop1
    mul bx
    mov cx, ax
    mov al, [si]
    call atoi
    mov ah, 0x00
    mov ah, 0
    add cx, ax
    mov ax, cx
    inc si
    jmp ._loop1
._exit_loop1:
    mov [._x], ax

    mov si, _s_parse_buf3
    mov bx, 10
    mov ax, 0
._loop2:
    cmp byte [si], 0x00
    je ._exit_loop2
    mul bx
    mov cx, ax
    mov al, [si]
    call atoi
    mov ah, 0
    add cx, ax
    mov ax, cx
    inc si
    jmp ._loop2
._exit_loop2:
    mov [._y], ax

    mov ah, [._x]
    mov al, [._y]
    call set_cursor_pos
    
    
    ret

._ax dw 0
._x db 0
._y db 0

atoh:
    cmp al, 0x3a
    jb ._num
    cmp al, 0x60
    ja ._lalpha

._ualpha:
    sub al, 0x37
    jmp ._exit
._lalpha:
    sub al, 0x57
    jmp ._exit
._num:
    sub al, 0x30
    jmp ._exit

._exit:

    ret


exec_mem:


    mov si, _s_parse_buf2
    mov bx, 16
    mov ax, 0
._loop1:
    cmp byte [si], 0x00
    je ._exit_loop1
    mul bx
    mov cx, ax
    mov al, [si]
    call atoh
    mov ah, 0x00
    add cx, ax
    mov ax, cx
    inc si
    jmp ._loop1
._exit_loop1:
    mov [._w_adr], ax

    mov si, _s_parse_buf3
    mov bx, 10
    mov ax, 0
._loop2:
    cmp byte [si], 0x00
    je ._exit_loop2
    mul bx
    mov cx, ax
    mov al, [si]
    call atoi
    mov ah, 0
    add cx, ax
    mov ax, cx
    inc si
    jmp ._loop2
._exit_loop2:
    mov [._w_cnt], ax

    mov ax, [._w_adr]
    mov bx, [._w_cnt]
    call disp_mem
    
    
    ret

._w_adr db 0
._w_cnt db 0

parse_cmd:
    mov [._ax], ax
    call str_len
    mov [._w_len], bx
    mov bx, ._s_sep
    call in_str
    mov [._w_sep_pos], cx
    mov ax, [._ax]
    mov bx, 0
    mov cx, [._w_sep_pos]
    mov dx, _s_parse_buf1
    call sub_str
    mov ax, _s_parse_buf1
    call rtrim

    mov ax, [._ax]   ; 残り
    mov bx, [._w_sep_pos]
    inc bx
    mov cx, [._w_len]
    mov dx, ._s_temp_buf1
    call sub_str

    mov ax, ._s_temp_buf1    ; 2番目のトークン
    call str_len
    mov [._w_len], bx
    mov bx, ._s_sep
    call in_str
    mov [._w_sep_pos], cx
    mov ax, ._s_temp_buf1
    mov bx, 0
    mov cx, [._w_sep_pos]
    mov dx, _s_parse_buf2
    call sub_str
    mov ax, _s_parse_buf2
    call rtrim

    mov ax, ._s_temp_buf1    ; 残り（最後のトークン）
    mov bx, [._w_sep_pos]
    inc bx
    mov cx, [._w_len]
    mov dx, _s_parse_buf3
    call sub_str
    mov ax, _s_parse_buf3
    call rtrim

    ; ; debug write
    ; mov ax, [._ax]
    ; call get_cursor_pos
    ; inc ah
    ; mov bx, _s_parse_buf1
    ; call disp_strd
    ; call set_cursor_pos

    ; ; debug write
    ; call get_cursor_pos
    ; inc ah
    ; mov bx, _s_parse_buf2
    ; call disp_strd
    ; call set_cursor_pos

    ; ; debug write
    ; call get_cursor_pos
    ; inc ah
    ; mov bx, _s_parse_buf3
    ; call disp_strd
    ; call set_cursor_pos

._exit:

    ret

._s_temp_buf1 times 32 db 0
._s_temp_buf2 times 32 db 0
._ax dw 0
._s_sep db ' ', 0x00
._w_sep_pos dw 0
._w_len dw 0
_s_parse_buf1 times 32 db 0
_s_parse_buf2 times 32 db 0
_s_parse_buf3 times 32 db 0
_s_parse_buf4 times 32 db 0



disp_help:
    call get_cursor_pos
    mov bx, ._s_msg1
    call disp_strd
    mov al, 79
    call next_pos
    call set_cursor_pos
    
    call get_cursor_pos
    mov bx, ._s_msg2
    call disp_strd
    mov al, 79
    call next_pos
    call set_cursor_pos
    
    call get_cursor_pos
    mov bx, ._s_msg3
    call disp_strd
    mov al, 79
    call next_pos
    call set_cursor_pos
    
    call get_cursor_pos
    mov bx, ._s_msg4
    call disp_strd
    mov al, 79
    call next_pos
    call set_cursor_pos

    call get_cursor_pos
    mov bx, ._s_msg5
    call disp_strd
    mov al, 79
    call next_pos
    call set_cursor_pos

    mov al, 79
    call next_pos
    call set_cursor_pos

    ret
 
._s_msg1    db '  command is follow', 0x00
._s_msg2    db '    help', 0x00
._s_msg3    db '    cls', 0x00
._s_msg4    db '    locate x y', 0x00
._s_msg5    db '    mem adr len', 0x00


; param  : ax : target
;          bx : count
mem_clear:
    push cx

    mov si, ax
    mov cx, bx
._loop:
    mov byte [si], 0x00
    inc si
    loop ._loop
    
    pop cx
    ret
next_pos:
    push bx
    push cx
    push dx

    inc al
    cmp al, 80
    jb ._skip
    mov al, 0
    inc ah
    cmp ah, 25
    jb ._skip
    mov ah, 0x06
    mov al, 0x01
    mov bh, 0x07
    mov ch, 16
    mov cl, 0
    mov dh, 24
    mov dl, 79
    int 0x10
    mov ah, 24
    mov al, 0
._skip:
    
    pop dx
    pop cx
    pop bx
    
    ret

recv_message:

    mov al, 0x03
    call recv_my_msg
    jz .no_msg


    ret

.no_msg:
        ret

get_key:
    push bx
    
    mov ax, 0x0000
    call read_key_buf
    mov bh, al
    call read_key_buf
    mov bl, al
    mov ax, bx
    
    pop bx
    ret

read_key_buf:
    push bx
    push cx
    push ds
    push es
    
    mov ax, 0x0000
    mov bx, key_buf_seg
    mov ds, bx
    mov es, bx
    mov bx, 0x0000
    
    mov cx, [es:bx + key_buf_head_ofs]
    mov dx, [es:bx + key_buf_tail_ofs]
    
    inc dx
    cmp dx, key_buf_len + 1
    ;cmp dx, 256 + 1
    jb .no_wrap
    mov dx, 0
.no_wrap:
    
    cmp cx, dx
    je .empty
    mov [es:bx + key_buf_tail_ofs], dx
    mov ax, [es:bx + key_buf_tail_ofs]
    
    add bx, dx
    add bx, key_buf_data_ofs
    mov byte al, [es:bx]
    mov byte [es:bx], 0x00
    jmp .not_empty
.empty:
    sub cx, dx
.not_empty:
    pop es
    pop ds
    pop cx
    pop bx

    ret


%include "routine2.asm"

%include "routine_imp.inc"

