; task1.asm
org 0x0000
bits 16

.loop:
    cli
    push ds
    jmp $+3
    pop si
    mov ax, cs
    mov ds, ax
    mov es, ax
    ;push ds
    ;pop es
    
    
    mov ax, ._msg
    mov bx, ds
    call far [disp_str_ptr]
    pop ds
    
    
    
    
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

._msg: db 'Hi!', 0x00

%include "def.asm"

times 510 - ($ - $$) db 0
dw 0xAA55