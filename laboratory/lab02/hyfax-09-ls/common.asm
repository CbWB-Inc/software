; ============================================================
; common.asm - 共通ルーチン群
; ============================================================
 BITS 16
 SECTION .text

%include 'hyfax.asm'

; %define STACK_SEG  0x0050
; %define BUF_SEG    0x09E0
; %define BUF_OFF    0x0000
%define PART_LBA   2048          ; 物理パーティション先頭（VBRのLBA）
; %define APP_SEG    0x1000
; %define APP_OFF    0x0000
; %define MON_SEG    0x0050
%define MON_ADDR    0x0000
%define PART_OFFSET 2048

global ps
global pc
global pcd
global psd
global phd1
global phd2
global phd4
global dump_mem

global memcpy
global memset

global exit_return

app_arg_data dw 0

; %define svc_putchar 0x23

CRTC_IDX  equ 0x3D4
CRTC_DATA equ 0x3D5
;---------------------------------------
; get_cursor
; out: AX = cursor position (0..1999)
;---------------------------------------
get_cursor:
    mov dx, CRTC_IDX
    mov al, 0x0E        ; Cursor High
    out dx, al
    inc dx              ; 0x3D5
    in  al, dx
    mov ah, al

    dec dx              ; 0x3D4
    mov al, 0x0F        ; Cursor Low
    out dx, al
    inc dx              ; 0x3D5
    in  al, dx
    ; AX = cursor pos
    ret

;---------------------------------------
; set_cursor
; in: AX = cursor pos
;---------------------------------------
set_cursor:
    push dx
    push bx

    mov bl, al          ; ★ low byte を退避

    ; high
    mov dx, CRTC_IDX
    mov al, 0x0E
    out dx, al
    mov dx, CRTC_DATA
    mov al, ah
    out dx, al

    ; low
    mov dx, CRTC_IDX
    mov al, 0x0F
    out dx, al
    mov dx, CRTC_DATA
    mov al, bl          ; ★ 退避した low byte を書く
    out dx, al

    pop bx
    pop dx
    ret

;---------------------------------------
; pc
; AL = character
; BL = attribute
;---------------------------------------
pc:
  push ax
  mov ah, 0x0e
  mov bx, 0x0007
  int 0x10
  pop ax
  ret


; pc
;     push ax
;     push bx
;     push dx
;     push di
;     push es

;     cmp al, 13      ; '\r'
;     je .cr
;     cmp al, 10      ; '\n'
;     je .lf

;     push ax
;     call get_cursor     ; AX = pos
;     mov dx, ax

;     ; VRAM offset = pos * 2
;     mov di, ax
;     shl di, 1

;     mov ax, 0xB800
;     mov es, ax

;     pop ax              ; AL = char
;     ; mov ax, dx
;     mov ah, bl
;     stosw               ; write char+attr

;     ; cursor++
;     ; call get_cursor
;     mov ax, dx
;     inc ax
;     call set_cursor

;     pop es
;     pop di
;     pop dx
;     pop bx
;     pop ax
;     ret

.cr:
    call get_cursor     ; AX = pos
    call pc_cr
    call set_cursor
    pop es
    pop di
    pop dx
    pop bx
    pop ax
    ret

.lf:
    call get_cursor     ; AX = pos
    call pc_lf
    call set_cursor
    pop es
    pop di
    pop dx
    pop bx
    pop ax
    ret

; in: AX = cursor_pos
; out: AX = new cursor_pos
pc_cr:
    xor dx, dx
    mov bx, 80
    div bx          ; AX=row, DX=col
    mul bx          ; AX=row*80
    ret

; in: AX = cursor_pos
; out: AX = new cursor_pos
pc_lf:
    xor dx, dx
    mov bx, 80
    div bx
    inc ax
    mul bx
    ret

; ds:ax -> es:bx , cx Byte
memcpy:
  push ax
  push bx
  push cx
  push si
  push di

  mov si, ax
  mov di, bx
.loop:
  mov al, ds:[si]
  mov es:[di], al
  inc si
  inc di
  loop .loop

  pop di
  pop si
  pop cx
  pop bx
  pop ax

  ret

memset:
  push ax
  push bx
  push cx
  push di

  mov di, ax
.loop:
  mov ds:[di], bl
  inc di
  loop .loop

  pop di
  pop cx
  pop bx
  pop ax

  ret

ps:
    ; mov ah, 0x03
    ; mov bx, 0
    ; int 0x10

  push ax
  mov si, ax
.loop:
  lodsb
  test al, al
  jz .exit
  mov ah, 0x0e
  int 0x10
  jmp .loop
.exit:
  pop ax
  ret

; --- Debug Output (Bochs/VMware port E9)
pcd:
  push ax
  out 0xE9, al
  pop ax
  ret

psd:
  mov si, ax
.loop:
  lodsb
  cmp al, 0
  je .exit
  push ax
  out 0xE9, al
  pop ax
  jmp .loop
.exit:
  ret

phd4:
  push ax
  mov al, ah
  call phd2
  pop ax
  push ax
  call phd2
  pop ax
  ret


phd2:
    push ax
    shr al, 4
    call phd1
    pop ax
    push ax
    call phd1
    pop ax
    ret



phd1:
        push ax
        and al, 0x0f
        cmp al, 0x09
        ja .gt_9
        add al, 0x30
        jmp .cnv_end
.gt_9:
        add al, 0x37

.cnv_end:
        out 0xE9, al
        pop ax
        ret

; phd2:
;   push ax
;   mov ah, al
;   shr al, 4
;   call .n
;   mov al, ah
;   and al, 0x0F
;   call .n
;   pop ax
;   ret
; .n:
;   cmp al, 9
;   jbe .d
;   add al, 'A' - 10
;   jmp .o
; .d:
;   add al, '0'
; .o:
;   push ax
;   out 0xE9, al
;   pop ax
;   ret

ph1:
        push ax
        and al, 0x0f
        cmp al, 0x09
        ja .gt_9
        add al, 0x30
        jmp .cnv_end
.gt_9:
        add al, 0x37

.cnv_end:
        mov ah, 0x0e
        int 0x10
        pop ax
        ret

ph2:
    push ax
    shr al, 4
    call ph1
    pop ax
    call ph1
    ret
ph4:
  push ax
  mov al, ah
  call ph2
  pop ax
  push ax
  call ph2
  pop ax
  ret


dump_mem:
    ; push si
    ; push cx
    ; push ax
    pushf
    cld
    push bx
    push cx
    push dx
    push si
    push di
    push ds
    push es

.next:
    test cx, cx
    jz .done
    mov al, [es:si]
    call phd2
    mov al, ' '
    out 0xE9, al
    inc si
    dec cx
    jmp .next
.done:
    pop es
    pop ds
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    popf
    
    ; pop ax
    ; pop cx
    ; pop si
    ret

strlen:
    mov si, ax
    xor cx, cx
.loop:
    cmp byte [si], 0x00
    jz .exit
    inc cx
    inc si
    jmp .loop
.exit:
    ret

; strcpy_ds
; IN : AX=dst_off, BX=src_off (both in DS)
; OUT: CX=bytes copied (not including NUL)
; CLOBBER: AX, CX
strcpy:
    push di
    push si

    mov di, ax
    mov si, bx
    xor cx, cx

.loop:
    mov al, [si]
    mov [di], al
    inc si
    inc di
    cmp al, 0
    je  .done
    inc cx
    jmp .loop

.done:
    pop si
    pop di
    ret

; strcmp
; DS:SI = s1
; DS:DI = s2
; AX = result (0, <0, >0)

strcmp:
.loop:
    mov al, [si]
    mov bl, [di]
    cmp al, bl
    jne .diff

    test al, al      ; 両方 0 なら終端
    je .equal

    inc si
    inc di
    jmp .loop

.diff:
    ; AX = (signed)al - (signed)bl
    mov ah, 0
    mov bh, 0
    sub ax, bx
    ret

.equal:
    xor ax, ax
    ret


; ----------------------------------------
; ucase
;   DS:ax -> NUL終端文字列を大文字化
; ----------------------------------------
ucase:
    push ax
    mov si, ax
.next:
    lodsb              ; AL = [SI], SI++
    test al, al
    jz   .done          ; NULで終了

    cmp  al, 'a'
    jb   .next
    cmp  al, 'z'
    ja   .next

    sub  al, 0x20       ; 'a'->'A'
    mov  [si-1], al     ; 書き戻し
    jmp  .next

.done:
    pop ax
    ret

exit_return:
    ; --- モニタへ戻る ---
    ; 既定：MON_SEG:0000 に戻る（monitor側の戻り口が0x0000想定）
    push word TTS_SEG
    push word 0x0000
    retf


;************************************
; 83形式のファイル名をドット形式にする
;************************************
to_dot:
    ret

;************************************
; ドット表記のファイル名を83形式にする
; IN : なし (file_name グローバル変数を直接使用)
; OUT: file_name が 83形式に変換される
;************************************
to_83:
    push bp
    mov bp, sp
    push ax
    push ds
    push es
    push si
    push di
    push bx
    push cx

    ; ★★★ 内部バッファをクリア ★★★
    mov ax, cs
    mov es, ax
    
    ; .input_copy をクリア (256バイト)
    mov di, .input_copy
    xor al, al
    mov cx, 256
    rep stosb
    
    ; file_name_ths をクリア (128ワード = 256バイト)
    mov di, file_name_ths
    xor ax, ax
    mov cx, 128
    rep stosw
    
    ; === 入力文字列(file_name)をCSセグメント内にコピー ===
    mov si, file_name         ; DS:SI = file_name
    push cs
    pop es
    mov di, .input_copy
.copy_in:
    lodsb
    stosb
    test al, al
    jnz .copy_in

    ; === DS/ESをCSに設定してパース実行 ===
    mov ax, cs
    mov ds, ax
    mov es, ax

    mov si, .input_copy
    mov di, file_name_ths
    mov al, '.'
    call split

    ; base/ext 取得
    mov si, [di + THS.off]
    mov [.base], si
    mov si, [di + THS.off + 2]
    mov [.ext], si

    ; === temp_bufを空白で初期化 ===
    mov di, .temp_buf
    mov al, ' '
    mov cx, 11
    rep stosb
    mov byte [di], 0          ; NUL終端

    ; === NAME部分コピー (最大8文字) ===
    mov si, [.base]
    mov di, .temp_buf
    mov cx, 8
.name_loop:
    cmp byte [si], 0
    je .name_done
    movsb
    loop .name_loop
.name_done:

    ; === EXT部分コピー (最大3文字) ===
    mov si, [.ext]
    test si, si               ; NULLチェック
    jz .no_ext
    cmp byte [si], 0          ; 空文字列チェック
    je .no_ext

    mov di, .temp_buf
    add di, 8
    mov cx, 3
.ext_loop:
    cmp byte [si], 0
    je .ext_done
    movsb
    loop .ext_loop
.ext_done:
.no_ext:

    ; === 結果をfile_name(呼び出し元セグメント)にコピー ===
    pop cx                    ; スタックからレジスタ復元開始
    pop bx
    pop di
    pop si
    pop es
    pop ds                    ; DS = 元のセグメント
    pop ax
    
    ; ここでDS = 呼び出し元, ES = CSにする
    mov di, file_name         ; DS:DI = file_name
    
    push cs
    pop es                    ; ES = CSセグメント
    mov si, .temp_buf         ; ES:SI = temp_buf
    
    mov cx, 12                ; 11文字 + NUL
.copy_out:
    mov al, es:[si]           ; CSセグメントから読む
    mov [di], al              ; 呼び出し元セグメントに書く
    inc si
    inc di
    loop .copy_out

    pop bp
    ret

.input_copy times 256 db 0
.temp_buf times 256 db 0
.cnt db 0
.base dw 1
.ext dw 1
.si_save dw 1

file_name times 256 db 0

;************************************
; split処理
;************************************
; DS:SI = 入力文字列
; ES:DI = THS 構造体先頭
; al    = 区切り文字
split:
    xor cx, cx                  ; cnt = 0
    lea bx, [di + THS.off]      ; off 配列先頭

.skip:
    cmp byte [si], al
    jne .check
    inc si
    jmp .skip

.check:
    cmp byte [si], 0
    je .done

    ; cmp cx, 126
    ; jae .done
    mov [bx], si                ; offset 登録
    add bx, 2
    inc cx

.scan:
    cmp byte [si], 0
    je .next
    cmp byte [si], al
    je .cut
    inc si
    jmp .scan

.cut:
    mov byte [si], 0
    inc si

.next:
    jmp .skip

.done:
    mov [di + THS.cnt], cx
    ret

.dlm db 0

;************************************
; 表示を1行クリアする
;************************************
; clear_line
; IN : CX = 消したい文字数（現在の行の最大長）
; OUT: カーソルは行頭
; CLOBBER: AX, CX
clear_line:
    ; 行頭に戻る
    mov al, 0x0d        ; CR
    mov ah, svc_putchar
    int 0x80

.clear_loop:
    test cx, cx
    jz .done

    mov al, ' '
    mov ah, svc_putchar
    int 0x80

    dec cx
    jmp .clear_loop

.done:
    ; もう一度行頭へ
    mov al, 0x0d
    mov ah, svc_putchar
    int 0x80

    ret

;************************************
; テスト用関数
;************************************
func:
    call ps
    ret

file_name_ths times 128 dw 0 
dw 0xDEAD


%include 'hyfax.asm'