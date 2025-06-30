;org 0x0000
bits 16

%include "routine_imp.inc"

;----------------------------------
; スタート
;----------------------------------
global _start

_start:


setup:
    ;mov sp, 0x7000
    call set_own_seg

    mov ax, tick_addr
    mov [tick_ptr], ax

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
    
    call get_cursor_pos
    mov bx, ax
    
    mov ah, 17
    mov al, 30
    call set_cursor_pos
    
    mov al, 'k'
    call putc
    mov al, ' '
    call putc
    mov al, ':'
    call putc

    call get_tick
    call disp_hex
    
    mov al, ':'
    call putc
    mov al, 0x00
    
.no_data:
    

    push ax
    push bx
    push es
    push ds
    ;mov ax, key_buf_seg
    mov ax, shared_buf_seg
    mov es, ax
    mov ds, ax
    mov bx, 0x00
    mov al, ' '
    call putc
    mov ax, [es:bx + 0]
    call disp_hex
    mov al, ' '
    call putc
    mov ax, [es:bx + 2]
    call disp_hex
    mov al, ' '
    call putc
    mov ax, [es:bx + 4]
    call disp_hex
    mov al, ' '
    call putc
    mov ax, [es:bx + 6]
    call disp_hex
    mov al, ' '
    call putc
    mov ax, [es:bx + 8]
    call disp_hex

    ;call lock_log
    
;    call read_log
;    jz .empty_data
;    mov bh, al
;    call read_log
;    jz .empty_data
;    mov bl, al
;    mov al, ':'
;    call putc
;    mov ax, bx
;    call disp_hex_be
;    mov al, ':'
;    call putc
;    mov ax, bx
;    call putc
    
    pop ds
    pop es
    pop bx
    pop ax

    

.empty_data:
    
    mov ax, bx
    call set_cursor_pos
    
    
    ret

_s_msg: db 'k :', 0x00
_dt_save db 0

;----------------------------------
; 共通ルーチンなど（必要に応じて）
;----------------------------------
