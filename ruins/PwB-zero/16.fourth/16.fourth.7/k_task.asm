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
    call disp_hex_be
    
    mov al, ':'
    call putc
    mov al, 0x00
    
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
    mov al, ' '
    call putc
    mov ax, [es:bx + 0]
    call disp_hex_be
    mov al, ' '
    call putc
    mov ax, [es:bx + 2]
    call disp_hex_be
    mov al, ' '
    call putc
    mov ax, [es:bx + 4]
    call disp_hex_be
    mov al, ' '
    call putc
    mov ax, [es:bx + 6]
    call disp_hex_be
    mov al, ' '
    call putc
    mov ax, [es:bx + 8]
    call disp_hex_be

    ;call lock_log
    
    call read_log
    jz .empty_data
    mov bh, al
    call read_log
    jz .empty_data
    mov bl, al
    mov al, ':'
    call putc
    mov ax, bx
    call disp_hex_be
    mov al, ':'
    call putc
    mov ax, bx
    call putc
    

.empty_data:
    ;call unlock_log
    
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

read_log:
    push bx
    push cx
    push ds
    push es
    
    mov bx, shared_buf_seg
    mov ds, bx
    mov es, bx
    
    mov cx, [es:shared_head_ofs]
    mov bx, [es:shared_tail_ofs]
    inc bx
    cmp bx, shared_buf_len + 1
    jb .no_wrap
    mov bx, 0
.no_wrap:
    cmp cx, bx
    je .empty
    mov cx, [es:shared_tail_ofs]
    mov [es:shared_tail_ofs], bx
    ;mov bx, cx
    mov byte al, [es:shared_data_ofs + bx]
    mov byte [es:shared_data_ofs + bx], 0x00
    jmp .not_empty
.empty:
    xor cx, cx
.not_empty:
    pop es
    pop ds
    pop cx
    pop bx

    ret

._next_head_val dw 0
._current_head_val dw 0
._current_tail_val dw 0
._data_pos dw 0



; ビッグエンディアン形式で AX を16進表示（上位桁→下位桁）
disp_hex_be:
    push ax
    push bx
    push cx

    mov bx, ax        ; BX に値をコピー
    mov cx, 4         ; 4桁分ループ

.next_digit:
    rol bx, 4         ; 左に4ビット回転（最上位ニブルが下位にくる）
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
    int 0x10
    loop .next_digit

    pop cx
    pop bx
    pop ax
    ret


; リトルエンディアン形式で AX を16進表示（下位→上位バイト）
disp_hex_le:
    push ax

    mov ah, al        ; AH ← 下位バイト
    call disp_byte_hex2  ; 先に下位バイト（例：34）

    mov al, ah        ; AL ← 上位バイト
    call disp_byte_hex2  ; 次に上位バイト（例：12）

    pop ax
    ret



; AL の1バイトを16進で表示（上位→下位ニブル）
disp_byte_hex2:
    push ax

    mov ah, al
    shr ah, 4
    and ah, 0x0F
    cmp ah, 10
    jl .high_digit
    add ah, 'A' - 10
    jmp .high_out
.high_digit:
    add ah, '0'
.high_out:
    mov al, ah
    mov ah, 0x0E
    int 0x10

    pop ax
    push ax

    and al, 0x0F
    cmp al, 10
    jl .low_digit
    add al, 'A' - 10
    jmp .low_out
.low_digit:
    add al, '0'
.low_out:
    mov ah, 0x0E
    int 0x10

    pop ax
    ret


;--------------------------------
; lock_log
; ログバッファの排他ロックを獲得するまでループ
;--------------------------------
lock_log:
    push ax
    push bx
    push es

.lock_try:
    ; waitループ（少し休む）
    mov ax, 2
    call _wait

    ; ロック取得試行
    mov ax, 1
    mov bx, log_lock_seg
    mov es, bx
    mov bx, log_lock_off
    xchg ax, [es:bx]     ; ax と [es:bx] を交換（アトミック）
    cmp ax, 0
    jne .lock_try        ; 他が使ってたら再試行

    pop es
    pop bx
    pop ax
    ret

;--------------------------------
; unlock_log
; ロックを解放する
;--------------------------------
unlock_log:
    push bx
    push es

    mov bx, log_lock_seg
    mov es, bx
    mov bx, log_lock_off
    mov word [es:bx], 0

    pop es
    pop bx
    ret


tick_ptr dw 0


