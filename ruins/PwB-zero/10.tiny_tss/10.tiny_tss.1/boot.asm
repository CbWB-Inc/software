org 0x7c00
bits 16

jmp start

; -------------------------------
; タスク1（A出力）
; -------------------------------
task1:
.loop1:
    sti
    mov al, 'A'
    call putc
    hlt
    jmp .loop1

; -------------------------------
; タスク2（B出力）
; -------------------------------
task2:
.loop2:
    sti
    mov al, 'B'
    call putc
    hlt
    jmp .loop2

; -------------------------------
; 疑似TSS構造体
; -------------------------------
current_task       dw 0

task1_context:
task1_sp           dw 0
task1_cs           dw 0
task1_ip           dw 0

task2_context:
task2_sp           dw 0
task2_cs           dw 0
task2_ip           dw 0

task_switch_jump:
    dw 0
    dw 0

; -------------------------------
; メイン処理開始
; -------------------------------
start:
    cli
    
    ;mov ax, task1
    ;call print_hex_word
    ;mov ax, task2
    ;call print_hex_word

    cli
    xor ax, ax
    mov ds, ax
    mov es, ax

    call init_jump

    
    ; タスク1と2の初期化
    mov word [task1_ip], task1
    mov word [task1_cs], cs
    mov word [task1_sp], 0x7000

    mov word [task2_ip], task2
    mov word [task2_cs], cs
    mov word [task2_sp], 0x6800

    mov word [current_task], task1_context

    sti

    ; PIT 初期化（100Hz）
    mov al, 0x36
    out 0x43, al
    mov ax, 1193
    out 0x40, al
    mov al, ah
    out 0x40, al

    ; 割り込みベクタの設定
    push es
    xor ax, ax
    mov es, ax
    mov ax, cs
    mov [es:0x22], ax
    mov word [es:0x20], irq0_handler
    pop es

    ; PIC 初期化（マスタ・スレーブ）
    mov al, 0x11
    out 0x20, al
    mov al, 0x08
    out 0x21, al
    mov al, 0x04
    out 0x21, al
    mov al, 0x01
    out 0x21, al

    mov al, 0x11
    out 0xA0, al
    mov al, 0x70
    out 0xA1, al
    mov al, 0x02
    out 0xA1, al
    mov al, 0x01
    out 0xA1, al

    ; IRQ0 のみ許可
    in  al, 0x21
    and al, 0xFE
    out 0x21, al

    sti

main_loop:
    hlt
    jmp main_loop

; -------------------------------
; IRQ0 ハンドラ → タスク切り替え
; -------------------------------
irq0_handler:
    pusha
    push ds

;    mov al, '!'
;    call putc

    ; タスク種別出力
;    cmp si, task1_context
;    je .print1
;    mov al, '2'
;    call putc
;    jmp .cont
;.print1:
;    mov al, '1'
;    call putc
;.cont:

    ; EOI
    mov al, 0x20
    out 0x20, al

    ; context 保存
    mov ax, cs
    mov ds, ax
    mov si, [current_task]

    ;mov [si], sp
    ;mov word [si+2], cs
    ;mov word [si+4], .return_here

    ; タスク切り替え
    cmp si, task1_context
    je .switch_to_task2
    mov si, task1_context
    jmp .done_switch
.switch_to_task2:
    mov si, task2_context
.done_switch:
    mov [current_task], si

    ; context 復元
;mov sp, [si]
;mov ax, [si+2]
;call print_hex_word     ; ← CS
;mov ax, [si+4]
;call print_hex_word     ; ← IP

    mov sp, [si]
    push word [si+2]         ; CS
    push word [si+4]         ; IP
    ;mov ax, task1
    ;call print_hex_word
    retf

.return_here:
    cli
.halt_loop:
    hlt
    jmp .halt_loop

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

; -------------------------------
; 初期化サブルーチン
; -------------------------------
init_jump:
    mov word [task_switch_jump], irq0_handler
    mov word [task_switch_jump + 2], cs
    ret

; -------------------------------
; ブートセクタ終端
; -------------------------------
times 510 - ($ - $$) db 0
dw 0xAA55
