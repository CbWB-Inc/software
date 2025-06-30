;********************************
; disp_str
;       display null-terminated string.
; param : ax : addr of mem where string is set.
;         bx : ds
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
    disp_str_off : dw 0x0000
    disp_str_seg : dw 0x9000

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
    disp_byte_hex_off : dw 0x0020
    disp_byte_hex_seg : dw 0x9000

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
    disp_word_hex_off : dw 0x0037
    disp_word_hex_seg : dw 0x9000

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
    bin_nibble_hex_off : dw 0x004e
    bin_nibble_hex_seg : dw 0x9000

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
    bin_byte_hex_off : dw 0x0065
    bin_byte_hex_seg : dw 0x9000


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
    disp_nl_off : dw 0x008b
    disp_nl_seg : dw 0x9000

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
    
    mov ds, bx
    mov es, bx
    

    cmp bx, 0
    je ._end

    mov si, ax
    ;mov cx, bx
    mov cx, cx

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
    disp_mem_off : dw 0x009c
    disp_mem_seg : dw 0x9000


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
    _hlt_off : dw 0x00cf
    _hlt_seg : dw 0x9000


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
    get_cursor_pos_off : dw 0x00dc
    get_cursor_pos_seg : dw 0x9000


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
    set_cursor_pos_off : dw 0x00f5
    set_cursor_pos_seg : dw 0x9000


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
    cls_off : dw 0x010c
    cls_seg : dw 0x9000


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
    get_key_off : dw 0x0134
    get_key_seg : dw 0x9000


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
    exit_off : dw 0x013d
    exit_seg : dw 0x9000


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
    power_off_off : dw 0x0187
    power_off_seg : dw 0x9000




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

    retf

str_len_ptr:
    str_len_off : dw 0x01db
    str_len_seg : dw 0x9000


;********************************
; one_line_editor
;       2つの領域を指定したサイズで比べる
; param : ax : 入力された文字列を格納するバッファのアドレス
;              オーバーフロー注意
; return: axのさすアドレスに文字列を入れて返す
;********************************
one_line_editor:

    push cx
    push es
    push ds
    push si
    push di

    push ax
    mov ax, bx
    mov ds, ax
    mov es, ax
    pop ax

    ; バッファのクリア
    mov bx, ax
    mov di, bx
    mov al, 0x00
    mov cx, 128
    rep stosb

    ; 比較用バッファのクリア
    mov bx, _s_cmp_buf
    mov di, bx
    mov al, 0x00
    mov cx, 128
    rep stosb
    

    ; カーソル位置を取得
    call far [get_cursor_pos_ptr]
    

    ; 位置情報を初期化
    mov byte [_b_pos], 0x00
    mov byte [_b_len], 0x00
    mov byte [_b_x], al
    mov byte [_b_y], ah


    ; ディティネーションをセット
    mov bx, _s_one_line_buf
    mov di, bx

._loop:

    ; キー入力待ち
    mov ah, 0x00
    int 0x16  ; キー入力を待つ

    ; ←キー
    cmp ah, 0x4B
    jne ._skip1
    mov byte al, [_b_pos]
    cmp al, 0x00
    je ._loop

    dec di
    dec byte [_b_pos]
    mov al, [_b_pos]
    mov ah, [_b_y]
    call far [set_cursor_pos_ptr]
    jmp ._loop
    
._skip1:

    ; →キー
    cmp ah, 0x4D
    jne ._skip4
    ;push ax
    ;mov ax, _s_one_line_buf
    ;mov bx, es
    ;call far [str_len_ptr]
    ;;mov byte [_b_len], cx
    ;pop ax
    cmp bl, [_b_pos]
    jle ._loop
    
    inc di
    inc byte [_b_pos]
    mov al, [_b_pos]
    mov ah, [_b_y]
    call far [set_cursor_pos_ptr]
    jmp ._loop

._skip4:

    ;
    ;   単なる改行
    ;
    cmp al, 0x0d  ;
    je ._end_of_line

    ;
    ;   空白未満は何もしない
    ;
    cmp al, 0x20  ;
    js ._loop

    ;
    ;   ８ビットコードは何もしない
    ;
    cmp al, 0x7F
    jge ._loop
    
    
._skip:

    ;
    ;   表示可能文字
    ;

    inc byte [_b_pos]
    mov byte [di], al
    inc di
    mov ah, 0x0E
    int 0x10
    
    jmp ._loop

._end_of_line:

._skip2:
    
    mov si, _s_one_line_buf
    mov al, [si]
    cmp al, 0x00
    je ._skip3
    call far [disp_nl_ptr]

    
._skip3:

    mov ax, _s_one_line_buf
    mov bx, es
    
    pop di
    pop si
    pop ds
    pop es
    pop cx

    retf

one_line_editor_ptr:
    one_line_editor_off : dw 0x01f8
    one_line_editor_seg : dw 0x9000


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
    
    retf

ucase_ptr:
    ucase_off : dw 0x02aa
    ucase_seg : dw 0x9000


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
    
    retf

lcase_ptr:
    lcase_off : dw 0x02cf
    lcase_seg : dw 0x9000


;********************************
; str_cmp
;       文字列を比較する
; param : ax, bx, cx
; return: dx
;********************************
str_cmp:
    push ax
    push bx
    push cx
    push si
    push di
    
    mov ds, cx
    push ds
    pop es
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
    pop cx
    pop bx
    pop ax
    
    retf

str_cmp_ptr:
    str_cmp_off : dw 0x02f4
    str_cmp_seg : dw 0x9000

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

    ; バッファの初期化
    push ax
    mov cx, 128
    mov di, ax
    mov al, 0
    rep stosb
    pop ax

    mov di, ax
    push ax

._loop:
    ; キー入力待ち
    mov ah, 0x00
    int 0x16

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
    pop ax
    
    ;mov si, _s_one_line_buf
    mov si, ax
    mov cl, [si]
    cmp cl, 0x00
    je ._skip3
    call far [disp_nl_ptr]

    
._skip3:
    ;mov ax, _s_one_line_buf
    mov bx, es

    pop es
    pop ds
    pop cx


    retf

line_input_ptr:
    line_input_off : dw 0x0319
    line_input_seg : dw 0x9000


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

main2_ptr:
    main2_off : dw 0x2600
    main2_seg : dw 0x8000

main_ptr:
    main_off : dw 0x0000
    main_seg : dw 0x8000




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

; -------------------------------
; セクション終端
; -------------------------------
times 2048 - ($ - $$) -2 db 0
dw 0xAA55

