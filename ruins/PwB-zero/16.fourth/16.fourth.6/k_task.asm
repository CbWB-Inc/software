;org 0x0000
bits 16

%include "routine.inc"

;----------------------------------
; スタート
;----------------------------------
global _start

_start:


setup:
    mov sp, 0x7000
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
    mov al, 40
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
    
    ; log読み込み
;    call read_log
;    jz .no_data      ; 空ならスキップ
;    mov bh, al
;;    call putc
;    call read_log
;    jz .no_data      ; 空ならスキップ
;    mov bl, al
;    mov ax, bx
;    call disp_hex
    
.no_data:
    
    
    
    push ax
    push bx
    push es
    push ds
    mov ax, shared_buf_seg
    mov es, ax
    mov ds, ax
    ;mov bx, 0x100
    mov bx, 0x00
    ;mov al, ' '
    ;call putc
    ;mov ax, [es:bx + 0]
    ;call disp_hex
    ;mov al, ' '
    ;call putc
    ;mov ax, [es:bx + 2]
    ;call disp_hex
    ;mov al, ' '
    ;call putc
    ;mov ax, [es:bx + 4]
    ;call disp_hex
    ;mov al, ' '
    ;call putc
    ;mov ax, [es:bx + 6]
    ;call disp_hex
    ;mov al, ' '
    ;call putc
    ;mov ax, [es:bx + 8]
    ;call disp_hex
    
    ;call disp_nl
    ;call debug_sub
    
    




    
    ;mov ah, [di + 0]
    ;mov al, [di + 1]
    ;mov bh, [di + 2]
    ;mov bl, [di + 3]
    ;call disp_hex
    ;mov ax, bx
    ;call disp_hex
    pop ds
    pop es
    pop bx
    pop ax
    
    
    
    
    
    
    
    mov ax, bx
    call set_cursor_pos
    
    
    ret

_s_msg: db 'k :', 0x00
_dt_save db 0

;----------------------------------
; 共通ルーチンなど（必要に応じて）
;----------------------------------

disp_hex:
    push ax
    push bx
    push cx

    mov bx, ax        ; BX に値をコピー
    mov cx, 4         ; 4桁分ループ

.next_digit:
    rol bx, 4         ; 左に4ビット回転（上位桁から出す）
    mov al, bl
    and al, 0x0F      ; 下位4ビットだけ使う

    cmp al, 10
    jl .digit
    add al, 'A' - 10
    jmp .print
.digit:
    add al, '0'

.print:
    mov ah, 0x0E
    int 0x10          ; BIOSで表示
    loop .next_digit

    pop cx
    pop bx
    pop ax
    ret


;shared_buf_seg  equ 0x8d00
;shared_head_ofs equ 0x0000
;shared_tail_ofs equ 0x0002
;shared_data_ofs equ 0x0004
;;shared_buf_len  equ 252
;shared_buf_len  equ 6

tick_ptr dw 0

;%include "routine.asm"

