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

    ; --- メッセージ表示 ---
    mov si, msg_hello
    mov ah, svc_write              ; write(DS:SI, CX)
    int 0x80

    mov ah, svc_newline
    int 0x80

.loop1:
    mov di, line_buf        ; バッファの準備
    call line_input         ; historyの実行

    xor cx, cx              ; 0文字なら何もしない
    mov ax, line_buf
    call strlen
    cmp cx, 0
    je .skip

; DS:SI = 入力文字列
; ES:DI = THS 構造体先頭
; al    = 区切り文字

    ; 入力文字列をパース
    ; mov ax, ds
    ; mov es, ax
    mov si, line_buf
    mov di, line_buf_ths
    mov al, ' '
    call split

    ; ファイル名候補を抽出
    mov ax, file_name
    mov bx, [line_buf_ths + THS.off + 0]
    call strcpy   
    
    ; 内部コマンドかどうかを判定
    ; 内部コマンドならそれを実行
    ; 現在は内部コマンドがないので未処理
    
    ; 83形式に変換
    call to_83  

    ; mov al, '1'
    ; mov ah, svc_putchar
    ; int 0x80
    ; mov al, '['
    ; mov ah, svc_putchar
    ; int 0x80
    ; mov si, file_name
    ; mov ah, svc_write
    ; int 0x80
    ; mov al, ']'
    ; mov ah, svc_putchar
    ; int 0x80
    ; mov ah, svc_newline
    ; int 0x80

    mov ax, file_name
    ; mov ax, .temp_file_name
    call runapp
    mov si, ._s_msg_nf
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

.exit:
    ; call exit_return

    ; --- モニタへ戻る ---
    ; 既定：MON_SEG:0000 に戻る（monitor側の戻り口が0x0000想定）
    push word MON_SEG
    push word 0x0000
    retf
    
    ret             ; 無限ループなのでここには来ない

._s_msg_nf db 'Bad command or file name', 0x0d, 0x0a, 0x00

.temp_buf times 32 db 0

.temp_file_name db 'APP     BIN', 0x00


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

    ; ; === デバッグ表示: base ===
    ; mov al, '2'
    ; mov ah, svc_putchar
    ; int 0x80
    ; mov al, '['
    ; mov ah, svc_putchar
    ; int 0x80
    ; mov si, [.base]
    ; mov ah, svc_write
    ; int 0x80
    ; mov al, ']'
    ; mov ah, svc_putchar
    ; int 0x80
    ; mov ah, svc_newline
    ; int 0x80
    
    ; ; === デバッグ表示: ext ===
    ; mov al, '3'
    ; mov ah, svc_putchar
    ; int 0x80
    ; mov al, '['
    ; mov ah, svc_putchar
    ; int 0x80
    ; mov si, [.ext]
    ; mov ah, svc_write
    ; int 0x80
    ; mov al, ']'
    ; mov ah, svc_putchar
    ; int 0x80
    ; mov ah, svc_newline
    ; int 0x80

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

    ; ; === デバッグ表示: temp_buf ===
    ; mov al, '4'
    ; mov ah, svc_putchar
    ; int 0x80
    ; mov al, '['
    ; mov ah, svc_putchar
    ; int 0x80
    ; mov si, .temp_buf
    ; mov ah, svc_write
    ; int 0x80
    ; mov al, ']'
    ; mov ah, svc_putchar
    ; int 0x80
    ; mov ah, svc_newline
    ; int 0x80

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
file_name_ths times 128 dw 0 
line_buf_ths times 128 dw 0
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
    ; mov ax, ds
    ; mov [di + THS.seg], ax
    ret

.dlm db 0

;************************************
; ファイル名からAPPをロードして実行する
;     ax : ファイル名
;************************************
runapp:
    mov si, ax

    ; ; === デバッグ表示: temp_buf ===
    ; mov al, '5'
    ; mov ah, svc_putchar
    ; int 0x80
    ; mov al, '['
    ; mov ah, svc_putchar
    ; int 0x80
    ; ; mov si, .temp_buf
    ; mov ah, svc_write
    ; int 0x80
    ; mov al, ']'
    ; mov ah, svc_putchar
    ; int 0x80
    ; mov ah, svc_newline
    ; int 0x80


PUTC '!'

    mov ah, svc_newline
    int 0x80
    
    mov ax, APP_SEG
    mov es, ax
    mov bx, APP_OFF
    mov ax, si
PUTC '*'

    call loadapp
PUTC '*'

    ; === loadapp の戻り値チェック ===
    jc .load_failed         ; CF=1 なら失敗

    ; === 成功: APPを実行 ===
    jmp APP_SEG:APP_OFF

.load_failed:
    ; === 失敗: エラーメッセージを表示して戻る ===
    PUTC 'F'
    PUTC 'A'
    PUTC 'I'
    PUTC 'L'
    ret

.target_name: db 'APP     BIN', 0x00

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

hlt:
    hlt
    jmp hlt


%include 'common.asm'
%include 'loadapp.asm'

; ---- data ----

msg_hello:    db 'Hello from TTS', 13, 10, 0

msg_wait:     db 'Press any key to return Monitor...', 13, 10, 0

msg_nl:       db 13, 10, 0

keybuf:       times 2 db 0

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