org 0x0000
bits 16

jmp start

;>********************************
;> タスク共通開始点（IP = 0）
;>********************************
task_start:
    mov ah, 0x0e
    mov al, '?'       ; トレース文字
    int 0x10

    ;ret
    
.task_loop:
    hlt
    jmp .task_loop

;--------------------------------
; 重みづけ管理用
;--------------------------------
tick_counter: db 0

child_entry:
    dw 0x0000
    dw 0x2800

chain_entry:
    dw 0x0000
    dw 0x2400

;--------------------------------
; タスクコンテキスト構造（完全版）
;--------------------------------
;times 256 nop

child_context:
    resw 10   ; AX, CX, DX, BX, SP, BP, SI, DI, DS, ES
    resw 4    ; IP, CS, SP, SS

chain_context:
    resw 10
    resw 4

current_task: dw child_context
next_task:    dw chain_context


;>********************************
;> start
;>********************************

start:

    cli
    ;xor ax, ax
    mov ax, cs
    mov ds, ax
    mov es, ax
    

    ; 初期化：child_context にエントリ情報
    ;mov word [child_context + 20], child_start   ; IP
    mov word [child_context + 20], task_start   ; IP
    ;mov word [child_context + 20], 0x0000       ; IP
    mov word [child_context + 22], 0x2800       ; CS
    mov word [child_context + 24], 0x7C00       ; SP
    mov word [child_context + 26], 0x2800       ; SS

    ;mov word [chain_context + 20], chain_start
    mov word [chain_context + 20], task_start
    ;mov word [chain_context + 20], 0x0000
    mov word [chain_context + 22], 0x2400
    mov word [chain_context + 24], 0x7c00
    mov word [chain_context + 26], 0x2400

    ; 割り込みベクタの設定
    push es
    xor ax, ax
    mov es, ax
    mov ax, cs
;    mov word [es:0x20], irq0_handler
;    mov [es:0x22], ax
    mov word [es:0x80], irq0_handler
    mov [es:0x82], ax
    pop es
    
    
    ; PIT setup
    mov al, 0x36
    out 0x43, al
    ;mov ax, 11932     ; ~100Hz
    mov ax, 0xFFFF     ; 最遅
    out 0x40, al
    mov al, ah
    out 0x40, al

    ; PIC 初期化（マスタ・スレーブ）
    mov al, 0x11
    out 0x20, al
;    mov al, 0x08
    mov al, 0x20
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


    ; 無効化
    ;in  al, 0x21
    ;or  al, 0x01
    ;out 0x21, al

    ; 有効化
    in  al, 0x21
    and al, 0xFE
    out 0x21, al

read_disk:

    ; child を 0x2000:0000 に読み込む
    mov ax, 0x2800
    mov es, ax
    xor bx, bx
    mov ah, 0x02       ; int 13h: read
    mov al, 4          ; 読み込みセクタ数
    mov ch, 0          ; cylinder
    mov cl, 6          ; sector = 4 (1-based)
    mov dh, 0          ; head
    mov dl, 0x80       ; HDD
    int 0x13
    jc .load_error     ; キャリーが立ったら失敗


    ; chain を 0x3000:0000 に読み込む
    mov ax, 0x2400
    mov es, ax
    xor bx, bx
    mov ah, 0x02       ; int 13h: read
    mov al, 4          ; 読み込みセクタ数
    mov ch, 0          ; cylinder
    mov cl, 10          ; sector = 5
    mov dh, 0          ; head
    int 0x13
    jc .load_error

    jmp .load_normal

.load_error:
    mov ah, 0x0e
    mov al, 'E'
    int 0x10

    mov si, .msg_fail
.print:
    lodsb
    or al, al
    jz $
    mov ah, 0x0e
    int 0x10
    jmp .print

.msg_fail:
    db "LOAD ERR", 0


.load_normal:



main:
    cli
;mov ax, 0x9000
;mov ds, ax
call far [child_entry]
    sti


.loop:
    hlt
    jmp .loop

;>********************************
;> IRQ0 handler
;>********************************
; IRQ0 handler
irq0_handler:

    cli
    push ds
    push es
    pusha

    mov al, 0x20
    out 0x20, al

    ; 保存：current_task の位置を取得
    mov ax, cs
    ;xor ax, ax
    mov ds, ax
    mov si, [current_task]

    ; 保存順：AX〜DI, DS, ES（pusha + segment）
    mov [si], ax      ; AX
    mov [si+2], cx
    mov [si+4], dx
    mov [si+6], bx
    mov bx, sp
    lea ax, [bx+12]   ; SP（pusha+ds+es+ret用）
    mov [si+8], ax
    mov [si+10], bp
    mov [si+12], si
    mov [si+14], di
    mov ax, ds
    mov [si+16], ax
    mov ax, es
    mov [si+18], ax

    ; IP, CS はスタックから
    mov bx, sp
    mov ax, [ss:bx+16]
    mov [si+20], ax
    mov bx, sp
    mov ax, [ss:bx+18]
    mov [si+22], ax

    ; SS, SP
    mov ax, ss
    mov [si+26], ax
    mov bx, sp
    lea ax, [bx+20]
    mov [si+24], ax


    ;-----------------------------
    ; 重み付きスケジューリング
    ; 子2回、チェーン1回
    ;-----------------------------
    inc word [tick_counter]
    mov ax, [tick_counter]
    xor dx, dx
    mov bx, 3
    div bx         ; AX = tick_counter / 3, DX = tick_counter % 3
    cmp dx, 2
    jne .use_child

.use_chain:
    mov word [current_task], chain_context
    mov word [next_task], child_context
    jmp .schedule_done

.use_child:
    mov word [current_task], child_context
    mov word [next_task], chain_context

.schedule_done:

    ; 復元先 = 新しい current_task
    mov si, [current_task]

    mov ax, [si+26]
    mov ss, ax
    mov sp, [si+24]

    push word [si+22] ; CS
    push word [si+20] ; IP
    push word [si+18] ; ES
    push word [si+16] ; DS
    push word [si+14] ; DI
    push word [si+12] ; SI
    push word [si+10] ; BP
    push word [si+8]  ; old SP (無効)
    push word [si+6]  ; BX
    push word [si+4]  ; DX
    push word [si+2]  ; CX
    push word [si]    ; AX

    inc byte [tick_counter]
    cmp byte [tick_counter], 3
    jne .call_chain

    mov byte [tick_counter], 0
    cli
    ; デバッグ出力
    ;mov al, '#'
    ;call putc
    call far [child_entry]
    jmp .done

.call_chain:
    
    cli
    ; デバッグ出力
    ;mov al, '%'
    ;call putc
    call far [chain_entry]

.done:
    ;mov al, 0x20
    ;out 0x20, al

    ; デバッグ出力
    mov al, '!'
    call putc
    
    sti
popa
    pop es
    pop ds
    sti
    iret

; -------------------------------
; routine
; -------------------------------

%include "routine.asm"

; -------------------------------
; セクション終端
; -------------------------------
times 2048 - ($ - $$) -2 db 0
dw 0xEDFE


