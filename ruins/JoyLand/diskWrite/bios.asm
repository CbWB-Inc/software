; bios.asm

mov ax, 0x07c0
mov ds, ax
mov es, ax

mov ah, 0x0
mov al, 0x3
int 0x10

; set data to top of 2nd sector
mov si, _change_msg2
mov bx, 0x0200
loop2:
lodsb
or al, al
je loop2_end
mov [bx], al
add bx, 1
jmp loop2

loop2_end:

; set data to top of 3rd sector
mov si, _change_msg3
mov bx, 0x0400
loop3:
lodsb
or al, al
je loop3_end
mov [bx], al
add bx, 1
jmp loop3
loop3_end:

; set data to top of 4th sector
mov si, _change_msg4
mov bx, 0x0600
loop4:
lodsb
or al, al
je loop4_end
mov [bx], al
add bx, 1
jmp loop4
loop4_end:

; write disk

mov bx, 0x200   ; Destination address to write

mov ah, 0x03    ; Write Sectors To Drive
mov dl, 0x80    ; Drive
mov al, 0x03    ; Sectors To Write Count ;
mov ch, 0x00    ; Cylinder
mov cl, 0x02    ; Sector(starts from 1, not 0) ; set 2. becouse not need MBR
mov dh, 0x00    ; Head

int 0x13        ; Execute disk write

jmp hang

; end of proccess
;
hang:
jmp hang

_change_msg2: db 'All out!', 0x0d, 0x0a, 0x00
_change_msg3: db 'Pull the throttie!', 0x0d, 0x0a, 0x00
_change_msg4: db "All right Let's Go!", 0x0d, 0x0a, 0x00

times 510-($-$$) db 0

db 0x55
db 0xAA

_second_sector:
    db 'Forth Gate Open!', 0x0d, 0x0a, 0x00

    times 0x0400 -($-$$) db 0

_third_sector:
    db 'Quickly!', 0x0d, 0x0a, 0x00

    times 0x0600-($-$$) db 0

_fourth_sector:
    db 'Forth Gate Ooen!', 0x0d, 0x0a, 0x00

    times 0x0800 -($-$$) db 0

