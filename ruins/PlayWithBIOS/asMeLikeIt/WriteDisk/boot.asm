; boot.asm
;
mov ax, 0x07c0
mov ds, ax

mov ah, 0x0
mov al, 0x3
int 0x10


; practice 1 (print other)

mov ax, p1_title
call print_str

mov al, 1

mov ah, 0x0e
add al, 0x30
int 0x10

mov ax, crlf
call print_str
call print_str

; practice 2 (add 2 num)

mov ax, p2_title
call print_str

mov ax, p2_msg
call print_str

mov bh, 1
mov bl, 3
add bl, bh

mov ah, 0x0e
mov al, bl
add al, 0x30
int 0x10

mov ax, crlf
call print_str
call print_str

; practice 3 (add 1 to 100 and print it)

mov ax, p3_title
call print_str

mov bx, 0
mov ax, 0

add_loop:

add ax, bx
add bx, 1

cmp bx, 100
jle add_loop

mov bx, ax

print_loop:

mov dx, 0
mov ax, bx
mov bx, 10
div bx
mov bx, ax
mov ah, 0x0e
mov al, dl
add al, 0x30
int 0x10

cmp bx, 0

jne print_loop

mov ax, crlf
call print_str
call print_str


; practice 4 (print valu in address)

mov ax, p4_title
call print_str

mov ax, 0x0000
mov bx, _test
mov byte al, [bx]
mov bx, ax

p4_loop:

mov dx, 0
mov ax, bx
mov bx, 10
div bx
;mov cx, dx
mov bx, ax
mov ah, 0x0e
mov al, dl
add al, 0x30
int 0x10

cmp bx, 0

jne p4_loop

mov ax, crlf
call print_str
call print_str

; practice 5 (read disk)

mov ax, p5_title
call print_str

mov ax, 0x07c0
mov es, ax
mov bx, 512

mov ah, 0x02 ; Read Sectors From Drive
mov dl, 0x80 ; Drive
mov al, 0x01 ; Sectors To Read Count ;
mov ch, 0x00 ; Cylinder
mov cl, 0x02 ; Sector(starts from 1, not 0) ; set 2. becouse not need MBR
mov dh, 0x00 ; Head

int 0x13     ; Execute disk read

mov ax, 512
call print_str

mov ax, crlf
call print_str
call print_str

; practice 6 (key read)

mov ax, p6_title
call print_str

mov ax, p6_msg
call print_str

mov ah, 0x00
int 0x16

mov bx, ax
mov bh, 0

p6_loop:

mov dx, 0
mov ax, bx
mov bx, 10
div bx
mov bx, ax
mov ah, 0x0e
mov al, dl
add al, 0x30
int 0x10

cmp bx, 0

jne p6_loop

jmp hang


; end of proccess
;
hang:
jmp hang

p1_title:
	db 'practice 1 (print other)', 0x0a, 0x0d, 0x0a, 0x0d, 0x00

p2_title:
	db 'practice 2 (add 2 num)', 0x0a, 0x0d, 0x0a, 0x0d, 0x00

p2_msg:
	db '1 + 3 : ', 0x00

p3_title:
	db 'practice 3 (add 1 to 100 and print it)', 0x0a, 0x0d, 0x0a, 0x0d, 0x00

p4_title:
	db 'practice 4 (print valu in address)', 0x0a, 0x0d, 0x0a, 0x0d, 0x00

p5_title:
	db 'practice 5 (read disk)', 0x0a, 0x0d, 0x0a, 0x0d, 0x00

p6_title:
	db 'practice 6 (key read)', 0x0a, 0x0d, 0x0a, 0x0d, 0x00

p6_msg:
	db 'ascii code : ', 0x00

crlf:
	db '', 0x0a, 0x0d, 0x00

_test:
	db 0x15, 0x00

print_str:

        push ax
        push si

        mov si, ax
        mov ah, 0x0E

loop:
        lodsb

        or al, al
        jz loop_end

        int 0x10

        jmp loop

loop_end:

        pop si
        pop ax

        ret


times 510-($-$$) db 0

db 0x55
db 0xAA

top_of_2nd_sector:
	db 'Hello Sector No.1', 0x0d, 0x0a, 0x00

times 1024-($-$$) db 0
