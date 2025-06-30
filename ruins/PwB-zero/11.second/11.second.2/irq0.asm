; irq0.asm
org 0x0000
bits 16

irq0_handler:
    pusha
    push ds
    push es
    push fs
    push gs
    pushf
    cli

	mov ah, 0x0e
	mov al, '$'
	int 0x10


    ; -----------------------------
    ; 現在のタスクを保存（DS:SIにcurrent_task指定）
    ; -----------------------------
    mov ax, [current_task_seg]
    mov ds, ax
    mov si, [current_task_off]

    mov [si], sp
    mov [si+2], ss
    mov bx, [cs_saved]
    mov [si+4], word bx
    mov bx, [ip_saved]
    mov [si+6], word bx

    ; -----------------------------
    ; スケジューリング
    ;  task1: weight 1（task_counter==0）
    ;  task2: weight 3（task_counter==1〜3）
    ; -----------------------------
    mov ax, 0x2000
    mov ds, ax
    inc byte [task_counter]
    cmp byte [task_counter], 4
    jne .skip_reset
    mov byte [task_counter], 0
.skip_reset:

    ; 切り替え先決定
    cmp byte [task_counter], 0
    jne .select_task2

.select_task1:
    mov ax, [task1_seg]
    mov bx, [task1_off]
    jmp .switch

.select_task2:
    mov ax, [task2_seg]
    mov bx, [task2_off]
    ; fallthrough

.switch:
    mov [current_task_seg], ax
    mov [current_task_off], bx

    ; -----------------------------
    ; 新タスクの状態を復元
    ; -----------------------------
    mov ds, ax
    mov si, bx

    mov sp, [si]
    mov ss, [si+2]
    mov cx, [si+4]
    mov dx, [si+6]

    popf
    pop gs
    pop fs
    pop es
    pop ds
    popa

    ; PICへのEOI
    mov al, 0x20
    out 0x20, al

    mov [temp_jmp_off], cx
    mov [temp_jmp_seg], dx

    jmp far [temp_jmp]

; --- 割り込み侵入時のIP,CSを退避する用（セットは外部） ---
;-------------------------------
; 定義類
;-------------------------------
; タスク切替用カウンタとポインタ類
current_task_seg dw 0
current_task_off dw 0

task1_seg dw 0x3000
task1_off dw task1_ctx
task1_ctx dw 0x0003


task2_seg dw 0x3400
task2_off dw task2_ctx
task2_ctx dw 0x0003

; スケジューリング用
task_counter db 0  ; 0〜3の繰り返し

cs_saved dw 0
ip_saved dw 0

temp_jmp :
temp_jmp_off: dw 0
temp_jmp_seg: dw 0
