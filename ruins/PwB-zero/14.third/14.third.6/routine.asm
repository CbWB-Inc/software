;********************************
; disp_str
;       display null-terminated string.
; param : ax : addr of mem where string is set.
;********************************
disp_str:

    push ax
    push bx
    push si

    ;mov bx, cs
    ;mov ds, bx
    ;mov es, ax
    
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

    ;call bin_byte_hex
    call bin_byte_hex
    mov ah, 0x0e
    mov al, bh
    int 0x10
    mov al, bl
    int 0x10

    pop bx
    pop ax

    ret


;********************************
; disp_word_hex
;       2バイト（1ワード）のデータを表示する
;	（ビッグエンディアン表記）
; param : ax : 表示するword
;********************************
disp_word_hex:

    push ax
    push bx

    mov bx, ax
    mov al, bh
    call disp_byte_hex

    mov al, bl
    call disp_byte_hex

._end:

    pop bx
    pop ax

    ret

;********************************
; bin_nibble_hex
;       4bit整数を16進文字に変換する
;       0～15 -> '0'～'f'
; param  : ah : 変換する数値
;               16以上を指定すると上位ニブルは無視され、下位ニブルが変換されて返る
;                 e.g. 0x21 -> '1'
; return : al : 変換された文字
;******************************
bin_nibble_hex:
        and ah, 0x0f
        cmp ah, 0x09
        ja .gt_9
        add ah, 0x30
        jmp .cnv_end
.gt_9:
        add ah, 0x37

.cnv_end:
        mov al, ah
        ret

;********************************
; bin_byte_hex
;       1バイトの数値を16進文字列に変換する
; param  : al : 変換したい数値
; return : bx : 変換した2文字の16進文字
;********************************
bin_byte_hex:
    push cx

    mov cl, al
    mov ah, al
    sar ah, 4
    and ah, 0x0f
    mov al, 0x00
    call bin_nibble_hex
    mov bh, al
    
    mov ah, cl
    and ah, 0x0f
    mov al, 0x00
    call bin_nibble_hex
    mov bl, al

    pop cx

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
    call disp_byte_hex

    inc si
    dec cx

    cmp cx, 0
    je ._loop_end

    jmp ._loop

._loop_end:

    pop si
    pop cx
    pop bx
    pop ax

._end:

    call disp_nl
      
    ret


;>****************************
;> hlt
;>****************************
_hlt:

._loop:
    hlt
    
    mov ah, 0x0e
    mov al, '#'
    int 0x10
    
    jmp ._loop

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
; cls
;       テキストをクリアする
; param : 
; return: 
;********************************
cls:
    push ax
    push cx
    push es
    push ds
    push di
    
    mov ax, 0xb800      ; VGAテキストビデオメモリ
    mov es, ax
    xor di, di          ; 書き込み位置（画面先頭）

    mov cx, 80*25       ; 画面全体（80列 × 25行）
    mov ah, 0x07        ; 属性：黒背景・明るい灰色文字
    mov al, ' '         ; 空白文字

._loop:
    stosw             ; AX → ES:DI（1文字分：文字＋属性）
    loop ._loop

    mov ah, 0x00
    mov al, 0x00
    call set_cursor_pos
    
    pop di
    pop ds
    pop es
    pop cx
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
get_key:
	

    mov ah, 0x00
    int 0x16

    ret

;********************************
; exit
;       電源を落とす
; param : 
; return: 
;********************************
exit:

    push ax
    push ds
    push es
    push si
    
    jmp $+3
    pop si
    mov ax, cs
    mov ds, ax
    mov es, ax
    
    ; 処理終了
    call disp_nl
    call disp_nl
    ;call disp_nl
    ;call disp_nl
    mov ax, ._s_msg
    mov bx, es
    call disp_str
    ;call disp_str
    call get_key
    call power_off

    pop si
    pop es
    pop ds
    pop ax

    ret
._s_msg: db 'hit any key to power off', 0x0d, 0x0a, 0x00


;****************************
; power_off
; 	パワーオフ
;****************************
power_off:

    ; APM-BIOSのバージョン取得
    mov ax, 0x5300
    mov bx, 0
    int 0x15
    jc _hlt
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

    ;jmp _hlt
    jmp _hlt

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
; param : ax, bx, cx
; return: dx
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
    mov dl, 0x00
    jmp ._exit

._not_equal:
    mov dl, 0x01

    
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
; set_own_ds
;       実行時のcsにdsを合わせる。
; param : 
; return: 
;********************************
set_own_ds:
    
    push ax

    jmp $+3
    pop si
    mov ax, cs
    mov ds, ax
    mov es, ax

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
; tick値を得る
; -------------------------------
get_tick:
    
    push bx
    push ds
    
    mov ax, tick_seg
    mov ds, ax
    mov bx, tick_addr
    mov ax, [bx]

    pop ds
    pop bx

    ret

set_tick:
    
    push bx
    push ds
    
    mov bx, tick_seg
    mov ds, bx
    mov bx, tick_addr
    mov [bx], ax

    pop ds
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
    ;mov al, ' '
    ;call putc
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
    cli
    mov bx, cx
    mov dx, 0x0000
    call get_tick
    div bx
    cmp dx, 0x00
    je .exit
    sti
    ;mov al, ' '
    ;call putc
    hlt
    jmp .loop
.exit:
    ret


decide_next_p_task:
    ; queue_indexをもとにctx_nextを設定
    mov si, [queue_index]
    mov ax, si
    shl si, 1                        ; si *= 2 (wordサイズオフセット)
    mov bx, [p_task_queue + si]
    mov [ctx_next], bx              ; 次の実行タスクをセット

    ; queue_index++
    inc ax
    mov cx, [queue_size]
    xor dx, dx
    div cx
    mov [queue_index], dx           ; dx = ax % queue_size
    mov [queue_index], dx

    ret


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

    tick_addr equ 0xfff0
    tick_seg equ 0x9000
    tick_ptr dw 0
    sleep_sec dw 0



p_task_queue:
    dw ctx_p_task1, ctx_p_task2, ctx_p_task3  ; キュー内容
queue_size:
    dw 3
queue_index:
    dw 0

ctx_current dw 0x0000
ctx_next  dw 0x0000
ctx_temp    dw 0x0000
ctx_p_task1 equ 0x8600
ctx_p_task2 equ 0x8700
ctx_p_task3 equ 0x8800



_test: db 0x33, 0x00

_s_one_line_buf: times 128 db 0
_s_cmp_buf: times 128 db 0
_b_x: db 0x00
_b_y: db 0x00
_b_len: db 0x00
_b_pos: db 0x00
_s_p_msg db 'p_task', 0x00
