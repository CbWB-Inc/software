; boot.asm
;
mov ax, 0x07c0
mov ds, ax

mov ah, 0x0
mov al, 0x3
int 0x10

mov ax, 0
mov bx, 0

._loop

add bx, 1
add ax, bx

cmp bx, 100
jl ._loop

mov cx, ax

loop:

mov dx, 0
mov ax, cx
mov bx, 10
div bx
mov cx, ax
mov ah, 0x0e
mov al, dl
add al, 0x30
int 0x10

cmp cx, 0
jne loop

; end of proccess
;
hang:
jmp hang

times 510-($-$$) db 0

db 0x55
db 0xAA
