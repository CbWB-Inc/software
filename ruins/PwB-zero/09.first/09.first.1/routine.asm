;********************************
; disp_str
;       display null-terminated string.
; param : ax : addr of mem where string is set.
;********************************
disp_str:

    push ax
    push si
    push es
    push ds
    push dx

    mov es, bx
    mov ds, bx
    mov si, ax
    mov ah, 0x0E

._loop:
    lodsb
    or al, al
    jz ._loop_end
    int 0x10
    jmp ._loop

._loop_end:
    pop dx
    pop ds
    pop es
    pop si
    pop ax

    retf

disp_str_ptr:
    disp_str_off : dw 0x0200
    disp_str_seg : dw 0x8000

;********************************
; disp_byte_hex
;      1バイトの数値を16進で表示する
; param  : al : 表示したい数値
;********************************
disp_byte_hex:
    push ax
    push bx

    call far [bin_byte_hex_ptr]
    mov ah, 0x0e
    mov al, bh
    int 0x10
    mov al, bl
    int 0x10

    pop bx
    pop ax

    retf

disp_byte_hex_ptr:
    disp_byte_hex_off : dw 0x0220
    disp_byte_hex_seg : dw 0x8000

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
    call far [disp_byte_hex_ptr]

    mov al, bl
    call far [disp_byte_hex_ptr]

._end:

    pop bx
    pop ax

    retf

disp_word_hex_ptr:
    disp_word_hex_off : dw 0x0237
    disp_word_hex_seg : dw 0x8000

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
        retf

bin_nibble_hex_ptr:
    bin_nibble_hex_off : dw 0x024e
    bin_nibble_hex_seg : dw 0x8000

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
    call far [bin_nibble_hex_ptr]
    mov bh, al
    
    mov ah, cl
    and ah, 0x0f
    mov al, 0x00
    call far [bin_nibble_hex_ptr]
    mov bl, al

    pop cx

    retf

bin_byte_hex_ptr:
    bin_byte_hex_off : dw 0x0265
    bin_byte_hex_seg : dw 0x8000


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
    
    retf

disp_nl_ptr:
    disp_nl_off : dw 0x028b
    disp_nl_seg : dw 0x8000

;    disp_nl_off : dw disp_nl


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
    push ds
    push es
    
    mov ds, cx
    mov es, cx
    

    cmp bx, 0
    je ._end

    mov si, ax
    mov cx, bx

._loop:
    mov byte al, [si]
    
    mov al, [si]
    call far [disp_byte_hex_ptr]

    inc si
    dec cx

    cmp cx, 0
    je ._loop_end

    jmp ._loop

._loop_end:

    pop es
    pop ds
    pop si
    pop cx
    pop bx
    pop ax

._end:

    call far [disp_nl_ptr]
      
    retf

disp_mem_ptr:
    disp_mem_off : dw 0x029c
    disp_mem_seg : dw 0x8000


;>****************************
;> hlt
;>****************************
_hlt:
    hlt
    
    mov ah, 0x0e
    mov al, '#'
    int 0x10
    
    jmp _hlt

_hlt_ptr:
    _hlt_off : dw 0x02cf
    _hlt_seg : dw 0x8000


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

    retf

get_cursor_pos_ptr:
    get_cursor_pos_off : dw 0x02dc
    get_cursor_pos_seg : dw 0x8000


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

    retf

set_cursor_pos_ptr:
    set_cursor_pos_off : dw 0x02f5
    set_cursor_pos_seg : dw 0x8000


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
    call far [set_cursor_pos_ptr]
    
    pop di
    pop ds
    pop es
    pop cx
    pop ax
    
    retf

cls_ptr:
    cls_off : dw 0x030c
    cls_seg : dw 0x8000


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

    retf

get_key_ptr:
    get_key_off : dw 0x0334
    get_key_seg : dw 0x8000


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
    call far [disp_nl_ptr]
    call far [disp_nl_ptr]
    mov ax, ._s_msg
    mov bx, es
    call far [disp_str_ptr]
    call far [get_key_ptr]
    call far [power_off_ptr]

    pop si
    pop es
    pop ds
    pop ax

    retf
._s_msg: db 'hit any key to power off', 0x0d, 0x0a, 0x00

exit_ptr:
    exit_off : dw 0x033d
    exit_seg : dw 0x8000


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

    jmp far [_hlt_ptr]

    ret

power_off_ptr:
    power_off_off : dw 0x0387
    power_off_seg : dw 0x8000


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


_test: db 0x33, 0x00

_s_one_line_buf: times 128 db 0
_s_cmp_buf: times 128 db 0
_b_x: db 0x00
_b_y: db 0x00
_b_len: db 0x00
_b_pos: db 0x00


; disp_str2のテスト
exp_disp_str:
    ;mov [disp_str_seg], cs

    mov ax, ._s_msg
    mov bx, es
    call far [disp_str_ptr]

    ret

._s_msg: db 'disp_str2', 0x0d, 0x0a, 0x00


; exp_bin_nibble_hex2のテスト
exp_bin_nibble_hex:

    mov ah, 0x21
    
    call far [bin_nibble_hex_ptr]

    mov ah, 0x0e
    int 0x10

    mov ah, 0x89
    
    call far [bin_nibble_hex_ptr]

    mov ah, 0x0e
    int 0x10

    mov ah, 0xaf
    
    call far [bin_nibble_hex_ptr]

    mov ah, 0x0e
    int 0x10

    ret

; exp_bin_byte_hex2のテスト
exp_bin_byte_hex:

    mov al, 0xef
    
    call far [bin_byte_hex_ptr]

    mov ah, 0x0e
    mov al, bh
    int 0x10

    mov ah, 0x0e
    mov al, bl
    int 0x10

    ret

; exp_disp_byte_hex2のテスト
exp_disp_byte_hex:

    mov al, 0xef

    call far [bin_byte_hex_ptr]

    mov ah, 0x0e
    mov al, bh
    int 0x10

    mov ah, 0x0e
    mov al, bl
    int 0x10

    mov al, 0x32

    call far [disp_byte_hex_ptr]

    ret

; exp_disp_word_hex2のテスト
exp_disp_word_hex:

    mov ax, 0xef32

    call far [disp_word_hex_ptr]

    ret

; exp_disp_mem2のテスト
exp_disp_mem:

    mov ax, ._s_msg
    mov dx, bx
    mov bx, 10
    mov cx, ds

    call far [disp_mem_ptr]

    ret

._s_msg: db '1234567890'

exp_routine_test:

    ; disp_strのテスト
    call exp_disp_str
    

    ; bin_nibble_hexのテスト
    call exp_bin_nibble_hex
    call far [disp_nl_ptr]

    ; bin_byte_hexのテスト
    call exp_bin_byte_hex
    call far [disp_nl_ptr]

    ; disp_byte_hexのテスト
    call exp_disp_byte_hex
    call far [disp_nl_ptr]

    ; disp_memのテスト
    call exp_disp_mem
    call far [disp_nl_ptr]

    ret


