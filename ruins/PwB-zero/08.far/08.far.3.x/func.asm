org 0x0000  ; どこに読まれても問題ないように0で書く（後で動的に補正）

start:
    ; 自分の現在の CS:IP を取得
    call $+3
    pop si         ; SI = return address（IPに相当）
    mov ax, cs
    mov ds, ax     ; DSをCSに合わせる
    mov es, ax
    
    
    ;mov ds, bx
    ;mov es, bx

    mov ah, 0x0e
    mov al, 'H'
    int 0x10
    mov al, 'i'
    int 0x10
    mov al, '!'
    int 0x10
    mov al, 0x0a
    int 0x10
    mov al, 0x0d
    int 0x10
    



    ; 以降の文字列やデータ参照は DS:SI 相対で処理可能
    ;mov ax, [baddr]
    ;add ax, msg2
    
;    mov ax, ds:msg2
    mov ax, ds:0x0045
;    add ax, 
;    call disp_str2
;    call disp_word_hex
    call 0x0555
    
    
;    mov bx, disp_str

;    add bx, 0x2800
    ;call bseg:bx
    ;call disp_str
    ;mov word [.jmp_addr+2], bseg    ; segment

;    mov word [.jmp_addr], bx        ; offset
;    mov word [.jmp_addr+2], 0x07c0    ; segment
;    jmp far [.jmp_addr]

    mov ah, 0x0e
    mov al, '='
    int 0x10

;    pop ax
    jmp 0x07c0:0x2800
    ;jmp bseg:main2
    ;ret

.hang:
    hlt
    jmp .hang
;    jmp 0x07c0:main

.jmp_addr:
    dw  0
    dw  0

msg db "It works!", 0x0d, 0x0a, 0x00
msg2 db "It works!!!", 0x0d, 0x0a, 0x00
baddr dw 0

bseg equ 0x07c0
main2           equ 0x2800




;==============================================================
; 仮バイオスの末端
;==============================================================
_padding3:
    times 0x0400-($-$$)-2 db 0


;********************************
; セクションシグネチャ
;********************************

db 0x55
db 0xAA

;********************************
; サブルーチン
;********************************


;%include "def.asm"

;%include "routine1.asm"

;>===========================
;>  BIOSコールラッパー
;>===========================

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
; get_kb_sts
;   0x01    Return Keyboard Status
;       キーボードの状態を得る
; return : ZF : 0 : 読み込める
;               1 : 読み込めない
;          ah : スキャンコード
;          al : アスキーコード
; remarks: 前のRead Keyboard Inputが入力待ちでブロックされるので
;          こいつで回して読み込める時にRead Keyboard Inputをする
;          感じかな。向こうでバッファクリアだし。
;********************************
get_kb_sts:

    mov ah, 0x01
    int 0x16

    ret

;********************************
; get_kb_cond
;   0x02    Return Shift Flag Status
;       キーボードのシフトとかの押下状態を得る
; returen ; al : 状態のフラグ
;********************************
get_kb_cond:

    mov ah, 0x02
    int 0x16

    ret

;********************************
; get_kb_tr
;   0x03    Set Typematic Rate
;       キーボードの自動リピート、レートなどを設定する
; param     : ah : 0x03（固定）
;             al : 0x03 : タイプマティック遅延を設定します
;                  0x05 : タイプマティックレートを設定します
;             bl : 0x03 : al=0x03
;                           0x03	1000ミリ秒
;                         al=0x05
;                           0x1F	2.0文字/秒
; return    : なし
;********************************
set_kb_tr:

    mov ah, 0x03
    mov al, al
    mov bl, bl

    int 0x16

    ret

;********************************
; set_kb_buf
;       キーボードバッファにキーデータを書き込む
; param  : ah : 書き込むスキャンコード
;          al : 書き込むアスキーコード
;
;   0x05    Push Data to Keyboard
; param     : ah : 0x05（固定）
;             ch : 書き込むスキャンコード
;             cl : 書き込むアスキーコード
; return    : ZF : 0 : 成功
;                  1 : 失敗
;             al : 0x00 : エラーなし
;                  0x01 : キーボードバッファフル
;********************************
set_kb_buf:

    mov bx, ax
    mov ah, 0x05
    mov cx, bx

    int 0x16

    ret


;********************************
; enh_get_key_data
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

    mov bx, _b_false
    mov ah, 0x11
    int 0x16
    jne ._end
    mov bx, _b_true

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

;********************************
; read_disk
;    ahで指定されたドライブのalで指定されたセクタからbhで
;    指定された数だけディスクからセクタを読み込む
;       ax : Extra Segmentを指定
;       bx : 読み込んだデータを書き込むアドレスを指定
;       ch : 読み込むドライブ番号
;       cl : 読み込みを始めるセクタ番号（MBR:1、通常2以上)
;       dh : 読み込むセクタ数
;********************************
read_disk:


    ;mov ax, ax
    mov es, ax   ; 読み込むセグメント
    ;mov bx, bx  ; 読み込む先のアドレス

    mov ah, 0x02 ; セクタ読み込みを指示
    mov al, dh   ; セクタ数
    mov ch, 0x00 ; シリンダ
    mov cl, cl   ; 開始セクタ
    mov dh, 0x00 ; ヘッダ
    mov dl, 0x80 ; ドライブ番号
    int 0x13     ; 読み込み実行

    ret


;********************************
; write_disk
;    ahで指定されたドライブのalで指定されたセクタからbhで
;    指定された数だけディスクからセクタを読み込む
;       ax : Extra Segmentを指定
;       bx : 書き込むデータのあるアドレスを指定
;       ch : 書き込むドライブ番号
;       cl : 書き込みを始めるセクタ番号（MBR:1、通常2以上)
;       dh : 書き込むセクタ数
;********************************
write_disk:


    ;mov ax, ax
    mov es, ax   ; 読み込むセグメント
    ;mov bx, bx  ; 読み込む先のアドレス

    mov ah, 0x03 ; セクタ書き込みを指示
    mov al, dh   ; セクタ数
    mov ch, 0x00 ; シリンダ
    mov cl, cl   ; 開始セクタ
    mov dh, 0x00 ; ヘッダ
    mov dl, 0x80 ; ドライブ番号
    int 0x13     ; 書き込み実行

    ret


;********************************
; get_cpu_speed
;       CPUの速度を設定する
; param  : なし
; return : al : 0x00 : CPUクロックを低速にする
;               0x01 : CPUクロックを中速にする
;               0x02 : CPUクロックを高速にする
;
;   0xF1    Get CPU Speed
; param  : ah : 0xF0
; return : al : 0x00 : CPUクロックを低速にする
;               0x01 : CPUクロックを中速にする
;               0x02 : CPUクロックを高速にする
;********************************
get_cpu_speed:

    mov ah, 0xf1

    int 0x16

    ret


;********************************
; get_vbe_info
;       VBEの情報を取得する
; param  : ES:DI : beInfoBlock 構造体が格納されるバッファーアドレスを指定する。
; return : ax : VBEステータス
;
;   x00 Return VBE Controller Information
; param  : ah   : 0x4F  : VBEのファンクション番号を指定する。
;          al     0x00  : VBEコントローラー情報取得ファンクション番号を指定する。
;         ES:DI : beInfoBlock 構造体が格納されるバッファーアドレスを指定する。
;                       (beInfoBlock:512Byte、VBE3.0の情報 : VbeSignatureに”VBE2”をセットし)
; return : ax : VBEステータス
;
;********************************
get_vbe_info:

    mov ah, 0x4f
    mov al, 0x00

    int 0x00

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

    mov ah, 0x03
    mov al, 0x00
    mov bh, 0x00    ; 当面0ページ固定で様子を見る
    mov bl, 0x00    ; 当面0ページ固定で様子を見る
    int 0x10

    mov ax, dx
    mov bx, cx

    pop dx
    pop cx

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

    mov dx, ax
    mov ah, 0x02
    mov al, 0x00
    mov bh, 0x00    ; 当面０ページで固定
    mov bl, 0x00    ; 当面０ページで固定
    int 0x10

    pop bx
    pop ax

    ret


;>===========================
;> 	サブルーチン
;>===========================

;********************************
; bin_nibble_hex
;       4bit整数を16進文字に変換する
;       0～15 -> '0'～'f'
; param  : al : 変換する数値
;               16以上を指定すると上位ニブルは無視され、下位ニブルが変換されて返る
;                 e.g. 0x21 -> '1'
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
;       1バイトの数値を16進文字列に変換する
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
; str_cmp
;       文字列を比較する
; param : ax, bx
; return: cx
;********************************
str_cmp:
    push ax
    push bx
    push si
    push di

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

_s_equal db 'equal', 0x0d, 0x0a, 0x00
_s_not_equal db 'not equal', 0x0d, 0x0a, 0x00

;********************************
; ucase
;       大文字にする
; param : 
; return: 
;********************************
ucase:
    push ax
    push si
    
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
    pop ax
    
    ret

;********************************
; lcase
;       小文字にする
; param : 
; return: 
;********************************
lcase:
    push ax
    push di
    push si
    
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
    pop di
    pop ax
    
    ret


;>===========================
;>  ユーティリティ
;>===========================
;****************************
; disp_nl
;   改行する
;****************************
disp_nl:

    push ax

;    mov ax, ._s_crlf
;    call disp_str

    mov ah, 0x0e
    mov al, 0x0d
    int 0x10
    mov al, 0x0a
    int 0x10
    



    pop ax
    
    ret

    ._s_crlf:       db 0x0d, 0x0a, 0x00

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
disp_str2:

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



;==============================================================
; ファイル長の調整
;==============================================================
_padding4:
    times 0x0800-($-$$)-2 db 0

;********************************
; セクションシグネチャ
;********************************

db 0x55
db 0xAA
