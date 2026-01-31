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
    PUTC 'L'
    PUTC 'S'
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

    call exp_ls

    push cs
    pop ds

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

exp_ls:
    ; ===== BUFとして1ページを割り当て =====
    mov ah, svc_page_alloc
    int 0x80
    jc .alloc_error

    ; バッファ情報を控えておく
    shl dx, 12
    mov [BUF_SEG], dx
    mov [BUF_OFF], ax

    xor ax, ax
    mov es, ax
    ; 各種パラメータの取得
    ; -----------------------------------
    ; Bootドライブ
    ; -----------------------------------
    mov al, es:[BOOT_DRV_OFF]
    mov [BOOT_DRIVE], al
    ; -----------------------------------
    ; DIR_LBA
    ; -----------------------------------
    mov ax, es:[DIR_START_LBA]
    mov [DIR_LBA], ax
    ; -----------------------------------
    ; ROOT_ENT_CNT
    ; -----------------------------------
    mov ax, es:[ROOT_ENT_CNT_OFF]
    mov [ROOT_ENT_CNT], ax
    ; -----------------------------------
    ; BYTE_PER_SEC
    ; -----------------------------------
    mov ax, es:[BYTE_PER_SEC_OFF]
    mov [BYTE_PER_SEC], ax
    ; -----------------------------------
    ; rootのセクタ数を算出
    ; -----------------------------------
    mov ax, [ROOT_ENT_CNT]
    mov bx, 32
    mul bx
    mov bx, [BYTE_PER_SEC]
    div bx
    mov [DIR_ENT_SEC_CNT], ax

    mov bx, BUF_SEG
    mov es, bx

    ; ヘッダのの表示
    mov si, ._s_head1
    mov ah, svc_write
    int 0x80
    mov si, ._s_head2
    mov ah, svc_write
    int 0x80

.dir_ent_sec_loop:

    ; -----------------------------------
    ; Dir Entを読み込む
    ; -----------------------------------
    mov si, dap
    mov word [si + DAP.NumBlocks], ENT_SECTORS ; sectors
    mov word [si + DAP.BufferOff], BUF_OFF     ; buffer offset
    mov word [si + DAP.BufferSeg], BUF_SEG     ; buffer segment
    mov ax, [DIR_LBA]
    mov word [si + DAP.LBA_Low],   ax ; LBA low Low
    mov dword [si + DAP.LBA_High],  0 ; LBA high
    mov dl, ds:[BOOT_DRIVE]

    mov ah, 0x42
    int 0x13

    jc .disk_error

    mov di, BUF_OFF
    mov cx, 16          ; Byte/Ent

.entry_loop:
    ; ファイル、ディレクトリ以外を除外
    mov al, es:[di]
    cmp al, 0x00
    je .not_found
    cmp al, 0xE5
    je .next_entry
    mov al, es:[di+11]
    test al, 0x08          ; Volume
    jnz .next_entry

    ; ファイル名の表示
    mov dx, 11
    push di
.file_name_loop:
    ; mov ah, svc_putchar
    ; mov al, es:[di]
    ; int 0x80
    ; mov ah, 0x0e
    ; mov al, es:[di]
    ; int 0x10
    mov al, es:[di]
    call pc
    inc di
    dec dx
    cmp dx, 0
    jne .file_name_loop

    mov al, ' '
    call pc

    pop di

    ; ディレクトリなら<DIR>を表示
    mov al, es:[di+DIR_ENTRY.Attr]
    test al, 0x10          ; dir
    jz .dir_skip
    mov ax, ._s_dir
    call ps
    jmp .file_skip
.dir_skip:
    mov al, ' '
    call pc
    ; ファイルならサイズを表示
    test al, 0x20          ; file
    jz .file_skip
    mov ax, es:[di+DIR_ENTRY.FileSize]
    call ph4
    
.file_skip:
    mov ah, svc_newline
    int 0x80

.next_entry:
    add di, 32
    loop .entry_loop
.next_sec:
    mov ax, [DIR_LBA]
    inc ax
    mov [DIR_LBA], ax
    mov ax, [DIR_ENT_SEC_CNT]
    dec ax
    mov [DIR_ENT_SEC_CNT], ax
    cmp ax, 0
    jnz .dir_ent_sec_loop

    jmp .skip

.alloc_error:
    PUTC 'E'
    PUTC 'r'
    PUTC 'r'
    jmp .skip

.disk_error:
    PUTC 'E'
    PUTC 'r'
    PUTC 'r'

.not_found:

.skip:
    ; ===== BUFを開放 =====
    mov dx, [BUF_SEG]
    shr dx, 12
    mov bx, [BUF_OFF]
    mov ah, svc_page_free
    int 0x80

    ret

._s_head1: db '    NAME     SIZE', 0x0d, 0x0a, 0x00
._s_head2: db '-----------+------', 0x0d, 0x0a, 0x00
._s_dir: db '<DIR>', 0x00
.i64hs:
    times 4 dw 0
.phs:
    times 20 db 0
    dw 0
    db 0

%include 'common.asm'
%include 'bcdlib.asm'

; ---- data ----
msg_hello:    db 'Hello from LS', 13, 10, 0

msg_wait:     db 'Press any key to return shell...', 13, 10, 0

msg_nl:       db 13, 10, 0

keybuf:       times 2 db 0

BOOT_DRIVE db 0
DIR_LBA dw 0
ROOT_ENT_CNT dw 0
BYTE_PER_SEC dw 0
DIR_ENT_SEC_CNT dw 0

align 16
dap:                ; 
    db 0x10, 0x00   ; size / reserved
    dw 0            ; sectors
    dw 0x0000       ; buffer offset
    dw 0x0          ; buffer segment
    dq 0x0          ; LBA (low=2048, high=0)


