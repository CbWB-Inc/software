;org 0x0000
bits 16

;----------------------------------
; スタート
;----------------------------------
global _start

_start:

setup:
    mov sp, 0x7800
    mov ax, cs
    mov ds, ax
    mov es, ax
    ;call cls
    ;mov ah, 0x0
    ;mov al, 0x0
    ;call set_cursor_pos
    
start:
    sti
    ;mov ax, 2
    ;call _wait
    ;mov ax, 1
    ;call sleep
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
    mov al, 10
    mov bx, ._s_msg
    call disp_strd

    call get_tick
    mov bx, ax
    mov ah, 9
    mov al, 13
    call disp_word_hexd


    ; メッセージ関連処理
    mov bx, 0x0000
    mov dx, 0x0000
    call recv_message
    jz ._msg_not_me
    mov cx, ax
    mov dx, bx
    mov ah, 9
    mov al, 18
    mov bh, 0x07
    mov bl, '('
    call putcd
    
    mov ah, 9
    mov al, 19
    mov bh, 0x07
    mov bl, ch
    add bl, '0'
    call putcd
    
    mov ah, 9
    mov al, 20
    mov bh, 0x07
    mov bl, ')'
    call putcd
    
    mov ah, 9
    mov al, 21
    mov bx, dx
    call disp_word_hexd

._msg_end:
._msg_not_me

    ;mov ax, msgq_seg
    ;mov es, ax
    ;mov ds, ax
    
    ;mov ah, 15
    ;mov al, 46
    ;mov bx, [es:msgq_data_ofs + 0]
    ;call disp_word_hexd

    ;mov si, msgq_seg
    ;mov ah, 15
    ;mov al, 51
    ;mov bx, [es:msgq_data_ofs + 2]
    ;call disp_word_hexd

    ;mov si, msgq_seg
    ;mov ah, 15
    ;mov al, 56
    ;mov bx, [es:msgq_data_ofs + 4]
    ;call disp_word_hexd

    ;mov si, msgq_seg
    ;mov ah, 15
    ;mov al, 61
    ;mov bx, [es:msgq_data_ofs + 6]
    ;call disp_word_hexd

    ;mov si, msgq_seg
    ;mov ah, 15
    ;mov al, 66
    ;mov bx, [es:msgq_data_ofs + 8]
    ;call disp_word_hexd



    mov ax, ctx_d_task_id
    call set_ctx_heartbeat




    sti

    ret

._s_msg db 'd :', 0x00

;----------------------------------
; 共通ルーチンなど（必要に応じて）
;----------------------------------
recv_message:

    mov al, 0x02
    call recv_my_msg
    jz .no_msg
    mov cx, ax
    mov dx, bx

    ;mov ah, 3
    ;mov al, 0
    ;mov bx, cx
    ;call disp_word_hexd

    ;mov ah, 3
    ;mov al, 5
    ;mov bx, dx
    ;call disp_word_hexd

    ret

.no_msg:
        ret

%include "routine_imp.inc"

%include "routine2.asm"

buf:
    times 64 db 0

