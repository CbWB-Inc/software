org 0x0000
bits 16

jmp start

; -------------------------------
; タスク1（A出力）
; -------------------------------
task1:
.loop1:
    ;push ds
    cli
    mov ax, [si+8]
    ;mov ds, ax
    
    mov ah, 0x0e
    mov al, 'A'
    int 0x10
    ;pop ds
    sti
    hlt
    jmp .loop1

; -------------------------------
; タスク2（B出力）
; -------------------------------
task2:
.loop2:
    cli
    ;push ds
    mov ax, [si+8]
    ;mov ds, ax
    
    mov dx, [main_ds]
    ;mov ds, dx
    
    mov ah, 0x0e
    mov al, 'B'
    int 0x10
    
    ;pop ds
    sti
    hlt
    jmp .loop2

; -------------------------------
; タスク3（C出力）
; -------------------------------
task3:
.loop3:
    sti
    mov ah, 0x0e
    mov al, 'C'
    int 0x10
    hlt
    jmp .loop3

main_ds: dw 0x1000

; -------------------------------
; メイン処理開始
; -------------------------------
start:
    
    cli

    jmp $+3
    pop si
    mov ax, cs
    mov ds, ax
    mov es, ax
    mov [main_ds], ds

    ; タスク初期化
    call init_tasks
    
    
    mov ax, ds
    mov [main_ds] , ax

    ; current_task を ID(0〜2) に
    ;mov byte [current_task], 1

    mov ax, task1_context
    mov [current_task], ax

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


    ; 割り込み有効化後、初回だけ after_func を呼ぶ
    
    mov si, [current_task]
;    jmp after_func
    jmp irq0_handler
    
    
main_loop:
    hlt
    jmp main_loop

; タスクポインタ配列（offset, segment）
task_ptrs:
    dw task1, 0x1000
    dw task2, 0x1000
    dw task3, 0x1000

; -------------------------------
; IRQ0 ハンドラ → タスク切り替え
; -------------------------------
irq0_handler:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push ds
    push es

    call after_func

    pop es
    pop ds
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax

    push word 0x0200            ; FLAGS (IF=1)
    push word [temp_jmp+2]      ; CS
    push word [temp_jmp]        ; IP

    iret
    
after_func:
    cli

    ; 次のタスクへ切り替える（構造体アドレスを current_task に設定）
    call select_next_task

    ; SI ← current_task (構造体アドレス)
    mov si, [current_task]

    ; IP/CS を読み込み
    mov ax, [si+0x00]       ; IP
    mov bx, [si+0x02]       ; CS

    ; スタック切替 (SS:SP)
    mov dx, [si+0x18]       ; SS
    mov ss, dx
    mov dx, [si+0x1A]       ; SP
    mov sp, dx

    ; データセグメント切替 (DS)
    mov dx, [si+0x14]       ; DS
    mov ds, dx

    ; 割り込み復帰スタック構築（順序：IP, CS, FLAGS）
    push word 0x0200        ; FLAGS (IF=1)
    push bx                 ; CS
    push ax                 ; IP

    mov [temp_jmp], ax       ; IP
    mov [temp_jmp+2], bx     ; CS
    
    iret
;    cli
;    ; タスク切替
;    call select_next_task

;    ; current_task 番号を取得
;    mov al, [current_task]
;    movzx bx, al        ; BX = 0, 1, 2
;    shl bx, 2           ; BX *= 4（fwordサイズ）
;    mov si, task_ptrs
;    add si, bx

;    ; fword [si] = IP, CS
;    push word 0x0200       ; FLAGS (IF=1)
;    push word [si]         ; IP
;    push word [si+2]       ; CS
;    iret

select_next_task:
    ; 現在のタスクが task1 か？
    cmp word [current_task], task1_context
    jne .check2
    mov al, '1'
    call putc
    mov ax, task2_context
    mov [current_task], ax
    ret

.check2:
    mov ax, [current_task]
    call print_hex_word

    mov ax, task2_context
    call print_hex_word

    cmp word [current_task], task2_context
    jne .default
    mov al, '2'
    call putc
    mov ax, task3_context
    mov [current_task], ax
    ret

.default:
    ; task3 または不明 → task1 に戻す
    mov al, '3'
    call putc
    mov ax, task1_context
    mov [current_task], ax
    ret
 
; ------------------------------
; タスク初期化
; ------------------------------
init_tasks:
    ; task1 (出力: A)
    mov word [task1_context+0x1A], 0x7C00 - 6  ; SP
    mov word [task1_context+0x18], 0x2000      ; SS
    mov word [task1_context+0x02], 0x1000      ; CS
    mov word [task1_context+0x00], task1.loop1 - $$       ; IP（task1 のループ先頭）
    mov word [task1_context+0x04], 0x0200      ; FLAGS (IF=1)
    mov word [task1_context+0x14], 0x3000      ; DS（タスク1専用）

    ; task2 (出力: B)
    mov word [task2_context+0x1A], 0x7C00 - 6  ; SP
    mov word [task2_context+0x18], 0x2100      ; SS
    mov word [task2_context+0x02], 0x1000      ; CS
    mov word [task2_context+0x00], task2.loop2 - $$       ; IP（task2 のループ先頭）
    mov word [task2_context+0x04], 0x0200      ; FLAGS (IF=1)
    mov word [task2_context+0x14], 0x3100      ; DS（タスク2専用）

    ; task3 (出力: C)
    mov word [task3_context+0x1A], 0x7C00 - 6  ; SP
    mov word [task3_context+0x18], 0x2200      ; SS
    mov word [task3_context+0x02], 0x1000      ; CS
    mov word [task3_context+0x00], task3.loop3 - $$       ; IP（task3 のループ先頭）
    mov word [task3_context+0x04], 0x0200      ; FLAGS (IF=1)
    mov word [task3_context+0x14], 0x3200      ; DS（タスク3専用）
    

    mov word [current_task], task1_context
    ret

; -------------------------------
; 初期化サブルーチン
; -------------------------------
init_jump:
    mov word [task_switch_jump], irq0_handler
    mov word [task_switch_jump + 2], cs
    ret


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

; ------------------------------
; データ領域
; ------------------------------
task_switch_jump: dw 0
next_task:  dw 0

; 各タスクのTSSもどき構造
section .bss
align 2
current_task: resw 1
task1_context: resb 0x1e
task2_context: resb 0x1e
task3_context: resb 0x1e


temp_jmp:
    temp_jmp_off:   dw 0x0000     ; offset
    temp_jmp_seg:   dw 0x0000     ; segment

section .text

; -------------------------------
; セクション終端
; -------------------------------
times 1022 - ($ - $$) db 0
dw 0xAA55
