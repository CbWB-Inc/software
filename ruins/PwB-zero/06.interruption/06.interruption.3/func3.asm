org 0x0000  ; 読み込む先はどこでも良いので org 0

start:
    push ax
    push bx
    push es
    
    mov ah, 0x0e
    mov al, 'H'
    int 0x10
    
    ; ビデオページ先頭に 'A' を表示（白地黒文字）
    ;mov ax, cursor_pos_seg
    ;mov ds, ax
    ;mov bx, cursor_pos_off
    ;mov ax, 0xb800
    ;mov es, ax
    ;mov byte [es:bx], 'A'
    ;mov byte [es:bx+1], 0x1f
    ;add word [ds:bx], 2
    ;cmp word [ds:bx], 4000
    ;jb .skip_reset
    ;mov word [ds:bx], 0
.skip_reset:

    pop es
    pop bx
    pop ax
    retf   ; ← 割り込みハンドラから呼ばれるため必ず retf で戻る


; 表示位置（cursor_pos）を func3内に持たせるか、
; メイン側と共有するかは設計次第（ここでは独立に保持）
;extern cursor_pos
;cursor_pos: dw 160

;cursor_pos_seg equ 0x07c0
;cursor_pos_seg equ 0x4000
cursor_pos_seg equ 0x0000
cursor_pos_off equ 0x2295


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
