; task2.asm
org 0x0000
bits 16

.loop:
    cli
    push ds
    mov ax, ds
    mov ds, ax
    mov ah, 0x0e
    mov al, 'A'
    int 0x10
    pop ds
    sti
    hlt
    jmp .loop

times 510 - ($ - $$) db 0
dw 0xAA55
