; boot.asm
;
mov ax, 0x07c0
mov ds, ax

mov ah, 0x0
mov al, 0x3
int 0x10


mov ah, 0x00
int 0x16

mov cx, ax
mov ch, 0x00
mov bx, 10

loop:

mov dx, 0
mov ax, cx
div bx
mov cx, ax
mov ah, 0x0e
mov al, dl
add al, 0x30
int 0x10

cmp cx, 0
jne loop


jmp hang


; end of proccess
;
hang:
jmp hang

times 510-($-$$) db 0

db 0x55
db 0xAA
