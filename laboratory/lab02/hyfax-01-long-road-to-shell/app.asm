; app.asm - S1 sample app (blocking key wait)
; build: nasm -f bin app.asm -o APP.BIN

BITS 16
; org 0x0000

%include 'hyfax.asm'

%define MON_SEG  0x0050        ; monitor側のセグメント（monitor.asmと合わせる）

%macro PUTC 1
    push ax
    mov al, %1
    out 0xE9, al
    pop ax
%endmacro

; extern exit_return
; extern phd1
; extern phd2
; extern phd4

start:
    PUTC 'A'
    PUTC ':'

    ; --- COMライク初期化（CS=DS=ES=SS=自分、SP設定） ---
    push cs
    pop  ds
    push cs
    pop  es
    push cs
    pop  ss
    mov  sp, 0xfffe

    ; --- メッセージ表示 ---
    mov si, msg_hello
    mov ah, 0x20              ; write(DS:SI, CX)
    int 0x80

    mov ah, svc_newline
    int 0x80

    ; echo の確認
    ; call exp_echo

    ; history の確認
    ; call exp_history

    ; line_input の確認
    call exp_line_input


exit:
    ; call exit_return

    ; --- モニタへ戻る ---
    ; 既定：MON_SEG:0000 に戻る（monitor側の戻り口が0x0000想定）
    push word MON_SEG
    push word 0x0000
    retf
    

    ; 別戻り先にしたい場合（monitor側に monitor_restart がある等）：
    ; mon_ret_ptr: dw monitor_restart, MON_SEG
    ; jmp  far [mon_ret_ptr]



;********************************
; line_input確認用ドライバ
;********************************
exp_line_input:
.loop1:
    mov di, line_buf        ; バッファの準備
    call line_input         ; historyの実行

    xor cx, cx              ; 0文字なら何もしない
    mov ax, line_buf
    call strlen
    cmp cx, 0
    je .skip

    mov si, line_buf        ; バッファの表示
    mov ah, svc_write
    int 0x80

    mov ah, svc_newline     ; 改行
    int 0x80
    
    mov ax, line_buf        ; バッファのクリア
    mov bl, 0
    mov cx, cx
    call memset

.skip:
    jmp .loop1

    ret             ; 無限ループなのでここには来ない


;********************************
; 1行入力(echo)確認用ドライバ
;********************************
exp_echo:
.loop:
    mov di, line_buf    ; バッファの準備
    call echo           ; echoの実行

    mov si, line_buf    ; 戻ってきた値を出力
    mov ah, svc_write
    int 0x80

    mov ah, svc_newline ; 後片付け
    int 0x80
    
    mov ax, line_buf    ; バッファのクリア
    mov bl, 0
    mov cx, line_buf_size
    call memset

    jmp .loop

    ret

;********************************
; 履歴(history)確認用ドライバ
;********************************
exp_history:
.loop3:
    mov di, line_buf
    call history        ; history機能

    jmp .loop3

    ret


;********************************
; history
;********************************
history:
.loop4:
    mov ah, svc_getkey  ; getkey_wait() -> AX=ASCII(0含む)
    int 0x80

    test al, al
    jz .ext_key

    cmp al, 0x0d    ; return
    je ._0d
.ext_key:
.up:
    dec byte [hisp]
    js .up_worp
    jmp .exit

.up_worp:
    mov byte [hisp], 3
    jmp .exit

.down:
    inc byte [hisp]
    cmp byte [hisp], 4
    jl  .exit
    mov byte [hisp], 0
    jmp .exit

.exit:    
    cmp byte [.cnt], 0
    je .loop4
    
    xor cx, cx
    mov cl, 79
    call clear_line

    xor ax, ax
    mov al, [hisp]
    mov bx, line_buf_size
    mul bx
    mov si, hibuf
    add si, ax
    mov ah, svc_write
    int 0x80

    mov ah, svc_putchar
    mov al, 0x0d
    int 0x80

    jmp .loop4

._0d:

    ret

.cnt db 0

;********************************
; line_input
;********************************
line_input:
    mov ax, line_buf
    call strlen
    mov [.cnt], cl

.loop2:
    ; --- ブロッキングで1キー待ち (AH=0x22) ---
    mov ah, svc_getkey  ; getkey_wait() -> AX=ASCII(0含む)
    int 0x80

    ; ; for debug
    ; push ax
    ; mov bx, ax
    ; mov ah, svc_puthex 
    ; int 0x80
    ; pop ax
    
    test al, al
    jz .ext_key

    cmp al, 0x0d    ; return
    je ._0d

    cmp al, 0x08    ; BS
    je ._bs

    cmp al, 0x09    ; tab
    je ._tab

    jmp .ascii

.ext_key:
    cmp ah, 0x48    ; ↑ : History up
    je .up
    cmp ah, 0x50    ; ↓ : History down
    je .down
    jmp .loop2

.ascii:
    ; mov al, al
    mov ah, svc_putchar
    int 0x80
    mov [di], al

    inc di
    inc byte [.cnt]

    jmp .loop2

.up:
    dec byte [hisp]
    js .up_worp
    jmp .exit

.up_worp:
    mov byte [hisp], 3
    jmp .exit

.down:
    inc byte [hisp]
    cmp byte [hisp], 4
    jl  .exit
    mov byte [hisp], 0
    jmp .exit
    
    
.exit:    
    cmp byte [.cnt], 250    ; バッファサイズ上限チェック (250文字まで)
    jae .loop2              ; 上限なら入力を無視してループへ
    
    xor cx, cx
    mov cl, [.cnt]
    call clear_line

    xor ax, ax
    mov al, [hisp]
    mov bx, line_buf_size
    mul bx
    mov si, hibuf
    add si, ax
    mov ah, svc_write
    int 0x80

    mov ax, line_buf
    mov bl, 0
    mov cx, line_buf_size
    call memset
    
    mov ax, line_buf
    mov bx, si
    call strcpy
    mov [.cnt], cl
    mov di, line_buf
    add di, cx        ; CX = strlen

    jmp .loop2

._bs:
    cmp byte [.cnt], 0
    je .loop2
    
    dec byte [.cnt]
    dec di

; 画面上の削除処理 (BS -> 空白 -> BS)
    mov al, 0x08
    mov ah, svc_putchar
    int 0x80                ; カーソル戻す
    
    mov al, ' '
    mov ah, svc_putchar
    int 0x80                ; 空白で文字を消す
    
    mov al, 0x08
    mov ah, svc_putchar
    int 0x80                ; カーソルを再度戻す

    jmp .loop2

._tab:
    ; tabで現在の履歴バッファの内容を反映
    ; 直前のコマンドをリピートしたいときに便利
    jmp .exit

._0d:
    xor ax, ax
    mov al, [hisp]
    mov bx, line_buf_size
    mul bx
    mov si, hibuf
    add si, ax
    mov ax, si
    mov bl, 0
    mov cx, line_buf_size
    call memset

    mov ax, si
    mov bx, line_buf
    call strcpy

    mov ah, svc_newline
    int 0x80
    mov byte [.cnt], 0
    mov di, line_buf
    
    ret


.cnt db 0

hibuf:          ; history buffer
    db 'one',  0, 0, 0
    times 250 db 0
    db 'two',  0, 0, 0
    times 250 db 0
    db 'three',0
    times 250 db 0
    db 'four', 0, 0
    times 250 db 0

hisp: db 0


;********************************
; echo
;********************************
; IN : DI = buffer
; OUT: buffer filled, CX = length
; END: buffer is NUL-terminated
; CLOBBER: AX, CX, DI
echo:

.main_loop:

    ; --- ブロッキングで1キー待ち (AH=0x22) ---
    mov ah, svc_getkey  ; getkey_wait() -> AX=ASCII(0含む)
    int 0x80

    cmp al, 0x0d
    je ._0d

    test al, al
    jz .skip_echo
    
    mov al, al
    mov ah, svc_putchar
    int 0x80
    mov [di], al

    inc di
    inc byte [.cnt]

    jmp .main_loop

._0d:

    mov byte [di], 0x00
    xor cx, cx
    mov byte cl, [.cnt]

    cmp cl, 0
    je .skip_echo
    
    mov ah, svc_newline
    int 0x80

.skip_echo:

    ret

.cnt db 0

line_buf: times line_buf_size db 0


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

%include 'common.asm'

; ---- data ----
msg_hello:    db 'Hello from APP', 13, 10, 0

msg_wait:     db 'Press any key to return Monitor...', 13, 10, 0

msg_nl:       db 13, 10, 0

keybuf:       times 2 db 0

times 3072-($-$$) db 0