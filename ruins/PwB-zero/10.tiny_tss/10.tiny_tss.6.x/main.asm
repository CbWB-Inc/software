org 0x0000
bits 16

jmp start

; -------------------------------
; タスク1（A出力）
; -------------------------------
task1:
.loop1:
    push ds
    cli
    mov ax, [si+8]
    mov ds, ax
    
    mov ah, 0x0e
    mov al, 'A'
    int 0x10
    pop ds
    sti
    hlt
    jmp .loop1

; -------------------------------
; タスク2（B出力）
; -------------------------------
task2:
.loop2:
    cli
    push ds
    mov ax, [si+8]
    mov ds, ax
    
    mov al, 'B'
    call putc
    pop ds
    sti
    hlt
    jmp .loop2

; -------------------------------
; タスク3（C出力）
; -------------------------------
task3:
.loop3:
    cli
    push ds
    mov ax, [si+8]
    mov ds, ax
    
    mov al, 'C'
    call putc
    pop ds
    sti
    hlt
    jmp .loop3

; -------------------------------
; 疑似TSS構造体
; -------------------------------
;current_task       dw 0

;task1_context:
;task1_ip:           dw 0
;task1_cs:           dw 0
;task1_ss:           dw 0
;task1_sp:           dw 0
;task1_ds:           dw 0

;task2_context:
;task2_ip:           dw 0
;task2_cs:           dw 0
;task2_ss:           dw 0
;task2_sp:           dw 0
;task2_ds:           dw 0

;task3_context:
;task3_ip:           dw 0
;task3_cs:           dw 0
;task3_ss:           dw 0
;task3_sp:           dw 0
;task3_ds:           dw 0

;task_switch_jump:
;    dw 0
;    dw 0

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
    
    
    ;mov ax, 0x100
    ;mov word [task1_cs], ax
    ;mov word [task2_cs], ax
    ;mov word [task3_cs], ax

    ;call init_jump

    
    ;; タスク1と2の初期化
    ;;mov word [task1_ip], 0x0002   ;task1
    ;mov word [task1_ip], 0x0002
    ;mov word [task1_cs], 0x1000
    ;mov word [task1_ss], 0x2000
    ;mov word [task1_sp], 0x7c00
    ;mov word [task1_ds], 0x3000

    ;;mov word [task2_ip], 0x100b   ;task2
    ;mov word [task2_ip], 0x0014
    ;mov word [task2_cs], 0x1000
    ;mov word [task2_ss], 0x2100
    ;mov word [task2_sp], 0x7c00
    ;mov word [task2_ds], 0x3100

    ;;mov word [task3_ip], 0x1014   ;task3
    ;mov word [task3_ip], 0x0025
    ;mov word [task3_cs], 0x1000
    ;mov word [task3_ss], 0x2200
    ;mov word [task3_sp], 0x7c00
    ;mov word [task3_ds], 0x3200

    mov ax, ds
    mov [main_ds] , ax

    mov ax, [task1_context]
    mov word [current_task], ax


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
;    jmp irq0_handler
    
    
main_loop:
    hlt
    jmp main_loop

; -------------------------------
; IRQ0 ハンドラ → タスク切り替え
; -------------------------------
irq0_handler:
    cli
    pusha
    push ds
    push es

    ;mov ax, [main_ds]
    ;mov es, ax
    ;mov ds, ax
        
    ; context 保存
    mov si, [current_task]
    
    ; EOI
    mov al, 0x20
    out 0x20, al

    ; 保存
;    push ax
;    mov ax, [current_ip]
;    pop ax
;    mov [si+0x00], ax
    mov [si+0x06], ax
    mov [si+0x08], bx
    mov [si+0x0A], cx
    mov [si+0x0C], dx
    mov [si+0x0E], si
    mov [si+0x10], di
    mov [si+0x12], bp

    mov ax, ds
    mov [si+0x14], ax
    mov ax, es
    mov [si+0x16], ax

    mov ax, ss
    mov [si+0x18], ax
    mov ax, sp
    add ax, 14
    mov [si+0x1A], ax

    ; デバッグ出力
    mov ax, [si]
    call print_hex_word

    ;mov ax, [task1_context]
    ;call print_hex_word

    ;mov ax, [task2_context]
    ;call print_hex_word

    ;mov ax, [task3_context]
    ;call print_hex_word


    ; 切替
    call select_next_task
    mov ax, [next_task]
    mov [current_task], ax
    mov si, ax
    ;mov [next_task], si
    
    call print_hex_word
    
    ; 復元
    ;mov ax, [si+0x00]
    ;mov [current_task], ax
    mov ax, [si+0x14]
    mov ds, ax
    mov ax, [si+0x16]
    mov es, ax

    mov ax, [si+0x06]
    mov bx, [si+0x08]
    mov cx, [si+0x0A]
    mov dx, [si+0x0C]
    mov di, [si+0x10]
    mov bp, [si+0x12]

    mov ax, [si+0x18]
    mov ss, ax
    mov sp, [si+0x1A]

    ; デバッグ出力
    ;push ds
    ;mov ax, [main_ds]
    ;mov ds, ax
    ;mov ax, [ds:next_task]
    ;call print_hex_word
    ;pop ds
    
;    push word [si+0x04]  ; FLAGS
;    push word [si+0x02]  ; CS
;    push word [si+0x00]  ; IP

;    sti
;    iret



    jmp after_func

after_func:
    cli
;    mov ax, [main_ds]
;    mov es, ax
    
    ;mov si, [next_task]

    ; タスクの CS, IP を一時変数に保存
    mov ax, [si+0]        ; IP
    mov bx, [si+2]        ; CS
    
    mov [temp_jmp + 0], ax
    mov [temp_jmp + 2], bx


    ; SP/SS 切替
    mov ax, [si+0x18]
    mov ss, ax
    mov sp, [si+0x1A]

    ; DS も切り替え（タスク独立データセグメント）
    mov ax, [si+0x14]           ; DS
    mov ds, ax


;     ; スタック切り替え
;    push bx
;    mov dx, [si+4]          ; sp
;    mov bx, [si+2]
;    mov ss, bx
;    mov sp, dx
;    pop bx

    ; push IP, CS, FLAGS をタスク側スタックに積む
    ;push word 0x0200
    ;push word [temp_jmp + 0]  ; IP
    ;push word [temp_jmp + 2]  ; CS


    sti
    
    ; 実行
    ;jmp far [temp_jmp]    

    mov al, '!'
    call putc

    ;mov ax, [temp_jmp]
    ;call print_hex_word


    push word 0x0200         ; FLAGS (IF=1)
    push word [temp_jmp+2]   ; CS
    push word [temp_jmp]     ; IP
    
    iret     
    
 
; ------------------------------
; タスク切替 (ラウンドロビン)
; ------------------------------
select_next_task:
    mov si, [current_task]
    cmp si, [task1_context]
    je .to2
    cmp si, [task2_context]
    je .to3
    cmp si, [task3_context]
    je .to1
.to1:
    mov al, 'q'
    call putc
    
    mov ax, [task1_context]
    call print_hex_word
    mov [next_task], ax
    ret
.to2:
    mov al, 'w'
    call putc

    mov ax, [task2_context]
    call print_hex_word
    mov [next_task], ax
    ret
.to3:
    mov al, 'e'
    call putc

    mov ax, [task3_context]
    call print_hex_word
    mov [next_task], ax
    ret




; ------------------------------
; タスク初期化
; ------------------------------
init_tasks:
    ; task1 (出力: A)
    mov word [task1_context+0x1A], 0x7C00 - 6  ; SP
    mov word [task1_context+0x18], 0x2000      ; SS
    mov word [task1_context+0x02], 0x1000      ; CS
    mov word [task1_context+0x00], 0x0002      ; IP（task1 のループ先頭）
    mov word [task1_context+0x04], 0x0200      ; FLAGS (IF=1)
    mov word [task1_context+0x14], 0x3000      ; DS（タスク1専用）

    ; task2 (出力: B)
    mov word [task2_context+0x1A], 0x7C00 - 6  ; SP
    mov word [task2_context+0x18], 0x2100      ; SS
    mov word [task2_context+0x02], 0x1000      ; CS
    mov word [task2_context+0x00], 0x0014      ; IP（task2 のループ先頭）
    mov word [task2_context+0x04], 0x0200      ; FLAGS (IF=1)
    mov word [task2_context+0x14], 0x3100      ; DS（タスク2専用）

    ; task3 (出力: C)
    mov word [task3_context+0x1A], 0x7C00 - 6  ; SP
    mov word [task3_context+0x18], 0x2200      ; SS
    mov word [task3_context+0x02], 0x1000      ; CS
    mov word [task3_context+0x00], 0x0025      ; IP（task3 のループ先頭）
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
current_task: dw 0
task_switch_jump: dw 0
next_task:  dw 0

; 各タスクのTSSもどき構造
section .bss
align 2
task1_context: resb 0x1e
task2_context: resb 0x1e
task3_context: resb 0x1e

temp_jmp:
    temp_jmp_off:   dw 0x0000     ; offset
    temp_jmp_seg:   dw 0x0000     ; segment

section .text

; -------------------------------
; ブートセクタ終端
; -------------------------------
times 1022 - ($ - $$) db 0
dw 0xAA55
