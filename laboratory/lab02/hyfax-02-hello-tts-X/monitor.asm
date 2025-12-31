; ============================================================================
; monitor.asm
; バッファ = 09e0:0000, DLはブートからの値をそのまま使用
; 制約: FAT16フォーマットのみ対応（FATsz16 != 0 必須）
; ============================================================================
BITS 16
SECTION .text

jmp start

%include 'hyfax.asm'

; ---------------- デバッグ出力 ----------------
%macro PUTC 1
  push ax
  mov  al,%1
  out  0xE9,al
  pop  ax
%endmacro

global start 

; ---------------- 本体 ----------------
start:
    PUTC 'M'
    PUTC ':'
    cli
    mov ax, STACK_SEG
    mov ss, ax
    mov sp, 0xE000
    sti

    mov ax, MON_SEG
    mov ds, ax
    mov es, ax

    call install_int80

    mov si, _s_msg_monitor
    mov ah, 0x20              ; write(DS:SI, CX)
    int 0x80

    mov ax, TTS_SEG
    mov es, ax
    ; mov ds, ax
    mov bx, TTS_OFF
    mov ax, _s_target_name
    
    call loadapp

    jmp TTS_SEG:TTS_OFF

    jmp hlt

hlt:
    hlt
    jmp hlt

; =====================================================================
;  syscall.asm  (INT 80h 拡張版)
; =====================================================================

BITS 16
SECTION .text

; ------------------------------------------------------------
; install_int80: INT80h のハンドラを IVT に登録
; ------------------------------------------------------------
install_int80:
    cli
    push ax
    push bx
    push es

    xor ax, ax
    mov es, ax                ; IVTセグメント
    mov bx, 0x80*4            ; INT80hエントリ番地
    mov word [es:bx], int80_handler
    mov word [es:bx+2], MON_SEG  ; モニタのCS値

    pop es
    pop bx
    pop ax
    sti
    ret

; ------------------------------------------------------------
; INT80h ハンドラ本体
; ------------------------------------------------------------
int80_handler:
    ; push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp
    push ds
    push es

    cmp ah, 0x20
    je  .svc_write
    cmp ah, 0x21
    je  .svc_puthex
    cmp ah, 0x22
    je  .svc_getkey
    cmp ah, 0x23
    je  .svc_putchar
    cmp ah, 0x24
    je  .svc_newline
    cmp ah, 0x25
    je  .svc_cls
    cmp ah, 0x26
    je  .svc_reboot
    jmp .svc_exit

; ------------------------------------------------------------
.svc_write:                      ; AH=20h : write string DS:SI (0終端)
    mov bx, 0x0007
    mov ah, 0x0E
.w_loop:
    lodsb
    test al, al
    jz .svc_exit
    int 0x10
    jmp .w_loop

; ------------------------------------------------------------
.svc_puthex:                     ; AH=21h : BXを16進で出力
    push bx
    mov al, bh
    call phd2
    pop bx
    mov al, bl
    call phd2
    jmp .svc_exit

; ------------------------------------------------------------
.svc_getkey:                     ; AH=22h : キー入力待ち (ALに返す)
    xor ax, ax
    int 0x16
    jmp .svc_iret

; ------------------------------------------------------------
.svc_putchar:                    ; AH=23h : ALを1文字出力
    mov ah, 0x0E
    mov bx, 0x0007
    int 0x10
    jmp .svc_exit

; ------------------------------------------------------------
.svc_newline:                    ; AH=24h : 改行(CR+LF)
    mov ah, 0x0E
    mov al, 0x0D
    int 0x10
    mov al, 0x0A
    int 0x10
    jmp .svc_exit

; ------------------------------------------------------------
.svc_cls:                        ; AH=25h : 画面クリア
    mov ax, 0x0003
    int 0x10
    jmp .svc_exit

; ------------------------------------------------------------
.svc_reboot:                     ; AH=26h : 再起動
    ; jmp 0FFFFh:0000h
    cli

.wait_kbc:
    in   al, 0x64
    test al, 0x02
    jnz  .wait_kbc

    mov  al, 0xFE
    out  0x64, al

    hlt
; ------------------------------------------------------------
.svc_exit:
.svc_iret:
    pop es
    pop ds
    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    ; pop ax
    iret


%include 'loadapp.asm'
%include 'common.asm'

_s_msg_monitor db 'Hello from Monitor', 0x0d, 0x0a, 0x00
_s_msg_wait:   db 'Press any key to continue...', 0x0d, 0x0d, 0

_s_target_name db 'TTS     BIN', 0x00

times 1280-($-$$) db 0