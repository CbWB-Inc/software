;org 0x0000
bits 16

TSS_ip     equ 0
TSS_cs     equ 2
TSS_sp     equ 4
TSS_ss     equ 6
TSS_flags  equ 8
TSS_size   equ 10

task_switch:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp

    ; 表示：*AB
    mov ax, 0xb800
    mov es, ax
    mov word [es:0], 0x1f2a       ; '*'
    mov word [es:2], 0x1f41       ; 'A'
    mov word [es:4], 0x1f42       ; 'B'

    mov al, [current_tss_sel]
    cmp al, 0
    jne .showB
    mov word [es:6], 0x1f41       ; 'A'
    jmp .show_done
.showB:
    mov word [es:6], 0x1f42       ; 'B'
.show_done:

    ; スタック保存
    push ds
    mov ax, ss
    mov ds, ax
    mov si, sp
    mov bx, [current_tss]

    mov ax, [si+0]
    mov [bx + TSS_ip], ax
    mov ax, [si+2]
    mov [bx + TSS_cs], ax
    mov ax, ss
    mov [bx + TSS_ss], ax
    mov ax, sp
    mov [bx + TSS_sp], ax
    ; FLAGSは固定値にする（安定のため）
    mov ax, 0x0200
    mov [bx + TSS_flags], ax

    pop ds

    ; 切り替え
    mov al, [current_tss_sel]
    cmp al, 0
    jne .load1
    mov bx, tss2
    mov byte [current_tss_sel], 1
    jmp .after_switch
.load1:
    mov bx, tss1
    mov byte [current_tss_sel], 0
.after_switch:
    mov [current_tss], bx

    ; EOI
    mov al, 0x20
    out 0x20, al

    ; タスク復帰
    push word [bx + TSS_flags]
    push word [bx + TSS_cs]
    push word [bx + TSS_ip]
    iret

tss1: times TSS_size db 0
tss2: times TSS_size db 0

current_tss:     dw tss1
current_tss_sel: db 0

times 0x0800-($-$$)-2 db 0
db 0x55
db 0xAA
