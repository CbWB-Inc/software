;org 0x0000
bits 16

section .text

;********************************
; 開始
;********************************


global _start

_start:


;********************************
; 各種設定、初期化など
;********************************
setup:
    mov ax, cs
    mov ds, ax
    mov es, ax
    xor ax, ax
    
    mov ax, parent_seg
    mov ss, ax
    mov sp, 0xfffe

    cli
    call init_env
    call load_k_task

    call init_pit
    call init_pic

    call init_ctx_k_task

    call install_irq0_handler

    
    
    mov ax, cs
    mov ds, ax
    
    
    cli
    push ds
    mov ax, 0x07c0
    mov ds, ax
    mov es, ax
    mov ax, 0x0000
    mov bx, 10
    call disp_mem
    pop ax
    
    push 0x0200             ; flags
    push k_task_seg         ; segment
    push 0x0000             ; offset
    jmp k_task_seg:0x0000  ; 
    

.hang:
    hlt
    jmp .hang

._s_msg db 'executed!' , 0x00
._s_msg2 db '##### end #####' , 0x00


init_env:
;    call set_own_seg
    
    mov ax, 0x0000
    mov [call_counter], ax
    
    mov ax, tick_addr
    mov [tick_ptr], ax
    
    ret



;********************************
; タスク初期化
;********************************
init_ctx_k_task:
    mov si, ctx_k_task
    mov ax, 0x0000
    mov [si + context_ip], ax
    mov ax, k_task_seg
    mov [si + context_cs], ax
    mov ax, 0x0200     ; 適当な flags（IF=1にしてもよい）
    mov [si + context_flags], ax    
    mov ax, 0x0001     ; 
    mov [si + context_id], ax    
    
    ; ctx_child1 初期化
    mov ax, ss
    mov [si + context_ss], ax
    mov ax, ctx_k_task_sp
    mov [si + context_sp], ax

    mov ax, ds
    mov [si + context_ds], ax
    mov ax, es
    mov [si + context_es], ax
    mov ax, 0
    mov [si + context_fs], ax
    mov [si + context_gs], ax

    ret

;********************************
; タスクロード
;********************************
load_k_task:
    mov ax, k_task_seg
    mov es, ax
    mov bx, 0x0000
    mov ch, 0x00
    mov cl, k_task_sector
    call read_sectors
    ret

read_sectors:
    push dx
    push ax
    mov dl, 0x80
    mov ah, 0x02
    mov al, 9            ; 固定で9セクタ読み込み
    int 0x13
    pop ax
    pop dx
    ret

;********************************
; 割り込み関連設定
;********************************
init_pit:
    mov al, 0x36          ; mode 3, square wave
    out 0x43, al
    mov al, 0x9B          ; low byte (approx. 100Hz)
    ;mov al, 0xff
    out 0x40, al
    mov al, 0x2E          ; high byte
    ;mov al, 0xff
    out 0x40, al
    ret

init_pic:
    ; マスタ PIC 初期化
    mov al, 0x11       ; ICW1: エッジトリガ・ICW4有効
    out 0x20, al
    mov al, 0x20       ; ICW2: 割り込みベクタ 0x20 (IRQ0〜)
    out 0x21, al
    mov al, 0x04       ; ICW3: スレーブはIRQ2に接続
    out 0x21, al
    mov al, 0x01       ; ICW4: 8086モード
    out 0x21, al

    ; スレーブ PIC 初期化
    mov al, 0x11
    out 0xA0, al
    mov al, 0x28       ; ICW2: IRQ8〜が0x28〜になる
    out 0xA1, al
    mov al, 0x02       ; ICW3: スレーブIDは2番（IRQ2）
    out 0xA1, al
    mov al, 0x01       ; ICW4: 8086モード
    out 0xA1, al

; IRQ0 と IRQ1 を許可（1111 1100 = 0xFC）
    mov al, 0xFC
    out 0x21, al
    mov al, 0xFF       ; 全部マスク（スレーブは全部禁止）
    out 0xA1, al
    
    ; 無効化
    ;in  al, 0x21
    ;or  al, 0x01
    ;out 0x21, al

    ; 有効化
    ;in  al, 0x21
    ;and al, 0xFE
    ;out 0x21, al

    ret

;********************************
; irq0  関連設定
;********************************
install_irq0_handler:
    ; IRQ0 (INT 0x20) → offset 0x0000:0800 に配置されると仮定
    mov ax, 0x0000
    mov ds, ax
    mov word [irq0_vector * 4], irq0_handler     ; offset
    mov word [irq0_vector * 4 + 2], parent_seg   ; segment
    ret

; irq0  ハンドラ本体
irq0_handler:
    cli
    mov ax, cs
    mov ds, ax

    call get_cursor_pos
    mov bx, ax
    
    mov ah, 19
    mov al, 30
    call set_cursor_pos
    
    mov ax, ._s_msg
    call disp_str
    
    ; カウンタ情報の更新
    inc word [current_counter]
    call get_tick
    inc ax
    cmp ax, 65500
    jb .skip_clear
    mov ax, 0
.skip_clear:
    call set_tick

    call disp_hex
    
    mov ax, bx
    call set_cursor_pos

    mov al, 0x20
    out 0x20, al  ; EOI送信

    iret

._s_msg db 'h0:', 0x00

;********************************
; 共通ルーチン
;********************************

section .data

;********************************
; 領域設定
;********************************
section .data

parent_seg     equ 0x8000
k_task_seg     equ 0x9000

ctx_k_task_sp equ 0x7000

k_task_sector  equ 10       ; 子1はセクタ10から読み込む

irq0_vector    equ 0x20

;; === 先頭に追加 === ;;
context_ip     equ 0
context_cs     equ 2
context_flags  equ 4
context_ax     equ 6
context_bx     equ 8
context_cx     equ 10
context_dx     equ 12
context_si     equ 14
context_di     equ 16
context_bp     equ 18
context_ds     equ 20
context_es     equ 22
context_fs     equ 24
context_gs     equ 26
context_ss     equ 28
context_sp     equ 30
context_id     equ 32
context_size   equ 34


current_counter dw 0

call_counter dw 0x0000

ctx_k_task equ 0x9000

already_ex dw 0x0000


%include "routine.inc"

