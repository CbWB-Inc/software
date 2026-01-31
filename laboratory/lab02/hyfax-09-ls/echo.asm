; echo.asm - simple and working version
BITS 16

%include 'hyfax.asm'

%macro PUTC 1
    push ax
    mov al, %1
    out 0xE9, al
    pop ax
%endmacro
    
start:
    PUTC 'E'
    PUTC 'C'
    PUTC 'H'
    PUTC 'O'
    PUTC ':'

    ; --- 通常の初期化 ---
    push cs
    pop  ds
    push cs
    pop  es

    ; ★★★ ths_offsetに保存 ★★★
    mov [ths_offset], bx
    ; push bx

    ; ; メッセージ表示
    ; mov si, msg_hello
    ; mov ah, svc_write
    ; int 0x80
    ; mov ah, svc_newline
    ; int 0x80

    ; TTS_SEGから引数の数を取得
    mov ax, TTS_SEG
    mov es, ax
    mov di, [ths_offset]
    mov cx, es:[di + THS.cnt]

    ; 引数が2つ以下（コマンド名のみ）なら何も表示しない
    cmp cx, 2
    jl .no_args
    
    ; 全ての引数を表示（1番目から）
    mov word [current_index], 1

    mov ah, svc_putchar
    mov al, 0x0d
    int 0x80

.loop:
    ; 現在のインデックスを取得
    mov si, [current_index]
    
    ; 終了判定
    mov ax, TTS_SEG
    mov es, ax
    mov di, [ths_offset]
    cmp si, es:[di + THS.cnt]
    jge .done
    
    ; 引数のオフセットを取得
    mov si, [current_index]
    mov bx, si
    shl bx, 1
    add bx, THS.off
    mov bx, es:[di + bx]        ; BX = 文字列のオフセット（TTS_SEG内）
    
    ; 文字列を表示（TTS_SEGから）
    mov ax, TTS_SEG
    mov ds, ax
    mov si, bx
    mov ah, svc_write
    int 0x80
    mov ah, svc_putchar
    mov al, ' '
    int 0x80
    
    ; DSを戻す
    push cs
    pop ds
    
    ; 次の引数へ
    inc word [current_index]
    jmp .loop


.no_args:
    mov ax, cs
    mov ds, ax
    mov ax, msg_no_args
    call ps

.done:
    mov ah, svc_putchar
    mov al, 0x0d
    int 0x80

    mov ah, svc_newline
    int 0x80
    mov ah, svc_newline
    int 0x80

exit:
    push word TTS_SEG
    push word 0x0000
    retf
    ; call  exit_return

%include 'common.asm'

; ---- data ----
ths_offset:       dw 0
current_index:    dw 0

msg_hello:        db 'Hello from ECHO', 13, 10, 0
msg_cnt:          db 'Arg count: ', 0
msg_idx:          db 'Index ', 0
msg_off:          db ' offset=', 0
msg_no_args:      db '(no arguments)', 0
msg_wait:         db 13, 10, 'Press any key to return shell...', 13, 10, 0


