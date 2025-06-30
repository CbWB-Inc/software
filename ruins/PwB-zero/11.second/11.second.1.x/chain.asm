org 0x0000
bits 16
jmp chain_start

chain_start:
    mov ax, cs
    mov ds, ax
    
    ;cli
    
    ;call get_cursor_pos
    ;mov [._w_pos], ax

    ;mov ah, 40
    ;mov al, 16
    ;call set_cursor_pos

    mov ax, ._s_msg
    ;mov bx, ds
    call disp_str

    ;mov ax, [._w_pos]
    ;call set_cursor_pos

    
    ;mov ah, 0x0e
    ;mov al, 'C'
    ;int 0x10

    ;sti


    retf

.halt:
    jmp .halt

._s_msg: db 'A', 0x00

._w_pos dw 0


%include "routine.asm"

; -------------------------------
; セクション終端
; -------------------------------

times 2048 - ($ - $$) - 2 db 0
dw 0xEDFE
