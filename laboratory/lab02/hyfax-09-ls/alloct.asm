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

extern exit_return
extern phd1
extern phd2
extern phd4
    extern func
    extern ps

start:
    PUTC 'A'
    PUTC ':'

    ; --- COMライク初期化（CS=DS=ES=SS=自分、SP設定） ---
    push cs
    pop  ds
    push cs
    pop  es

    mov ah, svc_putchar
    mov al, 0x0d
    int 0x80

    ; --- メッセージ表示 ---
    mov si, msg_hello
    mov ah, 0x20              ; write(DS:SI, CX)
    int 0x80

    mov ah, svc_newline
    int 0x80
    PUTC 0x0d
    PUTC 0x0a

    mov si, mhs

    mov ah, svc_page_dump
    int 0x80
    PUTC 0x0d
    PUTC 0x0a

    ; ===== 3ページを割り当て =====
    mov ah, svc_page_alloc
    int 0x80
    ; DX:AX = 4KB aligned physical address
    mov [si + MHS.AXs + 0], ax
    mov [si + MHS.DXs + 0], dx
    mov word [si + MHS.cnt], 2
    PUTC '['
    call phd4
    PUTC ':'
    mov ax, dx
    call phd4
    PUTC ']'

    mov ah, svc_page_alloc
    int 0x80
    ; DX:AX = 4KB aligned physical address
    mov [si + MHS.AXs + 2], ax
    mov [si + MHS.DXs + 2], dx
    mov word [si + MHS.cnt], 4
    PUTC '['
    call phd4
    PUTC ':'
    mov ax, dx
    call phd4
    PUTC ']'
    
    mov ah, svc_page_alloc
    int 0x80
    ; DX:AX = 4KB aligned physical address (最後のページ)
    mov [si + MHS.AXs + 4], ax
    mov [si + MHS.DXs + 4], dx
    mov word [si + MHS.cnt], 6
    ; 最後に割り当てたページのアドレスを保存
    push dx          ; 上位ワードを保存
    push ax          ; 下位ワードを保存

    PUTC '['
    call phd4
    PUTC ':'
    mov ax, dx
    call phd4
    PUTC ']'
    

    mov ah, svc_page_dump
    int 0x80
    PUTC 0x0d
    PUTC 0x0a

    ; ===== 最後のページを解放 =====
    ; DX:AXをDX:BXに移動してからsyscallを呼ぶ
    pop bx           ; 下位ワードをBXに復元
    pop dx           ; 上位ワードをDXに復元
    ; この時点で DX:BX に解放するアドレスがセットされている
    
    mov ah, svc_page_free
    int 0x80
    ; AX = 0 (成功) or 1 (失敗)

    ; 結果を表示（デバッグ用）
    ; mov bx, ax
    ; mov ah, 0x21        ; svc_puthex
    ; int 0x80
    ; PUTC 0x0d
    ; PUTC 0x0a

    mov ah, svc_page_dump
    int 0x80
    PUTC 0x0d
    PUTC 0x0a

    mov word [si + MHS.cnt], 4
    mov bx, [si + MHS.AXs + 2]
    mov dx, [si + MHS.DXs + 2]
    mov ah, svc_page_free
    int 0x80
    ; AX = 0 (成功) or 1 (失敗)
    PUTC '['
    mov ax, bx
    call phd4
    PUTC ':'
    mov ax, dx
    call phd4
    PUTC ']'

    mov word [si + MHS.cnt], 2
    mov bx, [si + MHS.AXs + 0]
    mov dx, [si + MHS.DXs + 0]
    mov ah, svc_page_free
    int 0x80
    ; AX = 0 (成功) or 1 (失敗)
    PUTC '['
    mov ax, bx
    call phd4
    PUTC ':'
    mov ax, dx
    call phd4
    PUTC ']'

    mov ah, svc_page_dump
    int 0x80
    PUTC 0x0d
    PUTC 0x0a


    mov si, msg_wait
    mov ah, svc_write
    int 0x80

.clear_kbd
    mov ah, 0x01      ; キー有無チェック
    int 0x16
    jz  .getkey_done         ; ZF=1 → バッファ空

    mov ah, 0x00      ; 1文字読み捨て
    int 0x16
    jmp .clear_kbd

.getkey_done:



    mov ah, svc_getkey
    int 0x80
    xor ax, ax


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

; ---- data ----
msg_hello:    db 'Hello from ALLOCT', 13, 10, 0

msg_hello2:    db 'Hello from APP func', 13, 10, 0
msg_hello3:    db 'Hello from APP ps', 13, 10, 0


msg_wait:     db 'Press any key to return shell...', 13, 10, 0

msg_nl:       db 13, 10, 0

keybuf:       times 2 db 0

mhs times 129 dw 0

times 3072-($-$$) db 0
