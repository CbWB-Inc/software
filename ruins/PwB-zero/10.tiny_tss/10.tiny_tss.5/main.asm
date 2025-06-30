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
current_task       dw 0

task1_context:
task1_ip:           dw 0
task1_cs:           dw 0
task1_ss:           dw 0
task1_sp:           dw 0
task1_ds:           dw 0

task2_context:
task2_ip:           dw 0
task2_cs:           dw 0
task2_ss:           dw 0
task2_sp:           dw 0
task2_ds:           dw 0

task3_context:
task3_ip:           dw 0
task3_cs:           dw 0
task3_ss:           dw 0
task3_sp:           dw 0
task3_ds:           dw 0

task_switch_jump:
    dw 0
    dw 0

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

    
    mov ax, 0x100
    mov word [task1_cs], ax
    mov word [task2_cs], ax
    mov word [task3_cs], ax

    call init_jump

    
    ; タスク1と2の初期化
    ;mov word [task1_ip], 0x0002   ;task1
    mov word [task1_ip], 0x0002
    mov word [task1_cs], 0x1000
    mov word [task1_ss], 0x2000
    mov word [task1_sp], 0x7c00
    mov word [task1_ds], 0x3000

    ;mov word [task2_ip], 0x100b   ;task2
    mov word [task2_ip], 0x0014
    mov word [task2_cs], 0x1000
    mov word [task2_ss], 0x2100
    mov word [task2_sp], 0x7c00
    mov word [task2_ds], 0x3100

    ;mov word [task3_ip], 0x1014   ;task3
    mov word [task3_ip], 0x0025
    mov word [task3_cs], 0x1000
    mov word [task3_ss], 0x2200
    mov word [task3_sp], 0x7c00
    mov word [task3_ds], 0x3200

    mov ax, ds
    mov [main_ds] , ax

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


    ; 割り込み有効化後、初回だけ after_func を呼ぶ
    
    mov si, [current_task]
    jmp after_func
    
    
main_loop:
    hlt
    jmp main_loop

; -------------------------------
; IRQ0 ハンドラ → タスク切り替え
; -------------------------------
irq0_handler:
    pusha
    push ds

    mov ax, [main_ds]
    mov es, ax
    
    ; EOI
    mov al, 0x20
    out 0x20, al


    ; context 保存
    mov si, [current_task]

    ; タスク切り替え
    cmp si, task1_context
    je .switch_to_task2
    cmp si, task2_context
    je .switch_to_task3
    cmp si, task3_context
    je .switch_to_task1
    jmp .done_switch ; 念のため
.switch_to_task1:
    mov si, task1_context
    jmp .done_switch
.switch_to_task2:
    mov si, task2_context
    jmp .done_switch
.switch_to_task3:
    mov si,task3_context
.done_switch:
    mov [current_task], si


    jmp after_func

after_func:
    cli
    mov ax, [main_ds]
    mov es, ax

    ; タスクの CS, IP を一時変数に保存
    mov ax, [si+0]        ; IP
    mov bx, [si+2]        ; CS
    ;mov [next_ip], ax
    ;mov [next_cs], bx
    
    mov [temp_jmp + 0], ax
    mov [temp_jmp + 2], bx

     ; スタック切り替え
    push bx
    mov dx, [si+4]          ; sp
    mov bx, [si+2]
    mov ss, bx
    mov sp, dx
    pop bx

    ; push IP, CS, FLAGS をタスク側スタックに積む
    ;nop
    ;pushf
    ;push word [temp_jmp + 0]  ; IP
    ;push word [temp_jmp + 2]  ; CS


    sti
    
    ; 実行
    ;jmp far [temp_jmp]    

    push word 0x0200         ; FLAGS (IF=1)
    push word [temp_jmp+2]   ; CS
    push word [temp_jmp]     ; IP
    
    iret     
    
 
temp_jmp:
    temp_jmp_off:   dw 0x0000     ; offset
    temp_jmp_seg:   dw 0x0000     ; segment

next_task:
    next_ip: dw 0
    next_cs: dw 0

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

; -------------------------------
; ブートセクタ終端
; -------------------------------
times 510 - ($ - $$) db 0
dw 0xAA55
