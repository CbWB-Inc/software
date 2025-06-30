section .text

;%include "routine_imp.inc"
%include "routine_exp.inc"

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
; disp_byte_hex
;      1バイトの数値を16進で表示する
; param  : al : 表示したい数値
;********************************
disp_byte_hex:
    push ax
    push bx
    push cx

    mov cx, ax
    mov ah, 0x0e

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

;********************************
; disp_mem
;       指定された領域を16進で指定したサイズ表示する
; param : ax : 表示する領域のアドレス
;         bx : 表示するサイズ
;********************************
disp_mem:

    push ax
    push bx
    push cx
    push si
    
    cmp bx, 0
    je ._end

    mov si, ax
    mov cx, bx

._loop:
    mov byte al, [si]
    
    mov al, [si]

    ; start disp_byte_hex
    push ax
    push bx
    push cx

    mov cx, ax
    mov ah, 0x0e

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
    ; end disp_byte_hex

    inc si
    dec cx

    cmp cx, 0
    je ._loop_end

    jmp ._loop

._loop_end:

    pop si
    pop cx
    pop bx

    mov ah, 0x0e
    mov al, 0x0d
    int 0x10
    mov al, 0x0a
    int 0x10

    pop ax

._end:

      
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

;********************************
; get_key
;   0x00    Read Keyboard Input
;       キー入力待ちして、押下されたキーコードとアスキーコードを返す
;	（未確認だけどアスキーコードがないキーを押されるとアスキーコードに0x00が返るんじゃないかな）
; returen ; ah : キーコード
;           al : アスキーコード
;********************************
get_key_b:
	

    mov ah, 0x00
    int 0x16

    ret

;****************************
; power_off
; 	パワーオフ
;****************************
power_off:

    ; APM-BIOSのバージョン取得
    mov ax, 0x5300
    mov bx, 0
    int 0x15
    jc ._exit
    cmp ax, 0x0101
    js ._exit

    ; リアルモードからの制御を宣言（これ、もしかしたらリアルモードへの変更かも）
    mov ax, 0x5301
    mov bx, 0
    int 0x15

    ; APM-BIOS ver 1.1を有効化
    mov ax, 0x530e
    mov bx, 0
    mov cx, 0x0101
    int 0x15
    jc ._exit

    ; 全デバイスのAPM設定を連動させる
    mov ax, 0x530f
    mov bx, 0x0001
    mov cx, 0x0001
    int 0x15
    jc ._exit

    ; 全デバイスのAPM機能有効化
    mov ax, 0x5308
    mov bx, 0x0001
    mov cx, 0x0001
    int 0x15
    jc ._exit

    ; 電源OFF
    mov ax, 0x5307
    mov bx, 0x0001
    mov cx, 0x0003
    int 0x15

._exit:

    ret

;********************************
; str_len
;       ゼロターミネートされた文字列の長さを求める
; param   : ax : 文字列のアドレス
;           bx : セグメント
; returen ; cx : 文字列の長さ
;********************************
str_len:
    push ax
    push bx
    push si

    mov es, bx
    mov ds, bx

    mov si, ax
    mov bx, 0

._loop:
    cmp byte [si], 0x00
    je ._exit_loop
    inc si
    inc bx
    jmp ._loop

._exit_loop:

    pop si
    pop bx
    pop ax

    ret

;********************************
; ucase
;       大文字にする
; param : 
; return: 
;********************************
ucase:
    push ds
    push es
    push si
    
    mov es, bx
    mov ds, bx
    
    mov si, ax
    mov di, ax
._loop:
    lodsb
    or al, al
    jz ._exit
    cmp al, 0x61
    js ._skip
    cmp al, 0x7a
    jg ._skip
    sub al, 0x20
    stosb
._skip:
    jmp ._loop

._exit:
    pop si
    pop es
    pop ds
    
    ret

;********************************
; lcase
;       小文字にする
; param : 
; return: 
;********************************
lcase:
    push ds
    push es
    push si
    
    mov es, bx
    mov ds, bx

    mov si, ax
    mov di, ax
._loop:
    lodsb
    or al, al
    jz ._exit
    cmp al, 0x41
    js ._skip
    cmp al, 0x5a
    jg ._skip
    add al, 0x20
    stosb
._skip:
    jmp ._loop

._exit:
    pop si
    pop es
    pop ds
    
    ret

;********************************
; str_cmp
;       文字列を比較する
; param : ax, bx
; return: cl
;********************************
str_cmp:
    push ax
    push bx
    push si
    push di
    
    mov si, ax
    mov di, bx
    
._next_char:
    lodsb               ; AL ← DS:SI、SI++
    scasb               ; 比較 AL と ES:DI、DI++
    jne ._not_equal     ; 違っていたら不一致
    cmp al, 0
    jne ._next_char       ; NULLでなければ次へ

._equal:
    mov cl, 0x00
    jmp ._exit

._not_equal:
    mov cl, 0x01
    
._exit:

    pop di
    pop si
    pop bx
    pop ax
    
    ret

;********************************
; line_input
;       
; param : ax, bx
; return: ax
;********************************
line_input:

    push cx
    push ds
    push es

    mov es, bx
    mov ds, bx

    mov [_w_ax], ax

    ; バッファの初期化
    mov cx, 128
    mov di, ax
    mov al, 0
    rep stosb


    mov di, [_w_ax]
    
    
._loop:
    ; キー入力待ち
    mov ah, 0x00
    int 0x16
    ;call get_key
    
    ;   単なる改行
    cmp al, 0x0d  ;
    je ._end_of_line

    ;   空白未満は何もしない
    cmp al, 0x20  ;
    js ._loop

    ;   ８ビットコードは何もしない
    cmp al, 0x7F
    jge ._loop
    
    ;   表示可能文字
    mov byte [di], al
    inc di
    mov ah, 0x0E
    int 0x10
    
    
    jmp ._loop

._end_of_line:

._skip2:
    
    mov si, [_w_ax]
    mov cl, [si]
    cmp cl, 0x00
    je ._skip3
    push ax
    mov ah, 0x0e
    mov al, 0x0d
    int 0x10
    mov al, 0x0a
    int 0x10
    pop ax
    
._skip3:
    mov ax, [_w_ax]
    mov bx, ds

    pop es
    pop ds
    pop cx

    ret

;********************************
; set_own_seg
;       実行時のcsにdsを合わせる。
; param : 
; return: 
;********************************
set_own_seg:
    
    push ax

    mov ax, cs
    mov ds, ax
    mov es, ax

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
    mov bx, 400
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
    sti
    hlt
    loop .loop
.exit:
    cli
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

tick_ptr	dw 0
sleep_sec dw 0
tick_addr equ 0xfff0
tick_seg equ 0x8000


ctx_p_task1 equ 0x8600
ctx_p_task2 equ 0x8700
ctx_p_task3 equ 0x8800

ctx_current dw 0x0000
ctx_next  dw 0x0000
ctx_temp    dw 0x0000

shared_buf_seg  equ 0x9d00
shared_head_ofs equ 0x0000
shared_tail_ofs equ 0x0002
shared_data_ofs equ 0x0004
shared_buf_len equ 256

log_lock_seg equ 0x9e00
log_lock_off equ 0xfe00

g_cursor:
    .x: db 0x00
    .y: db 0x00

g_key_condition: db 0x00

key_buf_seg  		equ 0x9a00
key_buf_head_ofs 	equ 0x0000
key_buf_tail_ofs 	equ 0x0002
key_buf_data_ofs 	equ 0x0004
key_buf_len  		equ 256


