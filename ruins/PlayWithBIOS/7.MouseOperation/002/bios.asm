;>===========================
;>      BIOSで遊ぼっ！
;>===========================

section .data

    _c_seg          equ 0x07c0
    _c_ex_area_addr equ 0x200
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

    ; ビデオモードの設定
    mov ah, 0x0
    mov al, 0x3    ; 16色テキスト、80x25
    int 0x10

    jmp main

;********************************
; ブートセクタ終端までゼロで埋める
;********************************

times 510-($-$$) db 0

;********************************
; ブートセクタシグネチャの書き込み
;********************************

db 0x55
db 0xAA

;>===========================
;> main
;>===========================

main:

    ; システムカウンタの取得と表示
    call MouseOperation
    
    ; play Cursor
    ;call Move_Cursor

    call _hlt

;>===========================
;> Ply Cursor : inspect cursor function
;>===========================
Move_Cursor:

    mov bx, ax
    mov cx, 0x00
    cmp bl, 0x7f
    jle ._skip1
    not bl
    inc bl
    inc cl
._skip1:
    sar bl, 4

    cmp bh, 0x7f
    jle ._skip2
    not bh
    inc bh
    inc ch
._skip2:
    sar bh, 4

    call get_cursor_pos
    cmp cl, 0x00
    je ._l_equal
    cmp ah, bl
    jle ._l_le
    mov ah, 0x00
    jmp ._l_join
._l_le:
    sub ah, bl
    jmp ._l_join
._l_equal:
    add ah, bl
    cmp ah, 20
    jle ._l_join
    mov ah, 20
._l_join:

    cmp ch, 0x00
    je ._h_equal
    cmp al, bh
    jle ._h_le
    mov al, 0x00
    jmp ._h_join
._h_le:
    sub al, bh
    jmp ._h_join
._h_equal:
    add al, bh
    cmp al, 24
    jle ._h_join
    mov al, 24
._h_join:

    call set_cursor_pos

    ret

;>===========================
;> Ply Cursor : inspect cursor function
;>===========================
Play_Cursor:

    ; get cursor pos
    
    call get_cursor_pos
    call disp_word_hex
    call disp_nl

    call get_cursor_pos
    call disp_word_hex

    mov ah, 10
    mov al, 10
    call set_cursor_pos

    ret


;>===========================
;> mouse infomation 
;>===========================
MouseOperation:

    ; init mouse device
    mov al, 0xa8
    out 0x64, al

    ; reset mouse (and get status)
    mov al, 0x20
    out 0x64, al

    in al, 0x60
    mov bl, al
    or bl, 0x02

    mov al, 0x60
    out 0x64, al
    mov al, bl
    out 0x60, al

    mov al, 0xd4
    out 0x64, al
    mov al, 0xf4
    out 0x60, al

._loop1:
    in al, 0x60
    mov bl, 0xfa
    cmp al, bl
    jne ._loop1


._loop2:
    in al, 0x64
    test al, 0x20
    jnz ._loop2

    mov bl, 0
    in al, 0x60
    mov bh, [mouse_b]
    cmp al, bh
    je ._skip1
    inc bl
._skip1:
    mov [mouse_b], al

    in al, 0x60
    mov bh, [mouse_x]
    cmp al, bh
    je ._skip2
    inc bl
._skip2:
    mov [mouse_x], al

    in al, 0x60
    mov bh, [mouse_y]
    cmp al, bh
    je ._skip3
    inc bl
._skip3:
    mov [mouse_y], al

    cmp bl, 0
    je ._loop2

    mov ah, [mouse_y]
    mov al, [mouse_x]
    call Move_Cursor

;    mov al, [mouse_b]
;    call disp_byte_hex
;    mov al, [mouse_y]
;    call disp_byte_hex
;    mov al, [mouse_x]
;    call disp_byte_hex

    jmp ._loop2

    ret

mouse_b: db 0x00
mouse_x: db 0x00
mouse_y: db 0x00

;>===========================
;>      サブルーチン
;>===========================

;********************************
; get_cursor_pos
; カーソル位置取得
; paramater : なし
; return    : ah : 現在の行（0オリジン）
;           : al : 現在の列（0オリジン）
;********************************
get_cursor_pos:

    ;push ax
    ;push bx
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
    ;pop bx
    ;pop ax

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

_s_crlf:       db 0x0d, 0x0a, 0x00

;>****************************
;> hlt
;>****************************
_hlt:
    hlt
    jmp _hlt

