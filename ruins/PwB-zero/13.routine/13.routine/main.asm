
jmp setup


setup:
    mov ax, cs
    mov ds, ax
    mov es, ax

    ; ビデオモードの設定
    mov ah, 0x0
    mov al, 0x3    ; 16色テキスト、80x25
    int 0x10

start:
%include "routine.asm"

times 2048-($-$$) -2 db 0
dw 0x5E5E
