;>===========================
;> 	サブルーチン
;>===========================

;********************************
; set_mem
;       fill mem.
; param : ax : addr of mem where value will be set.
;         bl : value to be set.
;         cx : size to be set.
;********************************
fill_mem:
    push cx
    push si
    push bx
    push dx

    mov si, ax
    mov dx, cx

._loop:
    mov byte [si], bl
    inc si
    dec dx
    or dx, dx
    jne ._loop

._loop_end:
    pop dx
    pop bx
    pop si
    pop cx

    ret

;********************************
; copy_mem
;       copy from mem to mem.
; param : ax : addr of mem where to-value will be set.
;         bx : addr of mem where from-value is set.
;         cx : copy size.
;********************************
copy_mem:

    call set_mem

    ret

;********************************
; cmp_mem
;       2つの領域を指定したサイズで比べる
; param : ax : 1つ目のエリアのアドレス
;         bx : 2つ目のエリアのアドレス
;         cx : 比較するサイズ
; return: dl : 一致したら0、異なっていたら1が返る
;********************************
cmp_mem:
    push ax
    push bx
    push cx

    mov si, ax
    mov di, bx
    mov dx, cx

    mov bx, 0x000

._loop:
    or dx, 0
    je ._success

    mov al, [si]
    mov bl, [di]

    cmp al, bl
    jne ._fail

    inc si
    inc di
    dec dx
    inc bx

    jmp ._loop

._loop_end: 

._success:
    mov dl, 0
    jmp ._exit

._fail:
    mov dh, bl
    mov dl, 1

._exit:
    pop cx
    pop bx
    pop ax

    ret



    mov ax, [_w_cx]
    cmp cx, [_w_cx]
    je ._e

    mov byte al, [bx]
    cmp [si], al
    jne ._ne

    inc si
    inc bx
    inc cx
    jmp ._loop

._ne:
    mov dl, 1
    jmp ._end

._e:
    mov dl, 0

._end:
    pop cx
    pop bx
    pop ax
    ret

;********************************
; get_mem
;       get mem.
; param : ax : 取り出した内容を設定するエリアのアドレス
;         bx : 対象のメモリのアドレス
;         cx : 取り出すサイズ
;********************************
get_mem:
    
    call set_mem

    ret


;********************************
; set_mem
;       get mem.
; param : ax : 値を設定するエリアのアドレス
;         bx : 設定する内容のエリアのアドレス
;         cx : 設定するサイズ
;********************************
set_mem:

    push ax
    push bx
    push dx
    
    mov si, ax
    mov di, bx
    mov dx, cx

._loop:
    or dx, dx
    je ._exit
    mov al, [si]
    mov [di], al
    inc si
    inc di
    dec dx
    jmp ._loop

._exit:

    pop dx
    pop bx
    pop ax
    
    ret


;********************************
; hex_bin
;   alに設定された16進文字をバイナリに変換してalに返す
;   0～9、A～F以外が指定されると0とみなされる
;   2桁でなく1桁を指定すると後続に0が指定されたとみなされる。恐らく。
;********************************
hex_bin:
; in ax
; out al
    push bx
    push cx

    mov bx, ax

    mov al,  bh
    call hex_nibble
    mov ch, al

    mov al, bl
    call hex_nibble
    mov cl, 0x00
    mov cl, al
    mov al, cl

    mov ah, ch
    mov al, cl
    add cl, ch
    mov ah, 0x00
    mov al, cl

    pop cx
    pop bx

    ret


;********************************
; hex_nibble
;    alに指定された0～9、A～Fの文字をバイナリに変換してalに返す
;    範囲外が指定されると0を返す。
;    2桁指定されると、恐らく下位の位が変換されて返る。
;********************************
hex_nibble:
    cmp al, 0x30
    jl ._ng
    cmp al, 0x3a
    jl ._ok_0_9
    cmp al, 0x41
    jl ._ng
    cmp al, 0x47
    jl ._ok_A_F
    cmp al, 0x61
    jl ._ng
    cmp al, 0x67
    jl ._ok_a_f
._ng:
    mov al, 0x00
    jmp ._exit

._ok_0_9:
    sub al, 0x30
    jmp ._exit

._ok_A_F:
    sub al, 0x37
    jmp ._exit

._ok_a_f:
    sub al, 0x57
    jmp ._exit

._exit:

    ret


;********************************
; hex_str_bin
;    axで指定されたアドレスにある16進文字列をbyteに変換し同じアドレス移送して返す
;    変換できるのは結果が255バイトまで？
;********************************
hex_str_bin:

    push si
    push cx
    push dx
    push word [_w_ax]
    
    mov si, ax
    mov [_w_ax], ax
    mov bx, ._s_buf
    mov cx, 0x0000

._loop:
    mov dx, 0x0000
    lodsb

    cmp al, 0x30
    jl ._loop_end

    call hex_nibble
    mov dh, al

    lodsb

    call hex_nibble
    mov dl, al

    sal dh, 4
    add dl, dh
    mov al, dl

    mov [bx], al

    inc bx
    inc cx

    jne ._loop

._loop_end:

    mov ax, [_w_ax]
    mov bx, ._s_buf
    mov cx, cx
    call copy_mem

    mov bx, cx

    pop word [_w_ax]
    pop dx
    pop cx
    pop si

    ret

._s_buf: times 256 db 0x00


;********************************
; dec_bin
;    alで指定された1文字をbyteに変換してalに返す
;    範囲外は無視なんだろうなぁ
;********************************
dec_bin:
    push bx
    
    mov bl, 0x00
    
    cmp al, 0x30
    jl ._under
    
    cmp al, 0x3a
    jg ._over

    sub al, 0x30
    mov bl, al


;    jmp ._exit
    
._under:
._over:
._exit:
    mov al, bl

    pop bx
    
    ret

;********************************
; dec_str_bin
;    axで指定されたアドレスにある10進文字列をbyteに変換してbxに返す
;    65535までしか変換できない
;********************************
dec_str_bin:

    push ax
    push cx

    mov si, ax
    mov bx, 0x0000    
    mov cx, 0x0000    

._loop:
    lodsb
    or al, al
    je ._loop_end

    call dec_bin
    mov ah, 0x00
    
    mov cx, bx
    sal bx, 3
    add bx, cx
    add bx, cx
    
    add bx, ax
    jmp ._loop

._loop_end:
    
    pop cx
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
    push bx
    push cx
    
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
    
    
    ;mov ax, ._s_dummy
    ;call disp_str
    
    pop cx
    pop bx
    pop ax
    
    ret

._s_dummy: db 'debug print', 0x0d, 0x0a, 0x00

;>===========================
;>  ユーティリティ
;>===========================
;********************************
; debug_print
;********************************
debug_print:
    push ax
    push bx

    mov ax, ._s_debug
    call disp_str

    pop bx
    pop ax

    ret

._s_debug:
    db 'I HAVE COME THIS FAR. by Sun Wukong.', 0x0d, 0x0a, 0


;********************************
; disp_dec
;      1ワードの数値を10進で表示する
; param  : ax : 表示したい数値
;********************************
disp_dec:
    push ax
    push bx

    mov bx, 0
    mov si, ._buf
    add si, 3

._loop:
    mov dx, 0
    mov bx, 10
    div bx
    mov bx, ax
    mov al, dl
    add al, 0x30
    mov [si], al
    inc si
    mov ax, bx
    cmp bx, 0
    jne ._loop
    dec si
    std
    mov ax, si
    call disp_str
    cld

    pop bx
    pop ax

    ret

._buf db 0x00, 0x0a, 0x0d
    times 12 db 0

;********************************
; disp_mem
;       指定された領域を16進で指定したサイズ表示する
; param : ax : 表示する領域のアドレス
;         bx : 表示するサイズ
;********************************
disp_mem:

    push ax
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
    pop ax

._end:

    call disp_nl
      
    ret


;********************************
; バイナリ列を表示可能Asciiに変換する
; ax→ax
; 表示可能な文字は変換せず、不可な文字を「.」に変換する
;********************************
bin_strm_ascii:

    mov di, ._s_buf
    mov si, ax
    
._loop:
    lodsb
    or al, al
    je ._loop_end

    mov al, [si]
    call bin_byte_ascii
    
    mov [di], al
    
    jmp ._loop

._loop_end:



ret

    ._s_buf: times 256 db 0x00


;********************************
; 1ByteバイナリをAsciiに変換する
; al→al
; 表示可能な文字は変換せず、不可な文字を「.」に変換する
;********************************
bin_byte_ascii:

    push bx
    
    mov bl, 0x00

    cmp al, 0x20
    jl ._under
    
    cmp al, 0x7e
    jg ._over

    jmp ._exit

._under:
._over:
    mov al, 0x2e

._exit:
    ;mov al, bl

    pop bx

    ret

;********************************
; one_line_editer
;       2つの領域を指定したサイズで比べる
; param : ax : 入力された文字列を格納するバッファのアドレス
;              オーバーフロー注意
; return: axのさすアドレスに文字列を入れて返す
;********************************
one_line_editer:

    push bx

    mov ax, _c_seg
    mov ds, ax
    mov es, ax

    ; バッファのクリア
    mov bx, _s_one_line_buf
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
    call get_cursor_pos
    
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
    call set_cursor_pos
    jmp ._loop
    
._skip1:

    ; →キー
    cmp ah, 0x4D
    jne ._skip4
    push ax
    mov ax, _s_one_line_buf
    call str_len
    ;mov byte [_b_len], bx
    pop ax
    cmp bl, [_b_pos]
    jle ._loop
    
    inc di
    inc byte [_b_pos]
    mov al, [_b_pos]
    mov ah, [_b_y]
    call set_cursor_pos
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
    
    mov bx, _s_one_line_buf
    mov byte al, [bx]
    cmp al, 0x00
    je ._skip3
    call disp_nl

    
._skip3:
    pop bx
    mov ax, _s_one_line_buf
    
    ret

._s_dummy: db 'dummy string', 0x0d, 0x0a, 0x00


;>===========================
;>  サンプル
;>===========================
;****************************
; get_str_ascii
;   キーボードから文字列を取り込んでアドレスをaxに返す
;****************************
get_str_ascii:

    push si
    push bx

    mov [._w_buf_addr], ax
    mov si, ax

._loop:

    call enh_get_kb_sts
    or bx, bx
    jne ._loop

    call enh_get_key
    mov bx, ax
    cmp bl, 0x20
    jg ._add_b
    cmp bx, 0x1c0a
    je ._exit
    cmp bx, 0x1c00
    je ._exit
    cmp bl, 0x0d
    je ._exit 


    cmp si, [._w_buf_addr]
    je ._loop

._add_b:
    mov ax, bx
    mov ah, 0x0e
    int 0x10
    mov [si], al
    inc si
    jmp ._loop

._exit:
    mov byte [si], 0x0d
    inc si
    mov byte [si], 0x0a
    inc si
    mov byte [si], 0x00
    call disp_nl

    mov ax, [._w_buf_addr]

    pop bx
    pop si

    ret


._buf db 0x00

._w_buf_addr: dw 0x0000


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
    js _hlt

    ; リアルモードからの制御を宣言（これ、もしかしたらリアルモードへの変更かも）
    mov ax, 0x5301
    mov bx, 0
    int 0x15

    ; APM-BIOS ver 1.1を有効化
    mov ax, 0x530e
    mov bx, 0
    mov cx, 0x0101
    int 0x15
    jc _hlt

    ; 全デバイスのAPM設定を連動させる
    mov ax, 0x530f
    mov bx, 0x0001
    mov cx, 0x0001
    int 0x15
    jc _hlt

    ; 全デバイスのAPM機能有効化
    mov ax, 0x5308
    mov bx, 0x0001
    mov cx, 0x0001
    int 0x15
    jc _hlt

    ; 電源OFF
    mov ax, 0x5307
    mov bx, 0x0001
    mov cx, 0x0003
    int 0x15

    jmp _hlt

    ret


;********************************
; print
;       文字を表示する
; param : ax : 文字列を格納したバッファのアドレス
;              とりあえず使えそう？
; return: 
;********************************
print:
    push ax
    push bx
    push cx
    
    mov si, ax
    
    call get_cursor_pos

    mov bx, ax
    mov al, ah
    mov ah, 0x00
    mov cx, 160
    mul cx
    mov dl, bh
    add ah, dh
    mov di, ax

    mov ax, 0xb800      ; VGAテキストビデオメモリ
    mov es, ax

    mov ah, 0x07        ; 属性：黒背景・明るい灰色文字

._loop:
    lodsb
    or al, al
    jz ._exit
    stosw             ; AX → ES:DI（1文字分：文字＋属性）
    loop ._loop

._exit:
    call disp_nl

    pop cx
    pop bx
    pop ax

    ret


;********************************
; exit
;       電源を落とす
; param : 
; return: 
;********************************
exit:
    ; 処理終了
    call disp_nl
    call disp_nl
    mov ax, ._s_msg
    call disp_str
    call get_key
    call power_off

    ret
._s_msg: db 'hit any key to power off', 0x0d, 0x0a, 0x00



