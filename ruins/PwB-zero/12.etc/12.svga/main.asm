
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
    
    ; VESA機能チェック
    mov ax, 0x4F00      ; VBE機能チェック
    mov di, vesainfo    ; 結果格納先
    int 0x10
    cmp ax, 0x004F      ; 成功か確認
    jne failed
    
    mov cx, ax
    
    ; モード変更：800x600 256色
    mov ax, 0x4F02
    mov bx, 0x103
    int 0x10

    ; カラーパレットの変更（文字色を白にしたい）
    call set_palette_white_0F


    mov ax, cx              ; 004f
    call disp_word_hex
    call disp_nl
    
    mov ax, _s_svga_msg     ; 800*600 mode
    call disp_str
    call disp_nl

    mov si, vesainfo        ; 564553410003
    mov byte [si + 4] , 0x00
    mov ax, si
    call disp_str
    call disp_nl


    mov si, vesainfo        ; 564553410003
    mov ax, si
    mov bx, ds
    mov cx, 6
    call disp_mem
    call disp_nl

    call set_palette_white_0F
    mov si, vesainfo        ; 564553410003
    mov ax, si
    mov bx, 0x000f
    mov cx, ds
    call disp_str2
    call disp_nl
    
    call set_palette_white_0F
    mov ax, [info3_off]
    mov bx, 0x000f
    mov cx, [info3_seg]     ; わからない
    call disp_str2
    call disp_nl

    mov ax, [info3_off]     ; わからない
    mov bx, [info3_seg]
    mov cx, 20
    call disp_mem
    call disp_nl

    call set_palette_white_0F
    mov ax, [info3_off]     ; わからない
    mov bl, 0x0f
    mov cx, [info3_seg]
    call disp_str2
    call disp_nl

    
    

hang:
    hlt
    jmp hang

failed:
    ; 動作確認として失敗時に画面を赤に塗るなどもあり
    mov ah, 0x0E
    mov al, 'X'
    int 0x10
    jmp hang


disp_str2:
    push ds
    mov si, ax
    mov ds, cx
    mov ah, 0x0e
._loop:
    lodsb
    cmp al, 0x00
    je ._exit
    int 0x10
    jmp ._loop
    
._exit:
    pop ds
    ret


; -------------------------------------------
; 色番号 0x0F を白 (RGB = 63,63,63) に変更
; -------------------------------------------
set_palette_white_0F:
    ; パレットバッファに白 (63,63,63)
    mov byte [palette_buf], 63
    mov byte [palette_buf+1], 63
    mov byte [palette_buf+2], 63

    ; VBEパレット設定
    mov ax, 0x4F09
    mov bx, 0x000F        ; 色番号15を1色だけ設定
    mov cx, 1             ; 色数=1
    mov ax, cs
    mov es, ax
    mov dx, palette_buf
    int 0x10
    ret

palette_buf:
    db 63, 63, 63       ; R, G, B = 真っ白


vesainfo:
    info1 db 4 dup(0)   ; 'VESA' シグネチャがここに入る
    info2 dw 0          ; VBE Version
    info3_off   dw 0    ; OEM String ptr
    info3_seg   dw 0
    times 256 db 0   ; 最小でもこれくらい確保しておく

_s_svga_msg db '800*600 mode', 0x00


%include "routine.asm"

times 2048-($-$$) -2 db 0
dw 0x5E5E
