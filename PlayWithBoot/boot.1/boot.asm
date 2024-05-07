; boot.asm
hang:
jmp hang

times 510-($-$$) db 0

; This is a comment

db 0x55
db 0xAA
