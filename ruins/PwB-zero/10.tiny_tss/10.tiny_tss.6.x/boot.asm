org 0x7C00
bits 16

start:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax

    ; 読み込み先 ES:BX = 0x1000:0000
    mov ax, 0x1000
    mov es, ax
    xor bx, bx

    mov ah, 0x02          ; int 13h: read sector(s)
    mov al, 2             ; 読むセクタ数 = 1
    mov ch, 0             ; cylinder = 0
    mov cl, 2             ; sector = 2（LBA=1）
    mov dh, 0             ; head = 0
    mov dl, 0x80          ; HDD
    int 0x13

    jc .fail

    jmp 0x1000:0x0000

.fail:
    mov si, msg_fail
.print:
    lodsb
    or al, al
    jz $
    mov ah, 0x0e
    int 0x10
    jmp .print

msg_fail:
    db "LOAD ERR", 0

times 510 - ($ - $$) db 0
dw 0xAA55