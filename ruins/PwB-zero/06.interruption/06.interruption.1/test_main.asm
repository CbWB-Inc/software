org 0x0200
bits 16

main:
    mov ah, 0x0e
    mov al, 'D'
    int 0x10

    mov ah, 0x00
    mov al, 0x03
    int 0x10

    cld

    mov al, 0x36
    out 0x43, al
    mov al, 0x00
    out 0x40, al
    mov al, 0x10
    out 0x40, al

    push es
    xor ax, ax
    mov es, ax
    mov ax, irq0_handler
    mov [es:0x20], ax
    mov ax, cs
    mov [es:0x22], ax
    pop es

    sti

.loop:
    mov ah, 0x0e
    mov al, '.'
    int 0x10
    hlt
    jmp .loop

irq0_handler:
    push ax
    push bx
    push es
    mov ax, 0xb800
    mov es, ax
    mov bx, [cursor_pos]
    mov byte [es:bx], 'A'
    mov byte [es:bx+1], 0x1f
    add word [cursor_pos], 2
    cmp word [cursor_pos], 4000
    jb .skip_reset
    mov word [cursor_pos], 0
.skip_reset:
    mov al, 0x20
    out 0x20, al
    pop es
    pop bx
    pop ax
    iret

cursor_pos: dw 160
