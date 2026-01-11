BITS 16
org 0x0000

%include 'hyfax.asm'

%define MON_SEG  0x0050        ; monitor側のセグメント（monitor.asmと合わせる）

%macro PUTC 1
    push ax
    mov al, %1
    out 0xE9, al
    pop ax
%endmacro

start:
    PUTC 'T'
    PUTC ':'

    ; --- COMライク初期化（CS=DS=ES=SS=自分、SP設定） ---
    ; mov ax, 0x1000
    ; mov ds, ax
    push cs
    pop  ds
    push cs
    pop  es
    push cs
    pop  ss
    mov  sp, 0xfffe

    mov bx, ax

    ; --- メッセージ表示 ---
    mov si, msg_hello
    mov ah, svc_write              ; write(DS:SI, CX)
    int 0x80
    mov ah, svc_newline
    int 0x80

    ; 入力バッファの初期化
    mov ax, line_buf
    mov bl, 0
    mov cx, line_buf_size
    call memset


.loop1:
    mov di, line_buf        ; バッファの準備
    call line_input         ; 行入力

    xor cx, cx              ; 0文字なら何もしない
    mov ax, line_buf
    call strlen
    cmp cx, 0
    je .skip

    ; 入力文字列をパース
    ; DS:SI = 入力文字列
    ; ES:DI = THS 構造体先頭
    ; al    = 区切り文字
    mov si, line_buf
    mov di, line_buf_ths
    mov al, ' '
    call split

    ; 第一パラメータを大文字変換
    mov ax, [line_buf_ths + THS.off + 0]
    call ucase

    ; ファイル名候補を抽出
    mov ax, file_name
    mov bx, [line_buf_ths + THS.off + 0]
    call strcpy   
    
    ; 内部コマンドかどうかを判定
    ; 内部コマンドならそれを実行
    ; 現在は内部コマンドがないので未処理
    
    ; パースした最初がファイル名なのでこれを送る
    mov bx, di          ; di = line_buf_ths
    mov si, [line_buf_ths]
    mov ah, svc_exec
    int 0x80

    ; エラー判定
    cmp ax, 0
    je .nf_skip2
    push ds
    mov ax, TTS_SEG
    mov ds, ax

    ; エラーならエラーメッセージを表示
    mov si, ._s_msg_nf
    mov ah, svc_write
    int 0x80
    pop ds
.nf_skip2:

    ; バッファのクリア
    mov ax, line_buf        
    mov bl, 0
    mov cx, cx
    call memset

.skip:
    jmp .loop1

.exit:
    ; call exit_return

    ; --- モニタへ戻る ---
    ; 既定：MON_SEG:0000 に戻る（monitor側の戻り口が0x0000想定）
    push word MON_SEG
    push word 0x0000
    retf
    
    ret             ; 無限ループなのでここには来ない

._s_msg_nf db 'Bad command or file name', 0x0d, 0x0a, 0x0d, 0x0a, 0x00

.temp_buf times 32 db 0

.temp_file_name db 32, 0


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


line_buf: times line_buf_size db 0


%include 'common.asm'
; %include 'loadapp.asm'

; ---- data ----

msg_hello:    db 'Hello from TTS', 13, 10, 0

; keybuf:       times 2 db 0

hisp: db 0

_s_msg_test1 db 'TEST STRING 1', 0x0d, 0x0a, 0x00

hibuf:          ; history buffer
    db 'one',  0, 0, 0
    times 250 db 0
    db 'two',  0, 0, 0
    times 250 db 0
    db 'three',0
    times 250 db 0
    db 'four', 0, 0
    times 250 db 0

_s_msg_test2 db 'TEST STRING 2', 0x0d, 0x0a, 0x00

; times 4096-($-$$) db 0