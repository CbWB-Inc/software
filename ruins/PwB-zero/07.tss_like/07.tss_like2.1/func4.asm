org 0x0000  ; 読み込む先はどこでも良いので org 0

start:
    push ax
    push bx
    push si
    push ds
    push es

    mov ax, cs
    mov ds, ax     ; DSをCSに合わせる
    mov es, ax

    call proc
    
    pop es
    pop ds
    pop si
    pop bx
    pop ax

    retf   ; ← 割り込みハンドラから呼ばれるため必ず retf で戻る

proc:

    cli
    mov ax, .msg
    call disp_str
    sti

    ret



.msg: db 'Ho!', 0x00, 0xff, 0xff, 0xff, 0xff
baddr dw 0

cursor_pos_seg equ 0x07c0
cursor_pos_off equ 0x2295

bseg equ 0x07c0

;%include "def.asm"

disp_str:

    push ax
    push si

    mov si, ax
    mov ah, 0x0E

._loop:
    lodsb
    or al, al
    jz ._loop_end
    int 0x10
    jmp ._loop

._loop_end:
    pop si
    pop ax

    ret



;==============================================================
; ファイル長の調整
;==============================================================
_padding4:
    times 0x0800-($-$$)-2 db 0

;********************************
; セクションシグネチャ
;********************************

db 0x55
db 0xAA
