section .text

global disp_str
global disp_nl
global putc
global disp_word_hex
global disp_hex
global get_cursor_pos
global set_cursor_pos
global get_tick
global set_tick
global sleep
global _wait

%include "routine.inc"

;********************************
; disp_str
;       display null-terminated string.
; param : ax : addr of mem where string is set.
;********************************
disp_str:

    push ax
    push si

    mov si, ax
    mov ah, 0x0E
    
    cli
._loop:
    lodsb
    or al, al
    jz ._loop_end
    int 0x10

    jmp ._loop

._loop_end:
    sti
    
    pop si
    pop ax

    ret


;****************************
; disp_nl
;   改行する
;****************************
disp_nl:

    push ax

    mov ah, 0x0e
    mov al, 0x0d
    int 0x10
    mov al, 0x0a
    int 0x10
    
    pop ax
    
    ret


; -------------------------------
; 画面に1文字表示
; -------------------------------
putc:
    mov ah, 0x0e
    int 0x10
    ret

; -------------------------------
; 画面に１６進表示
; -------------------------------
disp_word_hex:
    push ax
    push bx
    push cx

    mov cx, ax
    mov ah, 0x0e

    mov bx, cx
    shr bx, 12
    and bx, 0x0f
    mov al, bl

    cmp al, 10
    jl .digit
    add al, 'A' - 10
    jmp .print
.digit:
    add al, '0'
.print:
    int 0x10

    mov bx, cx
    shr bx, 8
    and bx, 0x0f
    mov al, bl
    cmp al, 10
    jl .digit2
    add al, 'A' - 10
    jmp .print2
.digit2:
    add al, '0'
.print2:
    int 0x10

    mov bx, cx
    shr bx, 4
    and bx, 0x0f
    mov al, bl
    cmp al, 10
    jl .digit3
    add al, 'A' - 10
    jmp .print3
.digit3:
    add al, '0'
.print3:
    int 0x10

    mov bx, cx
    and bx, 0x0f
    mov al, bl
    cmp al, 10
    jl .digit4
    add al, 'A' - 10
    jmp .print4
.digit4:
    add al, '0'
.print4:
    int 0x10
    
    pop cx
    pop bx
    pop ax
    
    ret


; -------------------------------
; 画面に１６進表示
; -------------------------------
disp_hex:
    push ax
    push bx
    push cx

    mov cx, ax        ; BX に値をコピー
    mov bx, ax
    
    ; 最上位ニブル
    shr bx, 12
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

    ; 第2ニブル
    mov bx, cx
    shr bx, 8         ; 左に4ビット回転（上位桁から出す）
    mov al, bl
    and al, 0x0F      ; 下位4ビットだけ使う

    cmp al, 10
    jl .digit2
    add al, 'A' - 10
    jmp .print2
.digit2:
    add al, '0'

.print2:
    mov ah, 0x0E
    int 0x10          ; BIOSで表示

    ; 下位第１ニブル
    mov bx, cx
    shr bx, 4         ; 左に4ビット回転（上位桁から出す）
    mov al, bl
    and al, 0x0F      ; 下位4ビットだけ使う

    cmp al, 10
    jl .digit3
    add al, 'A' - 10
    jmp .print3
.digit3:
    add al, '0'

.print3:
    mov ah, 0x0E
    int 0x10          ; BIOSで表示

    ; 最下位ニブル
    mov bx, cx
    mov al, bl
    and al, 0x0F      ; 下位4ビットだけ使う

    cmp al, 10
    jl .digit4
    add al, 'A' - 10
    jmp .print4
.digit4:
    add al, '0'

.print4:
    mov ah, 0x0E
    int 0x10          ; BIOSで表示

.exit:
    pop cx
    pop bx
    pop ax
    ret

;********************************
; get_cursor_pos
; カーソル位置取得
; paramater : なし
; return    : ah : 現在の行（0オリジン）
;           : al : 現在の列（0オリジン）
;********************************
get_cursor_pos:

    push bx
    push cx
    push dx

    mov ah, 0x03
    mov al, 0x00
    mov bh, 0x00    ; 当面0ページ固定で様子を見る
    mov bl, 0x00    ; 当面0ページ固定で様子を見る
    int 0x10

    mov ax, dx
    mov bx, cx

    pop dx
    pop cx
    pop bx

    ret


;********************************
; set_cursor_pos
; カーソル位置設定
; parameter : ah : 設定する行（0オリジン）
;           : al : 設定する列（0オリジン）
; return : 事実上なし
;********************************
set_cursor_pos:

    push ax
    push bx
    push dx

    mov dx, ax
    mov ah, 0x02
    mov al, 0x00
    mov bh, 0x00    ; 当面０ページで固定
    mov bl, 0x00    ; 当面０ページで固定
    int 0x10

    pop dx
    pop bx
    pop ax

    ret

; -------------------------------
; tick値を得る
; -------------------------------
get_tick:
    
    push bx
    push es
    push ds
    
    mov ax, tick_seg
    mov es, ax
    mov ds, ax
    mov bx, tick_addr
    mov ax, [es:bx]

    pop ds
    pop es
    pop bx

    ret

set_tick:
    
    push bx
    push es
    push ds
    
    mov bx, tick_seg
    mov es, bx
    mov ds, bx
    mov bx, tick_addr
    mov [es:bx], ax

    pop ds
    pop es
    pop bx

    ret

sleep:
    mov [sleep_sec], ax
.loop:
    cli
    call get_tick
    mov bx, 100
    mov dx, 0
    div bx
    cmp dx, 0x0000
    jne .skip_dec
    dec word [sleep_sec]
    mov ax, [sleep_sec]
    cmp ax, 0x0000
    je .exit
.skip_dec:
    sti
    hlt
    jmp .loop
.exit:

    ret

_wait:
    cmp ax, 0x0000
    je .exit
    mov cx, ax
.loop:
    ;cli
    mov bx, cx
    mov dx, 0x0000
    call get_tick
    div bx
    cmp dx, 0x00
    je .exit
    ;sti
    hlt
    jmp .loop
.exit:
    ret


section .data
;>********************************
;> definition of variables
;>********************************

    _c_seg          equ 0x8000
    _c_ex_area_addr equ 0x0000

    _c_true         equ '1'
    _c_false        equ '0'

    _b_true         equ 1
    _b_false        equ 0

    _s_crlf:       db 0x0d, 0x0a, 0x00

    _s_buf: times 128 db 0 

    _b_rt_sts:     db 0

    _w_ax:
    _b_al:    db 0
    _b_ah:    db 0

    _w_bx:
    _b_bl:    db 0
    _b_bh:    db 0

    _w_cx:
    _b_cl:    db 0
    _b_ch:    db 0

    _w_dx:
    _b_dl:    db 0
    _b_dh:    db 0

    _w_x:
    _b_xl:    db 0
    _b_xh:    db 0

    _w_y:
    _b_yl:    db 0
    _b_yh:    db 0

    _w_i:
    _b_il:    db 0
    _b_ih:    db 0

    _w_j:
    _b_jl:    db 0
    _b_jh:    db 0

    _w_k:
    _b_kl:    db 0
    _b_kh:    db 0

    _s_true:  db 'TRUE ', 13, 10, 0

    _s_false: db 'FALSE', 13, 10, 0

    _b_isTest: db 0

    section .text

    _s_success: db 'SUCCESS!! (^^)b ', 13, 10, 0
    _s_fail:    db 'fail (T_T) ', 13, 10, 0


