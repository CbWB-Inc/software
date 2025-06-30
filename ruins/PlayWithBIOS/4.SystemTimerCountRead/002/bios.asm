;>===========================
;>	BIOSで遊ぼっ！
;>===========================

section .data

	_c_seg          equ 0x07c0
	_c_ex_area_addr equ 0x200

section .text

boot:
    ; set segment register
    mov ax, _c_seg
    mov ds, ax
    
    ; disk read
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

    _c_seg          equ 0x07c0
    _c_ex_area_addr equ 0x200
    _s_crlf:       db 0x0d, 0x0a, 0x00

section .text

;>===========================
;> 	サブルーチン
;>===========================
;********************************
; bin_nibble_hex
;       4bit整数を16進文字に変換する
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

;>===========================
;>  BIOSコールラッパー
;>===========================
;********************************
; get_key
;   0x00    Read Keyboard Input
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
    push cx
    push dx

    mov ah, 0x00
    int 0x01a

    jnc ._cf_nomal
    ; キャリーが立っていた場合
    mov ah, 0x01
    mov [._cf], ah

._cf_nomal:
    mov [._of], al

    ; CFの表示
    mov ax, ._s_hdr_cf
    call disp_str
    mov al, [._cf]
    call disp_byte_hex
    call disp_nl

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

    pop dx
    pop cx
    pop bx
    pop ax

    ret

._cf: db 0x00
._of: db 0x00
._s_hdr_of: db ' over flow : ', 0x00
._s_hdr_cx: db ' cx        : ', 0x00
._s_hdr_dx: db ' dx        : ', 0x00
._s_hdr_cf: db ' CF        : ', 0x00

;********************************
; 確認用
;********************************
exp_test:

    mov bx, 0xffff
    mov cx, 0xffff
    mov dx, 0x0003

    call disp_nl
    mov ax, ._s_hdr_target
    call disp_str
    call disp_nl
    mov ax, ._s_hdr_start
    call disp_str
    call exp_system_timer_count_read
    call disp_nl

    mov ax, ._s_hdr_process
    call disp_str

._loop1:                ; 1階層
._loop2:                ; 2階層
._loop3:                ; 3階層

    dec bx

    ;or bx, bx           ; 次の行とこの行のどちらかを選ぶ
    cmp bx, 0

    jne ._loop3         ; 3階層底
    mov bx, 0xffff
    
    dec cx
    or cx, cx
    jne ._loop2         ; 2階層底
    mov cx, 0xffff

    dec dx
    or dx, dx
    jne ._loop1         ; 1階層底

    call disp_nl
    call disp_nl
    mov ax, ._s_hdr_end
    call disp_str
    call exp_system_timer_count_read

    ret

._s_hdr_target: db '### TARGET : cmp bx, 0  ###', 0x0d, 0x0a, 0x00
;._s_hdr_target: db '### TARGET : or bx, bx ###', 0x0d, 0x0a, 0x00
._s_hdr_start: db ' ** start **', 0x0d, 0x0a, 0x00
._s_hdr_end: db ' ** end **', 0x0d, 0x0a, 0x00
._s_hdr_process: db ' now working..', 0x00
._s_buf: times 256 db 0x00
._s_dot: db '.', 0x00

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

;********************************
;   暫定実行コード：システムカウンタ
;********************************
    call exp_test

    ;call _hlt

    call disp_nl
    call disp_nl
    mov ax, ._s_msg
    call disp_str
    call get_key
    call power_off

    call _hlt
    ret

._s_msg: db 'hit any key to power off', 0x0d, 0x0a, 0x00

_bye: db 'bye', 0x0d, 0x0a, 0x00

_test: db 0x33, 0x00

;==============================================================
; ファイル長の調整
;==============================================================
_padding:
    times 0x100000-($-$$) db 0
