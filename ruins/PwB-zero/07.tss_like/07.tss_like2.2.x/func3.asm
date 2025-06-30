org 0x0000  ; 読み込む先はどこでも良いので org 0

start:
    cli

    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp
    push ds
    push es
    pushf

    mov ax, cs
    mov ds, ax     ; DSをCSに合わせる
    mov es, ax

    call proc
    
    popf
    pop es
    pop ds
    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax

;    sti

    ;hlt
    
    ;retf   ; ← 割り込みハンドラから呼ばれるため必ず retf で戻る
    ;iret

    ;jmp main2

    mov ax, 0x07c0
    mov ds, ax
    mov ss, [ds:0x2323]  ; main_ss
    mov sp, [ds:0x2325]  ; main_sp

    ;push 0x07c0
    ;push 0x2aa2
    retf
    



    ;jmp 0x07c0:0x2aa2
    ;jmp 0x07c0:0x2800
    ;after_func

proc:

    cli
    mov ax, _msg
    call disp_str2
    sti

    ret



baddr dw 0

cursor_pos_seg equ 0x07c0
cursor_pos_off equ 0x2295

bseg equ 0x07c0

_msg: db 'Hi!', 0x00, 0x00, 0x00, 0x00, 0x00


%include "def.asm"

disp_str2:

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
