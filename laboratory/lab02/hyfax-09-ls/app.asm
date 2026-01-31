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

start:
    PUTC 'A'
    PUTC ':'

    ; --- COMライク初期化（CS=DS=ES=SS=自分、SP設定） ---
    push cs
    pop  ds
    push cs
    pop  es

    ; --- メッセージ表示 ---
    mov si, msg_hello
    mov ah, 0x20              ; write(DS:SI, CX)
    int 0x80

    mov ah, svc_newline
    int 0x80

    mov si, msg_wait
    mov ah, svc_write
    int 0x80

    mov ah, svc_getkey
    int 0x80


exit:
    ; call exit_return

    ; --- モニタへ戻る ---
    ; 既定：MON_SEG:0000 に戻る（monitor側の戻り口が0x0000想定）
    ; push word MON_SEG
    ; mov ax, 0
    push word TTS_SEG
    push word 0x0000
    retf
    

    ; 別戻り先にしたい場合（monitor側に monitor_restart がある等）：
    ; mon_ret_ptr: dw monitor_restart, MON_SEG
    ; jmp  far [mon_ret_ptr]

; %include 'common.asm'

; ---- data ----
msg_hello:    db 'Hello from APP', 13, 10, 0

msg_hello2:    db 'Hello from APP func', 13, 10, 0
msg_hello3:    db 'Hello from APP ps', 13, 10, 0


msg_wait:     db 'Press any key to return shell...', 13, 10, 0

msg_nl:       db 13, 10, 0

keybuf:       times 2 db 0

times 3072-($-$$) db 0