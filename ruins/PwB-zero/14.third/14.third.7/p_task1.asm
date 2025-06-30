org 0x0000
bits 16

section .text
;----------------------------------
; スタート
;----------------------------------
setup:
    mov sp, 0x7ff0
    
    ;call set_own_ds
    ;call disp_nl
    ;mov  ax, msg_tick
    ;call disp_str
    
    
start:

    sti
    
    
    
    call set_own_ds
    
    call task_body
    sti
    hlt
    jmp start

;----------------------------------
; 処理本体（単純な表示など）
;----------------------------------
task_body:
    
    call get_cursor_pos
    mov bx, ax
    mov ah, 0xe
    mov al, 0x40
    call set_cursor_pos
    
    cli
    mov al, '1'
    call putc
    mov al, ':'
    call putc
    call get_tick
    call disp_word_hex
    sti

    mov ax, bx
    call set_cursor_pos

    ;mov al, '1'     ; '2', '3' に応じて変えて
    ;call write_log

    
    ;mov si, msg_tick
    ;call write_log_str


    ;push ds
    ;mov ax, c_data_seg
    ;mov es, ax
    ;mov ds, ax
    ;mov bx, c_data_msg_off
    ;mov ax, [es:bx]
    ;mov si, ax
    ;call write_log_str
    ;;call disp_str
    ;pop ds

    push ds
    mov ax, c_data_seg
    mov ds, ax
    call get_c_msg_off
    mov si, ax
    call write_log_str
    ;call disp_str
    pop ds


    ret

msg_tick:
    db '0123456789task3: tick=', 0


;----------------------------------
; 共通ルーチンなど（必要に応じて）
;----------------------------------
%include "routine.asm"

;----------------------------------
; セクション末尾
;----------------------------------
times 2048 - ($ - $$) - 2 db 0
dw 0x5E5E
