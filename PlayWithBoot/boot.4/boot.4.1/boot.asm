; boot.asm
;
mov ax, 0x07c0
mov ds, ax

mov ah, 0x0
mov al, 0x3
int 0x10


mov ah, 0x0E

mov al, 1
mov bl, 3
add al, bl

add al, 0x30

int 0x10

; end of proccess
;
hang:
jmp hang

times 510-($-$$) db 0

db 0x55
db 0xAA
