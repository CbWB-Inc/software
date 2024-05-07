; boot.asm
;
mov ax, 0x07c0
mov ds, ax

mov ah, 0x0
mov al, 0x3
int 0x10

mov ax, 0
mov bx, 0

loop:

add bx, 1
add ax, bx

cmp bx, 100
jl loop

add al, 0x30

int 0x10

; end of proccess
;
hang:
jmp hang

times 510-($-$$) db 0

db 0x55
db 0xAA
