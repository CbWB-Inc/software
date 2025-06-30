org 0x7c00
bits 16

start:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    
    mov ax, 0x8000
    mov ss, ax
    mov sp, 0x7000

    ; Load main (1 sector -> 0x8000:0000)
    ;mov si, 0x8000
    mov ax, 0x8000
    mov es, ax
    mov bx, 0x0000

    mov ah, 0x02          ; int 13h: read sector(s)
    mov al, 9             ; 読むセクタ数 = 1
    mov ch, 0             ; cylinder = 0
    mov cl, 2             ; sector = 2（LBA=1）
    mov dh, 0             ; head = 0
    mov dl, 0x80          ; HDD
    int 0x13

    jc .fail

    ; ビデオモードの設定
    mov ah, 0x0
    mov al, 0x3    ; 16色テキスト、80x25
    int 0x10
    
    jmp 0x8000:0x0000

.fail:
    mov si, _msg_fail
.print:
    lodsb
    or al, al
    jz $
    mov ah, 0x0e
    int 0x10
    jmp .print

_msg_fail:
    db "LOAD ERR", 0



times 512 - ($ - $$) - 2 db 0
dw 0xaa55
