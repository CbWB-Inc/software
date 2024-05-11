;>===========================
;>	BIOSで遊ぼっ！
;>===========================

section .data

	_c_seg          equ 0x07c0
	_c_ex_area_addr equ 0x200

	_c_true         equ '1'
	_c_false        equ '0'

	_b_true         equ 1
	_b_false        equ 0


section .text

boot:
	; set segment register
        mov ax, _c_seg
        mov ds, ax

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



;>****************************
;> hlt
;>****************************
_hlt:
	hlt
	jmp _hlt


_m_isTest:       db 0



;>****************************
;> ブートローダパディング
;>****************************


times 510-($-$$) db 0

;********************************
; ブートセクタシグネチャ
;********************************

db 0x55
db 0xAA

;>********************************
;> definition of variables
;>********************************

_s_crlf:       db 0x0d, 0x0a, 0x00

_m_buf_str:
	times 128 db 0 
    ;db 0, 10, 13, '                             '

_m_zf: db _b_false

section .text

;>===========================
;> BIOS call rapper 
;>===========================
;********************************
; enh_get_key
;   0x10    Enhanced Read Keyboardt
;       キー入力待ちして、押下されたキーコードとアスキーコードを返す
;	（未確認だけどアスキーコードがないキーを押されるとアスキーコードに0x00が返るんじゃないかな）
; returen ; ah : キーコード
;           al : アスキーコード
;********************************
enh_get_key:
	
    mov ah, 0x10
        int 0x16

    ret

;********************************
; enh_get_kb_sts
;   x11 Enhanced Read Keyboard Status
;       キーボードの状態を得る
; return : ZF : 0 : 読み込める
;               1 : 読み込めない
;          ah : スキャンコード
;          al : アスキーコード
; remarks: 前のRead Keyboard Inputが入力待ちでブロックされるので
;          こいつで回して読み込める時にRead Keyboard Inputをする
;          感じかな。向こうでバッファクリアだし。
;           『このファンクションの互換機能がDOSに実装されているため、通常このファンクションは使用しません』
;           だそうだけど、つまりBIOS機能は別途実装可能ってことね
;********************************
enh_get_kb_sts:

    ;mov ax, _b_false
    ;mov [_m_zf], ax
    mov ah, 0x11
    int 0x16
    jne ._end
    ;mov ax, _b_true
    ;mov [_m_zf], ax

._end:

    ret

;********************************
; enh_get_kb_cond
;   0x12    Enhanced Read Keyboard Flags	拡張キーボードフラグ読み込み
;       キーボードのシフトとかの押下状態を得る
; returen ; al : 状態のフラグ
;********************************
enh_get_kb_cond:

    mov ah, 0x12
    int 0x16

    ret

;>===========================
;>  BIOSコール 実験コード
;>===========================
;********************************
; エコーの実験
;********************************
exp_echo:

    mov ax, ._title1
    call disp_str
    mov ax, _s_crlf
    call disp_str

    call get_str_ascii

    call disp_nl
    call disp_nl
    mov ax, si
    call disp_str
    call disp_nl
    call disp_nl

    ret


._title1:
    db "*********************************", 0x0d, 0x0a
    db "* Echo" , 0x0d, 0x0a
    db "*********************************", 0x0d, 0x0a
    db "CTRL + Enter -> Power off", 0x0d, 0x0a
    db "Enter any key", 0x0d, 0x0a, 0x00

._restart: db '** : restart', 0x0d, 0x00a, 0x0d, 0x0a, 0x00



;>===========================
;> 	サブルーチン
;>===========================

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

;****************************
; get_str_ascii
;   改行する
;****************************
get_str_ascii:

    mov si, _m_buf_str

._loop:

    call enh_get_kb_sts
    jne ._loop

    call enh_get_key
    mov bx, ax
    
    cmp bl, 0x20
    jg ._skip

._l1:

    cmp bx, 0x1c0a
    je ._exit

    mov cx, bx
    mov ch, 0x00
    cmp cl, 0x0d
    jne ._nnl

    cmp si, _m_buf_str
    je ._loop

    mov byte [si], 0x0d
    inc si
    mov byte [si], 0x0a
    inc si
    mov byte [si], 0x00

    call disp_nl
    call disp_nl
    mov si, _m_buf_str
    mov ax, si
    call disp_str
    call disp_nl
    mov byte [si], 0x00

    jmp ._loop

._nnl
    mov ax, bx

    cmp si, _m_buf_str
    je ._loop

    mov [si], al
    inc si

    jmp ._loop

._skip:

    mov ax, bx
    
    mov ah, 0x0e
    int 0x10

    mov [si], al
    inc si

    jmp ._loop

._exit:

    mov ax, si

    ret


;>===========================
;> main
;>===========================

main:
    ; set segment register
    mov ax, _c_seg
    mov ds, ax

    ; ビデオモードの設定
    mov ah, 0x0
    mov al, 0x3    ; 16色テキスト、80x25
    ; mov al, 0x6a  ; 800x600x4bitカラー（ビデオカードによってはサポートされない）
    int 0x10

    ; 念のため初期化
    cld


    call exp_echo

    mov ax, _bye
    call disp_str

    ; 処理終了
    call power_off

_bye: db 'bye', 0x0d, 0x0a, 0x00

;==============================================================
; ファイル長の調整
;==============================================================
_padding:
    times 0x100000-($-$$) db 0

