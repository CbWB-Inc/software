;>===========================
;>      BIOSで遊ぼっ！
;>===========================

section .data

        _c_seg          equ 0x07c0
        _c_ex_area_addr equ 0x200

section .text

boot:
    ; set segment register
    mov ax, _c_seg
    mov ds, ax


    jmp main

;>****************************
;> hlt
;>****************************
_hlt:
    hlt
    jmp _hlt


;>********************************
;> definition of variables
;>********************************

    _c_seg          equ 0x07c0
    _c_ex_area_addr equ 0x200
    _s_crlf:       db 0x0d, 0x0a, 0x00

;>===========================
;>      サブルーチン
;>===========================
;********************************
; bin_nibble_hex
;       4bit整数を16進文字に変換する（下位4Bit）
;       0～15 -> '0'～'f'
; param  : al : 変換する数値
; return : bl : 変換された文字
;******************************
bin_nibble_hex:

        and al, 0x0f
        cmp al, 0x09
        ja .gt_9
        add al, 0x30
        jmp .cnv_end
.gt_9:
        add al, 0x37

.cnv_end:
        mov bl, al
        ret

;********************************
; bin_byte_hex
; param  : al : 変換したい数値
; return : bx : 変換した2文字の16進文字
;********************************
bin_byte_hex:
    push cx
    push dx

    mov cl, al
    sar al, 4
    and al, 0x0f
    mov ah, 0
    call bin_nibble_hex
    mov dh, bl

    mov al, cl
    and al, 0x0f
    mov ah, 0
    call bin_nibble_hex
    mov dl, bl

    mov bx, dx

    pop dx
    pop cx

    ret

;****************************
; disp_nl
;   改行する
;****************************
disp_nl:

    push ax

    mov ax, _s_crlf
    call disp_str

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
; disp_str
;       display null-terminated string.
; param : ax : addr of mem where string is set.
;********************************
disp_str:

    push ax
    push si

    mov si, ax
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

;>===========================
;>  サンプル
;>===========================
;****************************
; power_off
;       パワーオフ
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

;>===========================
;>  BIOSコールラッパー
;>===========================
;********************************
; get_key
;       キー入力待ちして、押下されたキーコードとアスキーコードを返す
; returen ; ah : キーコード
;           al : アスキーコード
;********************************
get_key:

    mov ah, 0x00
    int 0x16

    ret

;>===========================
;>  BIOSコール 実験コード
;>===========================
;********************************
; system_timer_count_readの確認
;********************************
exp_system_timer_count_read:

    push ax
    push bx

    mov ah, 0x00
    int 0x01a

    jnc ._cf_nomal
    ; キャリーが立っていた場合
    mov ah, 0x01
    mov [._cf], ah

._cf_nomal:
    mov [._of], al

    ;===========================
    ; CFのタイトルと内容表示
    ;===========================
    ; タイトル表示
    mov ah, 0x0e
    mov si, ._s_hdr_cf
._loop1:
    lodsb
    or al, al
    je ._loop1_end
    int 0x10
._loop1_end:

    ; CFの内容表示
    mov ah, 0x0e
    mov al, [._cf]
    call disp_byte_hex
    call disp_nl

    ; 上位1文字の表示
    sar al, 4
    cmp al, 0x09
    ja .gt9_1
    add al, 0x30
    jmp .cnv1_end
.gt9_1:
    add al, 0x37
.cnv1_end:
    mov bl, al
    int 0x10

    ; 下位1文字の表示
    mov al, [._cf]
    and al, 0x0f
    cmp al, 0x09
    ja .gt9_2
    add al, 0x30
    jmp .cnv2_end
.gt9_2:
    add al, 0x37
.cnv2_end:
    mov bl, al
    int 0x10

    ; 改行
    mov al, 0x0d
    int 0x10
    mov al, 0x0a
    int 0x10

    ; over fllow の表示
    mov ax, ._s_hdr_of
    call disp_str
    mov al, [._of]
    call disp_byte_hex
    call disp_nl

    ; cxの表示
    mov ax, ._s_hdr_cx
    call disp_str
    mov ax, cx
    call disp_word_hex
    call disp_nl

    ; dxの表示	

    mov ax, ._s_hdr_dx
    call disp_str
    mov ax, dx
    call disp_word_hex
    call disp_nl
    call disp_nl

    pop bx
    pop ax

    ret

._cf: db 0x00
._of: db 0x00

._s_hdr_of: db ' over flow : ', 0x00
._s_hdr_cx: db ' cx        : ', 0x00
._s_hdr_dx: db ' dx        : ', 0x00
._s_hdr_cf: db ' CF        : ', 0x00


;>===========================
;> main
;>===========================

main:

    ; ビデオモードの設定
    mov ah, 0x0
    mov al, 0x3    ; 16色テキスト、80x25
    int 0x10

;********************************
;   システムカウンタ
;********************************
    ; 改行
    mov ah, 0x0e
    mov al, 0x0d
    int 0x10
    mov al, 0x0a
    int 0x10

    ; タイトル表示
    mov si, ._s_hdr_start
._loop:
    lodsb
    or al, al
    je ._loop_end
    int 0x10
    jmp ._loop
._loop_end:

    ; システムカウンタ取得処理実行
    call exp_system_timer_count_read

    ; 処理終了
    call _hlt

    ret

._s_hdr_start: db '** System Timer Counter Read **', 0x0d, 0x0a, 0x00

times 510-($-$$) db 0

db 0x55
db 0xAA
