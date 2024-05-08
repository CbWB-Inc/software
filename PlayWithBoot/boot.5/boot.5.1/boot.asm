; boot.asm

mov ax, 0x07c0
mov ds, ax

mov ah, 0x0
mov al, 0x3
int 0x10

mov ax, 0x0000
mov bx, _test
mov byte al, [bx]
mov bx, ax

loop:

mov dx, 0
mov ax, bx
mov bx, 10
div bx
mov cx, dx
mov bx, ax
mov ah, 0x0e
mov al, dl
add al, 0x30
int 0x10

cmp bx, 0
jne loop


jmp hang

; end of proccess
;
hang:
jmp hang

_test: db 0x15, 0x00

times 510-($-$$) db 0

db 0x55
db 0xAA
