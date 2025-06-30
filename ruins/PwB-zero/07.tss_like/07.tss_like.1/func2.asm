org 0x0000
bits 16

func2_start:
    sti
.loop:
    mov ax, 0xb800
    mov es, ax
    mov word [es:162], 0x1f42     ; 'B'
    hlt
    jmp .loop

times 0x200-($-$$)-2 db 0
db 0x55
db 0xAA
