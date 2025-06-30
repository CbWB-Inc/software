org 0x7c00
bits 16

start:
    mov ah, 0x0e
    mov al, 'B'
    int 0x10

    cli
    mov ax, 0x07c0
    mov ds, ax
    mov es, ax
    mov ss, ax

    mov bx, 0x200

    mov ah, 0x02
    mov dl, 0x80
    mov al, 0x20
    mov ch, 0x00
    mov cl, 0x02
    mov dh, 0x00

    int 0x13
    sti

    mov ah, 0x0e
    mov al, 'C'
    int 0x10

    jmp 0x07c0:0x200

times 510-($-$$) db 0
dw 0xaa55
