;>>===========================
;>>	Bootで遊ぼっ！
;>>===========================

section .data

	_c_seg          equ 0x07c0
	_c_ex_area_addr equ 0x200

	_c_true         equ '1'
	_c_false        equ '0'


section .text

boot:
	; set segment register
        mov ax, _c_seg
        mov ds, ax

    ; テストして終了なら[m_isTest]にDEF_TRUEを設定する
    ; テストせず通常の処理をするなら[m_isTest]にDEF_FALSEを設定する
    ;
    mov byte [_m_isTest], _c_true
    ;mov byte [_m_isTest], _c_false

    mov ah, 0x0e
    ;
    ; disk read
    ;     read to es:bx
    ;
    mov ax, _c_seg
    mov es, ax
    mov bx, _c_ex_area_addr

    mov ah, 0x02 ; Read Sectors From Drive
    mov dl, 0x80 ; Drive
    mov al, 0x20 ; Sectors To Read Count ;
    mov ch, 0x00 ; Cylinder
    mov cl, 0x02 ; Sector(starts from 1, not 0) ; set 2. becouse not need MBR
    mov dh, 0x00 ; Head

    int 0x13     ; Execute disk read


	jmp main

;>>===========================
;>>  実験
;>>===========================

;>>****************************
;>> hlt
;>>****************************
_hlt:
	hlt
	jmp _hlt


_m_isTest:       db 0



;>>****************************
;>> ブートローダパディング
;>>****************************


times 510-($-$$) db 0

;********************************
; ブートセクタシグネチャ
;********************************

db 0x55
db 0xAA

;********************************
; definition of variables
;********************************

_s_crlf:       db 0x0d, 0x0a, 0x00

_m_buf_str:
	times 128 db 0 
    ;db 0, 10, 13, '                             '

_m_rt_sts:
    db 0

_m_ax:
_m_al:
    db 0
_m_ah:
    db 0

_m_bx:
_m_bl:
    db 0
_m_bh:
    db 0

_m_cx:
_m_cl:
    db 0
_m_ch:
    db 0

_m_dx:
_m_dl:
    db 0
_m_dh:
    db 0

_m_x:
_m_xl:
    db 0
_m_xh:
    db 0
_m_y:
_m_yl:
    db 0
_m_yh:
    db 0




;********************************
; definition of strings
;********************************

_s_true:    db 'TRUE ', 13, 10, 0

_s_false:   db 'FALSE', 13, 10, 0



section .text

;>>===========================
;>> 	サブルーチン
;>>===========================

;********************************
; nibble_hex
;       4bit整数を16進文字に変換する
;       0～15 -> '0'～'f'
; param  : al : 変換する数値
;               16以上を指定すると上位ニブルは無視され、下位ニブルが変換されて返る
;                 e.g. 0x21 -> '1'
; return : al : 変換された文字
;******************************
nibble_hex:

        and al, 0x0f

        cmp al, 0x09
        ja .gt_9

        add al, 0x30
        jmp .cnv_end

.gt_9:
        add al, 0x37

.cnv_end:

        ret


;
; jmpもcmpも美しくない。というわけでこんなの書いてみました。
;
nibble_hex2:

    push bx


    and al, 0x0f
    mov bx, 0
    mov bl, al
    sub bx, 10
    mov bl, bh

    sar bl, 7
    not bl

    and bl, 7

    add al, bl
    add ax, 0x30

    pop bx

    ret


;********************************
; byte_hex
;       1バイトの数値を16進文字列に変換する
; param  : al : 変換したい数値
; return : bx : 変換した2文字の16進文字
;********************************
byte_hex:
    push ax
    push cx

    mov cl, al
    and al, 0x0f
    mov ah, 0
    call nibble_hex
    mov bh, al

    mov al, cl
    shr al, 4
    mov ah, 0
    call nibble_hex
    mov bl, al

    pop cx
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

    call byte_hex

    mov ah, 0x0e
    mov al, bl
    int 0x10
    mov al, bh
    int 0x10

    pop bx
    pop ax

    ret


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

._loop
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
; byte_hex_mem
;      バイトデータを16進文字に変換してメモリに設定する
; param  : al : 16進文字に変換するバイトデータ
;          bx : 変換した16進文字を設定するメモリのアドレス
;********************************
byte_hex_mem:
        push bx
    push cx
    push word [_m_bx]
    mov word [_m_bx], bx

    call byte_hex
    mov cx, bx

    mov word bx, [_m_bx]
    mov byte [bx], cl
    add bx, 1
    mov byte [bx], ch

    pop word [_m_bx]
    pop cx
    pop bx

    ret


;********************************
; disp_str
;       display null-terminated string.
; param : ax : addr of mem where string is set.
;********************************
disp_str:

    push ax
    push si

    mov si, ax
;        cld
    mov ah, 0x0E

._loop:
    lodsb

    or al, al
    jz ._loop_end

    int 0x10

    jmp ._loop

._loop_end:

    pop si
    pop ax

    ret


;********************************
; mem_set
;       set mem.
; param : ax : addr of mem where value will be set.
;         bl : value to be set.
;         cx : size to be set.
;********************************
mem_set:
    push cx
    push si
    push word [_m_cx]
    push bx
    push dx

    mov word [_m_cx], cx

    mov si, ax
    mov cx, 0

._value_set_loop:
    mov byte [si], bl
    inc si
    inc cx

    mov dx, cx
    cmp dx, [_m_cx]
    jne ._value_set_loop

    pop dx
    pop bx
    pop word [_m_cx]
    pop si
    pop cx

    ret


;********************************
; mem_cpy
;       copy from mem to mem.
; param : ax : addr of mem where to-value will be set.
;         bx : addr of mem where from-value is set.
;         cx : copy size.
;********************************
mem_cpy:
    push bx
    push cx
    push dx
    push word [_m_bx]
    push word [_m_cx]
    push si

    mov word [_m_bx], bx
    mov word [_m_cx], cx

    mov cx, 0
    mov si, ax

._copy_loop:
    mov byte dh, [bx]
    mov [si], dh

    inc si
    inc bx
    inc cx

    cmp cx, [_m_cx]
    jb ._copy_loop

    pop si
    pop word [_m_cx]
    pop word [_m_bx]
    pop dx
    pop cx
    pop bx

    ret


;********************************
; mem_cmp
;       2つの領域を指定したサイズで比べる
; param : ax : 1つ目のエリアのアドレス
;         bx : 2つ目のエリアのアドレス
;         cx : 比較するサイズ
; return: dl : 一致したら0、異なっていたら1が返る
;********************************
mem_cmp:
    mov dl, 0

    push ax
    push bx
    push cx
    push si
    push word [_m_cx]


    mov [_m_cx], cx
    mov cx, 0
    mov si, ax

._loop:

    mov ax, [_m_cx]
    cmp cx, [_m_cx]
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
    pop word [_m_cx]
    pop si
    pop cx
    pop bx
    pop ax

    ret


;********************************
; mem_dsp
;       指定された領域を16進で指定したサイズ表示する
; param : ax : 表示する領域のアドレス
;         bx : 表示するサイズ
;********************************
mem_dsp:

    push ax
    push cx
    push si

    cmp bx, 0
    je ._end

    mov cx, 0
    mov si, ax

._loop:
    mov byte al, [si]
    call disp_byte_hex
    inc si
    inc cx
    cmp cx, bx
    jb ._loop


    pop si
    pop cx
    pop ax

._end:
        
    ret


;********************************
; str_len
;       ゼロターミネートされた文字列の長さを求める
; param   : ax : 文字列のアドレス
; returen ; bx : 文字列の長さ
;********************************
str_len:

    push si

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

    ret

;********************************
; get_key
;       キー入力待ちして、押下されたキーコードとアスキーコードを返す
;	（未確認だけどアスキーコードがないキーを押されるとアスキーコードに0x00が返るんじゃないかな）
; returen ; ah : キーコード
;           al : アスキーコード
;********************************
get_key:
	

    mov ah, 0x00
    int 0x16


    mov bx, ax


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


;>>===========================
;>> テスト
;>>===========================
_test_codes:

;>>===========================
;>> 個別テスト
;>>===========================

;********************************
; test_disp_str
;      disp_strのテスト
; param  : ax : 表示する文字列のアドレス（ゼロターミネート）
;********************************
test_disp_str:

    ; 開始メッセージ表示
    mov ax, ._start_msg
    call disp_str

    ; テスト実行
    mov ax, ._test_data 
    call disp_str


    ; 改行の調整
    ;mov ax, _s_crlf
    mov ax, _s_crlf
    call disp_str

	ret


._start_msg:
    db 0x0d, 0x0a
    db '****************************', 0x0d, 0x0a
    db 'TARGET : disp_str ', 0x0d, 0x0a
    db '  SUCCESS : display', 0x0d, 0x0a
    db '              "TRUE', 0x0d, 0x0a
    db '               FALSE"', 0x0d, 0x0a
    db '****************************', 0x0d, 0x0a
    db 0x0d, 0x0a, 0


._test_data:
    db 'TRUE', 0x0d, 0x0a, 'FALSE',  0x00, 'FALSE', 0x0d, 0x0a, 'TRUE', 0x00 


;********************************
; test_disp_byte_hex
;      disp_byte_hexのテスト
; param  : al : 表示したい数値
;********************************
test_disp_byte_hex:

    ; 開始メッセージ表示
    mov ax, ._start_msg
    call disp_str

    ; テスト実行
    mov al, 0x01
    call disp_byte_hex

    mov al, 0x09
    call disp_byte_hex

    mov al, 0x0a
    call disp_byte_hex

    mov al, 0x0f
    call disp_byte_hex

    mov al, 0x10
    call disp_byte_hex

    mov al, 0x90
    call disp_byte_hex

    mov al, 0xa0
    call disp_byte_hex

    mov al, 0xf0
    call disp_byte_hex

    mov al, 0xf1
    call disp_byte_hex

    mov al, 0xa9
    call disp_byte_hex

    mov al, 0x9a
    call disp_byte_hex

    mov al, 0x1f
    call disp_byte_hex


    ; 改行の調整
    mov ax, _s_crlf
    call disp_str

	ret


._start_msg:
    db 0x0d, 0x0a
    db '***********************************************', 0x0d, 0x0a
    db 'TARGET : disp_byte_hex', 0x0d, 0x0a
    db '  SUCCESS : display "01090A0F1090A0F0F1A99A1F"', 0x0d, 0x0a
    db '***********************************************', 0x0d, 0x0a
    db 0x0d, 0x0a, 0


;********************************
; test_byte_hex_mem
;      byte_hex_memのテスト
; param  : al : 16進文字に変換するバイト
;          bx : 変換した文字列を設定するアドレス
;********************************
test_byte_hex_mem:

    ; 開始メッセージ表示
    mov ax, ._s_start_msg1
    call disp_str

    mov ax, ._s_expected_result
    call disp_str

    mov ax, ._s_start_msg2
    call disp_str

    ; テスト実行
    mov al, 0xf0
    mov bx, ._s_test_result
    call byte_hex_mem

    mov al, 0xa0
    add bx, 2
    call byte_hex_mem

    mov al, 0x90
    add bx, 2
    call byte_hex_mem

    mov al, 0x10
    add bx, 2
    call byte_hex_mem

    mov al, 0x1f
    add bx, 2
    call byte_hex_mem

    mov al, 0x9a
    add bx, 2
    call byte_hex_mem

    mov al, 0xa9
    add bx, 2
    call byte_hex_mem

    mov al, 0xf1
    add bx, 2
    call byte_hex_mem

    mov al, 0x0f
    add bx, 2
    call byte_hex_mem

    mov al, 0x0a
    add bx, 2
    call byte_hex_mem

    mov al, 0x09
    add bx, 2
    call byte_hex_mem

    mov al, 0x01
    add bx, 2
    call byte_hex_mem


    ;mov ax, ._s_test_result
    ;call disp_str


    ; 改行の調整
    ;mov ax, _c_crlf
    ;call disp_str
    ;call disp_str


    ; メッセージ表示
    mov ax,	._s_result_msg1
    call disp_str

    mov ax, ._s_expected_result
    call disp_str

    mov ax, _s_crlf
    call disp_str

    mov ax, ._s_result_msg2
    call disp_str  

    mov ax, ._s_test_result
    call disp_str

    mov ax, _s_crlf
    call disp_str
    call disp_str


    ; 結果の確認

    mov ax, ._s_expected_result 
    mov bx, ._s_test_result
    mov cx, 0
._loop:
    add ax, cx
    add bx, cx
    mov cx, 0x01

    push bx
    push dx

    mov dx, [bx]
    mov [_m_x], dx

    mov bx, ax
    mov dx, [bx]

    cmp [_m_x], dl
    jne ._test_fail

    pop dx
    pop bx

    cmp byte [_m_x], 0x00
    je ._test_success

    jmp ._loop

._test_fail:
    mov ax, ._s_fail_msg
    call disp_str
    jmp ._end

._test_success:
    mov ax, ._s_success_msg
    call disp_str

._end:

    mov ax, _s_crlf
    call disp_str

	ret


._s_start_msg1:
    db 0x0d, 0x0a
    db '***********************************************', 0x0d, 0x0a
    db 'TARGET : byte_hex2mem', 0x0d, 0x0a
    db '  SUCCESS : display "', 0x00

._s_start_msg2:
    db '"', 0x0d, 0x0a
    db '***********************************************', 0x0d, 0x0a
    db 0x0d, 0x0a, 0

._s_test_result:
    times 30 db 0

._s_expected_result:
    db 'F0A090101F9AA9F10F0A0901', 0x00

._s_fail_msg:
    db 'fail', 0x00

._s_success_msg:
    db 'SUCCESS !! ', 0x00

    ._s_result_msg1:
    db 'Expected result : ', 0x00

._s_result_msg2:
    db 'Test     result : ', 0x00


;********************************
; test_mem_set
;       memsetのテスト
; param : ax : 値をセットするエリアのアドレス
;         bl : セットする値
;         cx : セットするサイズ
;********************************
test_mem_set:

    ; 開始メッセージ表示
    mov ax, ._s_start_msg1
    call disp_str

    mov ax, ._s_start_msg2
    call disp_str
    mov ax, ._s_before
    call disp_str
    mov ax, _s_crlf
    call disp_str

    mov ax, ._s_start_msg3
    call disp_str
    mov ax, ._s_after
    call disp_str
    mov ax, _s_crlf
    call disp_str


    mov ax, ._s_start_msg4
    call disp_str

    ; 実行前のエリア内容を表示
    mov ax, ._s_start_msg2
    call disp_str
    mov bx, ._m_test_area
    mov cx, ._m_test_area
    mov ax,  [._b_area_size] 
    mov ah, 0
    add cx, ax
._before_loop:
    mov dx, [bx]
    mov al, dl
    call disp_byte_hex
    add bx, 1

    cmp bx, cx
    jbe ._before_loop

    mov ax, _s_crlf
    call disp_str

    ; 実行
    mov ax, ._m_test_area
    mov bl, 0
    ;mov cx, _siz[._b_area_size]
    mov cx, ._size
    call mem_set

    ; 実行後のエリア内容を表示
    mov ax, ._s_start_msg3
    call disp_str
    mov bx, ._m_test_area
    mov cx, ._m_test_area
    ;mov ax,  [._b_area_size]
    mov ax,  ._size
    mov ah, 0
    add cx, ax
._after_loop:
    mov dx, [bx]
    mov al, dl
    call disp_byte_hex
    add bx, 1

    cmp bx, cx
    jbe ._after_loop



    ; 結果の確認

    mov ax, ._m_expected_result
    mov bx, ._m_test_area
    mov cx, ._size
    call mem_cmp
    cmp dl, 0x00
    jne ._test_fail


    jmp ._test_success


._test_fail:
    mov ax, _s_crlf
    call disp_str
    call disp_str

    mov ax, ._s_fail_msg
    call disp_str
    jmp ._end

._test_success:
    mov ax, _s_crlf
    call disp_str
    call disp_str

    mov ax, ._s_success_msg
    call disp_str

._end:

    mov ax, _s_crlf
    call disp_str

	ret

._s_start_msg1:
    db 0x0d, 0x0a
    db '***************************************', 0x0d, 0x0a
    db 'TARGET : memset', 0x0d, 0x0a
    db '  SUCCESS  ', 0x0d, 0x0a, 0x00

._s_start_msg2:
    db '    before : ', 0x00

._s_start_msg3:
    db '    after  : ', 0x00

._s_start_msg4:
    db '***************************************', 0x0d, 0x0a
    db 0x0d, 0x0a, 0

._s_before: db '0102030405060708090A0B0C', 0x00
._s_after: db  '00000000000000000000000C', 0x00

._b_area_size: db 11

._s_fail_msg:
    db 'fail', 0x00

._s_success_msg:
    db 'SUCCESS !! ', 0x00

._size equ 11 

._m_expected_result: times 11 db 0x00
		db 0x0c, 0x00

._m_test_area: db 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x00


;********************************
; test_memcpy
;       memcpyのテスト
; param : ax : コピー先のアドレス
;         bx : コピー元のアドレス
;         cx : こぷーするサイズ
;********************************
test_mem_cpy:


    ; 開始メッセージ表示
    mov ax, ._s_start_msg1
    call disp_str

    mov ax, ._s_start_msg2
    call disp_str
    mov ax, ._s_source
    call disp_str
    mov ax, _s_crlf
    call disp_str

    mov ax, ._s_start_msg3
    call disp_str
    mov ax, ._s_before
    call disp_str
    mov ax, _s_crlf
    call disp_str

    mov ax, ._s_start_msg4
    call disp_str
    mov ax, ._s_after
    call disp_str
    mov ax, _s_crlf
    call disp_str

    mov ax, ._s_start_msg5
    call disp_str



    ;コピー元のエリア内容を表示
    mov ax, ._s_start_msg2
    call disp_str
    mov bx, ._m_source
    mov cx, ._m_source
    mov ax,  [._w_area_size]
    add cx, ax
._source_loop:
    mov dx, [bx]
    mov al, dl
    call disp_byte_hex
    add bx, 1

    cmp bx, cx
    jbe ._source_loop

    mov ax, _s_crlf
    call disp_str


    ; 実行前のエリア内容を表示
    mov ax, ._s_start_msg3
    call disp_str
    mov bx, ._m_test_area
    mov cx, ._m_test_area
    mov ax,  [._w_area_size]
    add cx, ax
._before_loop:
    mov dx, [bx]
    mov al, dl
    call disp_byte_hex
    add bx, 1

    cmp bx, cx
    jbe ._before_loop

    mov ax, _s_crlf
    call disp_str


    ; 実行
mov ax, [._w_area_size]
    mov ah, 0
    mov cx, ax
    mov ax, ._m_test_area
    mov bx, ._m_source
    call mem_cpy


    ; 実行後のエリア内容を表示
    mov ax, ._s_start_msg4
    call disp_str
    mov bx, ._m_test_area
    mov cx, ._m_test_area
    mov ax,  [._w_area_size]
    add cx, ax
._after_loop:
    mov dx, [bx]
    mov al, dl
    call disp_byte_hex
    add bx, 1

    cmp bx, cx
    jbe ._after_loop

    mov ax, _s_crlf
    call disp_str


    ; 結果の確認
    mov ax, ._m_expected_result
    mov bx, ._m_test_area
    mov cx,  [._w_area_size]
    call mem_cmp
    jne ._test_fail

    jmp ._test_success


._test_fail:

    mov ax, _s_crlf
    call disp_str
    call disp_str

    mov ax, ._s_fail_msg
    call disp_str
    jmp ._end

._test_success:
    mov ax, _s_crlf
    call disp_str
    call disp_str

    mov ax, ._s_success_msg
    call disp_str

._end:

    mov ax, _s_crlf
    call disp_str


    ret


._s_start_msg1:
    db 0x0d, 0x0a
    db '***************************************', 0x0d, 0x0a
    db 'TARGET : mem_cpy', 0x0d, 0x0a
    db '  SUCCESS  ', 0x0d, 0x0a, 0x00

._s_start_msg2:
    db '    source : ', 0x00


._s_start_msg3:
    db '    before : ', 0x00

._s_start_msg4:
    db '    after  : ', 0x00

._s_start_msg5:
    db '***************************************', 0x0d, 0x0a
    db 0x0d, 0x0a, 0

._s_source: db '0C0B0A090807060504030201', 0x00
._s_before: db '0102030405060708090A0B0C', 0x00
._s_after:  db '0C0B0A09080706050403020C', 0x00

._w_area_size: db 11,0  

._s_fail_msg:
    db 'fail', 0x00

._s_success_msg:
    db 'SUCCESS !! ', 0x00

._m_expected_result:    db 0x0C, 0x0B, 0x0A, 0x09, 0x08, 0x07, 0x06, 0x05, 0x04, 0x03, 0x02, 0x0C, 0x00

._m_source:    db 0x0C, 0x0B, 0x0A, 0x09, 0x08, 0x07, 0x06, 0x05, 0x04, 0x03, 0x02, 0x01, 0x00

._m_test_area: db 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x00


;********************************
; test_mem_cmp
;       memcmpのテスト
; param : ax : 比較先のアドレス
;         bx : 比較元のアドレス
;         cx : 比較するサイズ
;********************************
test_mem_cmp:
	mov dl, 0

    ; 開始メッセージ表示
    mov ax, ._s_start_msg1
    call disp_str

    mov ax, ._s_start_msg2
    call disp_str
    mov ax, ._s_destination
    call disp_str
    mov ax, _s_crlf
    call disp_str

    mov ax, ._s_start_msg3
    call disp_str
    mov ax, ._s_source
    call disp_str
    mov ax, _s_crlf
    call disp_str

    mov ax, ._s_start_msg4
    call disp_str
    mov ax, ._s_result
    call disp_str
    mov ax, _s_crlf
    call disp_str

    mov ax, ._s_start_msg5
    call disp_str


    ; テスト実行
    ; ケース１
    mov ax, ._s_size
    call disp_str

    mov ax, ._s_source
    mov bx, ._s_destination
    mov cx, [._w_case1]

    push ax
    mov al, cl
    call disp_byte_hex
    pop ax

    call mem_cmp

    mov ax, ._s_return
    call disp_str
    mov al, dl
    call disp_byte_hex
    mov ax, _s_crlf
    call disp_str

    ; ケース２
    mov ax, ._s_size
    call disp_str

    mov ax, ._s_source
    mov bx, ._s_destination
    mov cx, [._w_case2]

    push ax
    mov al, cl
    call disp_byte_hex
    pop ax

    call mem_cmp

    mov ax, ._s_return
    call disp_str
    mov al, dl
    call disp_byte_hex
    mov ax, _s_crlf
    call disp_str

	ret


._s_start_msg1:
    db 0x0d, 0x0a
    db '***************************************', 0x0d, 0x0a
    db 'TARGET : mem_cmp', 0x0d, 0x0a, 0x00

._s_start_msg2:
    db '    dst : ', 0x00


._s_start_msg3:
    db '    src : ', 0x00

._s_start_msg4:
    db '    ret : ', 0x00

._s_start_msg5:
    db '***************************************', 0x0d, 0x0a
    db 0x0d, 0x0a, 0

._s_source     : db 'Hello World!', 0x00
._s_destination: db 'Hello Universe!', 0x00
._s_result     : db '1 or 0', 0x00
._s_size: db 'Size : ', 00
._s_return: db ' return : ', 00

._w_case1: db 6,0
._w_case2: db 8,0


;********************************
; test_mem_dsp
;       mem_dspのテスト
; param : ax : 表示する領域のアドレス
;         bx : 表示するサイズ
;********************************
test_mem_dsp:

    ; 開始メッセージ表示
    mov ax, ._s_start_msg1
    call disp_str

    mov ax, ._s_start_msg2
    call disp_str

    mov ax, ._s_source
    mov bx, 12
    call mem_dsp
    mov ax, _s_crlf
    call disp_str

    mov ax, ._s_start_msg3
    call disp_str
    mov word bx, [._w_disp_size]
    mov ax, bx
    call disp_word_hex
    mov ax, _s_crlf
    call disp_str

    mov ax, ._s_start_msg4
    call disp_str

    ; テスト実行
    mov ax, ._s_source
    mov bx, 7
    call mem_dsp

    mov ax, _s_crlf
    call disp_str

    ret


._s_start_msg1:
    db 0x0d, 0x0a
    db '***************************************', 0x0d, 0x0a
    db 'TARGET : mem_dsp', 0x0d, 0x0a, 0x00

._s_start_msg2:
    db '    source : ', 0x00


._s_start_msg3:
    db '    size   : ', 0x00

._s_start_msg4:
    db '***************************************', 0x0d, 0x0a
    db 0x0d, 0x0a, 0

._s_source:    db 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x00

._w_disp_size: db 7, 0


;********************************
; test_get_key
;       getkeyのテスト
; param : なし
; retuen: ah : キーコード
;         al : アスキーコード
;********************************
test_get_key:

    mov bl, 0xff
    sal bl, 4
    mov al, bl
    call disp_byte_hex

    jmp _hlt
	
	
    mov ax, ._msg1
    call disp_str

    call get_key

    mov ax, ._msg2
    call disp_str

    mov al, bh
    call disp_byte_hex
    mov ax, _s_crlf
    call disp_str

    mov ax, ._msg3
    call disp_str

    mov al, bl
    call disp_byte_hex
    mov ax, _s_crlf
    call disp_str

    ret

._msg1
    db '*****************************', 0x0d, 0x0a
    db '   get_key ', 0x0d, 0x0a
    db '*****************************', 0x0d, 0x0a
    db 0x0d, 0x0a, 0x00

._msg2
    db 'key code   : ', 0x00

    ._msg3
    db 'ascii doce : ', 0x00


;********************************
; test_disp_dec
;      disp_decのテスト
; param  : ax : 表示する数値
;********************************
test_disp_dec:

    ; 開始メッセージ表示
    mov ax, ._start_msg
    call disp_str

    ; テスト実行
    mov ax, 0 
    call disp_dec

    mov ax, 10 
    call disp_dec

    mov ax, 0xf 
    call disp_dec

    mov ax, 0x10 
    call disp_dec

    mov ax, 0xff 
    call disp_dec

    mov ax, 0x100 
    call disp_dec

    mov ax, 0xfff 
    call disp_dec

    mov ax, 0x1000 
    call disp_dec

    mov ax, 0xffff 
    call disp_dec

    mov ax, 11 
    call disp_dec

    mov ax, 1100 
    call disp_dec

    ; 改行の調整
    mov ax, _s_crlf

ret


._start_msg:
    db 0x0d, 0x0a
    db '****************************', 0x0d, 0x0a
    db 'TARGET : disp_dec ', 0x0d, 0x0a
    db '  SUCCESS : display 0, 10, 15, 16, 255, 256, 4095, 4096, 65535, 11, 1100', 0x0d, 0x0a
    db '****************************', 0x0d, 0x0a
    db 0x0d, 0x0a, 0


._test_data:
    db 'TRUE', 0x0d, 0x0a, 'FALSE',  0x00, 'FALSE', 0x0d, 0x0a, 'TRUE', 0x00 


;>>===========================
;>> 一括テスト
;>>===========================
test_all:

    ; テスト開始メッセージの表示
	mov ax, ._start_msg
    call disp_str


    ; disp_decのテスト
    call test_disp_dec

    ; disp_strのテスト
    call test_disp_str

    ; disp_byte_hexのテスト
    call test_disp_byte_hex

    ; byte_hex_memのテスト
    call test_byte_hex_mem

    ; mem_setのテスト
    call test_mem_set

    ; mem_cpyのテスト
    call test_mem_cpy

    ; mem_dspのテスト
    call test_mem_dsp

    ; mem_cmpのテスト
    call test_mem_cmp

    jmp _hlt


._end:

    ret

._start_msg:
    db 0x0d, 0x0a, 0x0d, 0x0a
    db '########################', 0x0d, 0x0a
    db 'Currently in test mode.', 0x0d, 0x0a
    db 'Test is started', 0x0d, 0x0a
    db '########################', 0x0d, 0x0a
    db 0x0d, 0x0a, 0

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


;>>===========================
;>> main
;>>===========================

main:
    ; set segment register
    mov ax, _c_seg
    mov ds, ax

    ; テストモードならテストを実行して終了
    cmp byte [_m_isTest], _c_true
    jne ._skip_test
    call test_all
    jmp _hlt

._skip_test:

    ; ビデオモードの設定
    mov ah, 0x0
    mov al, 0x3    ; 16色テキスト、80x25
    ; mov al, 0x6a  ; 800x600x4bitカラー（ビデオカードによってはサポートされない）
    int 0x10

    ; 念のため初期化
    cld

    mov ax, ._msg
    call disp_str

    ; キー入力待ち
._loop
    call get_key

    call disp_word_hex

    cmp al, 0x00
    je ._loop

    ; 処理終了
    call power_off

._msg
    db 'Entrt any key to power off', 0x0d, 0x0a, 0x00

;==============================================================
; ファイル長の調整
;==============================================================
_padding:
    times 0x100000-($-$$) db 0

