; boot.asm
mov ax, 0x07c0
mov ds, ax

mov ah, 0x0
mov al, 0x3
int 0x10

mov si, msg
mov ah, 0x0E

print_character_loop:
lodsb

or al, al
jz print_2nd_character

int 0x10

jmp print_character_loop

print_2nd_character:
mov si, msg2
mov ah, 0x0E

print_character_loop2:
lodsb

or al, al
jz hang

int 0x10

jmp print_character_loop2

msg:
db 'Hello, World!', 13, 10, 0

msg2:
db 'Hello, x86!', 13, 10, 0

hang:
jmp hang

times 510-($-$$) db 0

db 0x55
db 0xAA
