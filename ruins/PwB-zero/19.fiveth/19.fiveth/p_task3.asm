;org 0x0000
bits 16


;----------------------------------
; スタート
;----------------------------------
global _start

_start:

setup:
    mov ax, cs
    mov ss, ax
    mov sp, 0x7ff0
    
    call set_own_seg
    
start:
    sti
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
    
    mov ah, 13
    mov al, 30
    mov bx, ._s_msg
    call disp_strd

    call get_tick
    mov bx, ax
    mov ah, 13
    mov al, 33
    call disp_word_hexd
    

    ; メッセージ関連処理
    mov bx, 0x0000
    mov dx, 0x0000
    mov al, 0x05
    call recv_message
    jz ._msg_not_me
    mov cx, ax
    mov dx, bx
    mov ah, 13
    mov al, 38
    mov bh, 0x07
    mov bl, '('
    call putcd
    
    mov ah, 13
    mov al, 39
    mov bh, 0x07
    mov bl, ch
    add bl, '0'
    call putcd
    
    mov ah, 13
    mov al, 40
    mov bh, 0x07
    mov bl, ')'
    call putcd
    
    mov ah, 13
    mov al, 41
    mov bx, dx
    call disp_word_hexd
    jmp ._msg_end
    
    mov ah, 13
    mov al, 46
    mov bx, cx
    call disp_word_hexd
    
    mov ah, 13
    mov al, 46
    mov bx, dx
    call disp_word_hexd
    
    jmp ._msg_end
    
._msg_not_me:
    mov ah, 13
    mov al, 38
    mov bx, ._s_not_me
    call disp_strd
    
._msg_end:

    ; heartbeatの更新
    mov ax, ctx_p_task3_id
    call set_ctx_heartbeat

    ret

._s_msg db 'p3:', 0x00

._s_not_me db '(-)----', 0x00






;----------------------------------
; 共通ルーチンなど（必要に応じて）
;----------------------------------
recv_message:
    ret

%include "routine_imp.inc"

%include "routine2.asm"

