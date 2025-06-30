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
    
    mov ah, 18
    mov al, 60
    call set_cursor_pos
    
    mov al, 'k'
    call putc
    mov al, ' '
    call putc
    mov al, ':'
    call putc

    
    call get_tick
    call disp_hex
    
    
    mov ax, bx
    call set_cursor_pos


    ;call get_cursor_pos
    ;mov bx, ax

    ;mov ax, _s_common_buf   ; routine.asmにある汎用128バイトバッファ
    ;mov bx, cs
    ;mov ds, bx
    ;mov es, bx
    ;mov di, ax
    ;call read_log_str       ; DS:DI に文字列を読み込み

    ;cmp byte [di-1], 0
    ;je .skip

    ;call disp_nl
    ;mov ax, _s_common_buf
    ;mov bx, cs
    ;call disp_str

.skip:
    ;mov ax, bx
    ;call set_cursor_pos
        
    
    ret

_s_msg: db 'k :', 0x00

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

;%include "routine.asm"

