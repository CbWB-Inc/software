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
    
    mov ah, 9
    mov al, 30
    mov bx, ._s_msg
    call disp_strd

    call get_tick
    mov bx, ax
    mov ah, 9
    mov al, 33
    call disp_word_hexd
    
    mov ah, 9
    mov al, 37
    mov bh, 7
    mov bl, ':'
    call putcd
    
    call get_key
    jz .skip
    mov cx, ax
    mov ah, 9
    mov al, 38
    mov bh, 7
    mov bl, cl
    call putcd
    mov al, 39
    mov bl, ':'
    call putcd
    mov ah, 9
    mov al, 40
    mov bx, cx
    call disp_word_hexd
.skip:



    ; heartbeatの更新
    
    mov ax, ctx_p_task1_id
    call set_ctx_heartbeat

    sti

    ret

._s_msg db 'p1:', 0x00

;----------------------------------
; 共通ルーチンなど（必要に応じて）
;----------------------------------

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

