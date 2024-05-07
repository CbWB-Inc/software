; boot.asm

mov ax, 0x07c0
mov ds, ax
mov es, ax

mov ah, 0x0
mov al, 0x3
int 0x10


mov bx, 0x200   ; Destination address to read

mov ah, 0x02    ; Read Sectors From Drive
mov dl, 0x80    ; Drive
mov al, 0x01    ; Sectors To Read Count ;
mov ch, 0x00    ; Cylinder
mov cl, 0x02    ; Sector(starts from 1, not 0) ; set 2. becouse not need MBR
mov dh, 0x00    ; Head

int 0x13        ; Execute disk read

mov si, 0x0200
mov ah, 0x0E

loop:

lodsb

or al, al
jz loop_end

int 0x10

jmp loop

loop_end:


jmp hang


; end of proccess
;
hang:
jmp hang


times 510-($-$$) db 0

db 0x55
db 0xAA

test:
	db 'Hello 1st sector!', 0x0a, 0x0d, 0x00

_padding:
        times 0x0400-($-$$) db 0
