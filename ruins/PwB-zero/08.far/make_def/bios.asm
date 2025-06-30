;>===========================
;>	BIOSで遊ぼっ！
;>===========================

section .data

	_c_seg          equ 0x07c0
	_c_ex_area_addr equ 0x200

section .text

boot:
    ;org 0x7c00
    cli
    
    ; set segment register
    mov ax, _c_seg
    ;xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
;    mov sp, 0x7c00

    mov ah, 0x0e
    ;
    ; disk read
    ;     read to es:bx
    ;
    ;mov ax, _c_seg
    ;mov es, ax
    mov bx, _c_ex_area_addr

    mov ah, 0x02 ; Read Sectors From Drive
    mov dl, 0x80 ; Drive
    mov al, 0x20 ; Sectors To Read Count ;
    mov ch, 0x00 ; Cylinder
    mov cl, 0x02 ; Sector(starts from 1, not 0) ; set 2. becouse not need MBR
    mov dh, 0x00 ; Head

    int 0x13     ; Execute disk read

    jmp _c_seg:0x200

;>****************************
;> hlt
;>****************************
_hlt:
    hlt
    jmp _hlt

;>****************************
;> ブートローダパディング
;>****************************

times 510-($-$$) db 0

;********************************
; ブートセクタシグネチャ
;********************************

db 0x55
db 0xAA
