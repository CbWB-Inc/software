org 0x0000  ; 読み込む先はどこでも良いので org 0

start:
    push ax
    push bx
    push si
    push ds
    push es
    
    ;mov ah, 0x0e
    ;mov al, 'H'
    ;int 0x10
    
    ; ビデオページ先頭に 'A' を表示（白地黒文字）
    mov ax, cursor_pos_seg
    mov ds, ax
    mov bx, cursor_pos_off
    
    mov ax, [bx]
    mov si, [bx]
    add word [bx], 2

    
    cmp word [bx], 4000
    jb .skip_reset
    mov word [bx], 0
.skip_reset:

    ; VRAM に書き込む
    mov ax, 0xb800
    mov es, ax
    mov byte [es:si], 'A'
    mov byte [es:si+1], 0x1f

    pop es
    pop ds
    pop si
    pop bx
    pop ax
    retf   ; ← 割り込みハンドラから呼ばれるため必ず retf で戻る


cursor_pos_seg equ 0x07c0
cursor_pos_off equ 0x2295

bseg equ 0x07c0

%include "def.asm"

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
