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
    
    mov ah, 11
    mov al, 30
    mov bx, ._s_msg
    call disp_strd

    call get_tick
    mov bx, ax
    mov ah, 11
    mov al, 33
    call disp_word_hexd


    ; メッセージ関連処理
    mov al, 0x04
    call recv_message
    jz ._msg_skip

._msg_skip


    ; 疑似故障
.accident:
    ;mov ax, 0x00ff
    call xorshift16
    
    ; 確認用表示
    ;push ax
    ;push bx
    ;mov bx, ax
    ;mov ah, 12
    ;mov al, 33
    ;call disp_word_hexd
    ;pop bx
    ;pop  ax
    
    cmp ax, 0x0010
    ja .skip
    mov ax, 0x0008
    call _wait
;    jmp .accident
.skip:
    

    ; heartbeatの更新
    mov ax, ctx_p_task2_id
    call set_ctx_heartbeat
    
    sti


    ret

._s_msg db 'p2:', 0x00








;----------------------------------
; 共通ルーチンなど（必要に応じて）
;----------------------------------
recv_message:
    ret


%include "routine_imp.inc"

%include "routine2.asm"

