;>===========================
;>      BIOSと戯れてみる
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

times 510-($-$$) db 0

;********************************
; ブートセクタシグネチャ
;********************************

db 0x55
db 0xAA

;>===========================
;>      サブルーチン
;>===========================
;********************************
; ch0   4bit整数を16進文字に変換する（下位4Bit）
;       0～15 -> '0'～'f'
; param  : al : 変換する数値
; return : bl : 変換された文字
;******************************
ch0:

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
; ch2    : 1バイト整数を16進文字に変換する（下位4Bit）
; param  : al : 変換したい数値
; return : bx : 変換した2文字の16進文字
;********************************
ch1:
    push cx
    push dx

    mov cl, al
    sar al, 4
    and al, 0x0f
    mov ah, 0
    call ch0
    mov dh, bl

    mov al, cl
    and al, 0x0f
    mov ah, 0
    call ch0
    mov dl, bl

    mov bx, dx

    pop dx
    pop cx

    ret

;****************************
; pnl  : 改行する
;****************************
pnl:

    push ax

    mov ax, ._s_crlf
    call ps

    pop ax

    ret

._s_crlf db 0x0d, 0x0a, 0x00

;********************************
; ph1    : 1バイトの数値を16進で表示する
; param  : al : 表示したい数値
;********************************
ph1:
    push ax
    push bx

    call ch1
    mov ah, 0x0e
    mov al, bh
    int 0x10
    mov al, bl
    int 0x10

    pop bx
    pop ax

    ret

;********************************
; ph2   : 2バイト（1ワード）のデータを表示する
; param : ax : 表示するword
;********************************
ph2:

    push ax
    push bx

    mov bx, ax
    mov al, bh
    call ph1

    mov al, bl
    call ph1

._end:

    pop bx
    pop ax

    ret

;********************************
; ps    : display null-terminated string.
; param : ax : addr of mem where string is set.
;********************************
ps:

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
;>  BIOSコール 実験コード
;>===========================
;********************************
; system_timer_count_readの確認
;********************************
system_timer_count_read:

    push ax
    push bx

    mov ah, 0x00    ; 読み込みファンクション指定（０固定）
    int 0x01a       ; システムタイマカウント読み込み

    jnc ._cf_nomal
    ; 失敗
    mov ah, 0x01

._cf_nomal:
    mov [._success], ah

    mov [._of], al

    ; CFの表示
    mov ax, ._s_hdr_cf
    call ps

    mov al, [._success]
    call ph1
    call pnl

    ; over fllow の表示     : Over Fllowしたか？
    mov ax, ._s_hdr_of
    call ps
    mov al, [._of]
    call ph1
    call pnl

    ; cxの表示              : cxxの値表示           
    mov ax, ._s_hdr_cx
    call ps
    mov ax, cx
    call ph2
    call pnl

    ; dxの表示	            : dxの値表示           
    mov ax, ._s_hdr_dx
    call ps
    mov ax, dx
    call ph2
    call pnl
    call pnl

    pop bx
    pop ax

    ret

._success: db 0x00
._of:      db 0x00

._s_hdr_of: db " over flow : ", 0x00
._s_hdr_cx: db " cx        : ", 0x00
._s_hdr_dx: db " dx        : ", 0x00
._s_hdr_cf: db " success   : ", 0x00

;>===========================
;> main
;>===========================

main:

    ; ビデオモードの設定
    mov ah, 0x0
    mov al, 0x3    ; 16色テキスト、80x25
    int 0x10

;********************************
;   暫定実行コード：システムカウンタ
;********************************
    call pnl
    mov ax, ._s_hdr_start
    call ps

    call system_timer_count_read

    ; 処理終了

._s_hdr_start: db '** System Timer Counter Read **', 0x0d, 0x0a, 0x00

;==============================================================
; ファイル長の調整
;==============================================================
_padding:
    times 0x100000-($-$$) db 0
