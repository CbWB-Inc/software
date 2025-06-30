org 0x7c00
bits 16

start:
    cli

    ; セグメント初期化
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7c00

    ; IRQ0 の割り込みベクタ設定
    mov word [0x08 * 4], irq0_handler
    mov word [0x08 * 4 + 2], cs

    ; PIT 初期化（IRQ0, 約18.2Hz）
    mov al, 0x36
    out 0x43, al
    mov ax, 0x1000
    out 0x40, al
    mov al, ah
    out 0x40, al

    ; PIC マスク（IRQ0 だけ許可）
    mov al, 0b11111110
    out 0x21, al
    mov al, 0xff
    out 0xa1, al

    ; 初期タスク設定
    mov word [current_task], 0

    ; デバッグ出力
    mov ah, 0x0e
    mov al, '?'
    int 0x10

    ; task1をコピー
    mov si, task1
    mov ax, 0x1000
    mov es, ax
    xor di, di
    mov cx, task1_end - task1
    cld
    rep movsb

    ; task2をコピー
    mov si, task2
    mov ax, 0x2000
    mov es, ax
    xor di, di
    mov cx, task2_end - task2
    cld
    rep movsb

    ; task3をコピー
    mov si, task3
    mov ax, 0x3000
    mov es, ax
    xor di, di
    mov cx, task3_end - task3
    cld
    rep movsb

    ; 現在のタスク index = 0
    mov word [current_task], 0

    sti
    jmp $

; タスクテーブル（3つのタスク）
task_table:
    dw task1_seg, task1_off
    dw task2_seg, task2_off
    dw task3_seg, task3_off

task_count: equ 3
current_task: dw 0

; 割り込みハンドラ
irq0_handler:
    push ax
    push bx
    push dx
    
    ; デバッグ出力
    mov ah, 0x0e
    mov al, '!'
    int 0x10

    ; タスクインデックス更新
    mov bx, [current_task]
    inc bx
    cmp bx, task_count
    jl .store
    mov bx, 0
.store:
    mov [current_task], bx
    
    ; EOI送信
    mov al, 0x20
    out 0x20, al

    ; タスクのセグメントとオフセット取得
    mov si, bx
    shl si, 2                ; si *= 4 (2ワード分)
    mov dx, [task_table + si]      ; segment
    mov ax, [task_table + si + 2]  ; offset

    push dx
    push ax
    retf

    ; dx:ax で jmp far
    ; 方法：メモリに一時保存して、そこを jmp far で使う
;    mov [jmp_ptr], ax
;    mov [jmp_ptr+2], dx
;    db 0xEA                  ; jmp far ptr 命令
;jmp_ptr:
;    dw 0x0000                ; offset
;    dw 0x0000                ; segment



; タスク1
task1:
    sti
.loop1:
    mov ah, 0x0e
    mov al, '1'
    int 0x10
    hlt
    jmp .loop1
task1_end:

task1_seg: dw 0x1000
task1_off: dw task1

; タスク2
task2:
    sti
.loop2:
    mov ah, 0x0e
    mov al, '2'
    int 0x10
    hlt
    jmp .loop2
task2_end:

task2_seg: dw 0x2000
task2_off: dw task2

; タスク3
task3:
    sti
.loop3:
    mov ah, 0x0e
    mov al, '3'
    int 0x10
    hlt
    jmp .loop3
task3_end:

task3_seg: dw 0x3000
task3_off: dw task3




; -------------------------------
; 画面に1文字表示
; -------------------------------
putc:
    mov ah, 0x0e
    int 0x10
    ret

; -------------------------------
; AXの内容（16bit）を16進で表示（4桁）
; -------------------------------
print_hex_word:
    pusha
    mov bx, ax

    ; 桁1
    mov ax, bx
    shr ax, 12
    and al, 0x0F
    call hex_digit

    ; 桁2
    mov ax, bx
    shr ax, 8
    and al, 0x0F
    call hex_digit

    ; 桁3
    mov ax, bx
    shr ax, 4
    and al, 0x0F
    call hex_digit

    ; 桁4
    mov ax, bx
    and al, 0x0F
    call hex_digit

    popa
    ret

hex_digit:
    cmp al, 10
    jl .digit
    add al, 'A' - 10
    jmp .emit
.digit:
    add al, '0'
.emit:
    call putc
    ret


times 510 - ($ - $$) db 0
dw 0xaa55
