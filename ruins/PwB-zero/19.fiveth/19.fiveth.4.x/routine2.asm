;********************************
; cls
;       テキストをクリアする
; param : 
; return: 
;********************************
cls:
    push ax
    push cx
    push es
    push ds
    push di
    
    mov ax, 0xb800      ; VGAテキストビデオメモリ
    mov es, ax
    xor di, di          ; 書き込み位置（画面先頭）

    mov cx, 80*25       ; 画面全体（80列 × 25行）
    mov ah, 0x07        ; 属性：黒背景・明るい灰色文字
    mov al, ' '         ; 空白文字

._loop:
    stosw             ; AX → ES:DI（1文字分：文字＋属性）
    loop ._loop

    mov ah, 0x00
    mov al, 0x00
    call set_cursor_pos
    
    pop di
    pop ds
    pop es
    pop cx
    pop ax
    
    ret


;********************************
; putcd
;       1文字表示
; param : ah:x座標
;         al:y座標
;         bh:属性
;         bl:文字
; return: 
;********************************
putcd:
    push ax
    push bx
    push cx
    push dx
    push es
    push ds
    
    mov cx, 0xb800
    mov es, cx
;    mov ds, cx
    
    mov cx, bx
    mov [.y], al
    mov al, ah
    mov ah, 0x00
    
    mov dx, 0x0000
    mov bx, 0x0005
    shl ax, 5
    mul bx
    
    mov bl, [.y]
    mov bh, 0x00
    shl bx, 1

    add ax, bx
    
    mov bx, ax
    mov word [es:bx], cx

    pop ds
    pop es
    pop dx
    pop cx
    pop bx
    pop ax
    
    ret

.y: db 0


;********************************
; disp_strd
;       文字表示
; param : ah:x座標
;         al:y座標
;         bx:文字列のアドレス
; return: 
;********************************
disp_strd:
    push ax
    push bx
    push cx
    push dx
    push si
    push ds
    push es

    call set_own_seg

    mov cx, 0xb800
    mov es, cx
     
    mov si, bx
    mov cx, ax

    mov [.x], ah
    mov [.y], al

.loop:
    lodsb
    cmp al, 0x00
    je .exit
    
    mov bh, 0x07
    mov bl, al
    mov cx, bx

    mov al, [.x]
    mov ah, 0x00
    
    mov dx, 0x0000
    mov bx, 0x0005
    shl ax, 5
    mul bx
    
    mov bl, [.y]
    mov bh, 0x00
    shl bx, 1

    add ax, bx
    
    mov bx, ax
    mov word [es:bx], cx

    mov cx, [.y]
    inc cx
    mov [.y], cx
    
    jmp .loop

.exit:
    
    pop es
    pop ds
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

.y: db 0
.x: db 0



; -------------------------------
; 画面に１６進表示
; -------------------------------
disp_word_hexd:
    push ax
    push bx
    push cx
    push dx

    mov dx, bx
    mov bh, 0x07
    
    mov cx, dx
    shr cx, 12
    and cx, 0x0f
    cmp cl, 10
    jl .digit
    add cl, 'A' - 10
    jmp .print
.digit:
    add cl, '0'
.print:
    mov bl, cl
    call putcd
    
    mov cx, dx
    shr cx, 8
    and cx, 0x0f
    cmp cl, 10
    jl .digit2
    add cl, 'A' - 10
    jmp .print2
.digit2:
    add cl, '0'
.print2:
    mov bl, cl
    inc al
    call putcd
    
    mov cx, dx
    shr cx, 4
    and cx, 0x0f
    cmp cl, 10
    jl .digit3
    add cl, 'A' - 10
    jmp .print3
.digit3:
    add cl, '0'
.print3:
    mov bl, cl
    inc al
    call putcd

    mov cx, dx
    ;shr cx, 0
    and cx, 0x0f
    cmp cl, 10
    jl .digit4
    add cl, 'A' - 10
    jmp .print4
.digit4:
    add cl, '0'
.print4:
    mov bl, cl
    inc al
    call putcd

    pop dx
    pop cx
    pop bx
    pop ax
    
    ret


;key_buf_seg  		equ 0x9a00
;key_buf_head_ofs 	equ 0x0000
;key_buf_tail_ofs 	equ 0x0002
;key_buf_data_ofs 	equ 0x0004
;key_buf_len  		equ 256


set_ctx_heartbeat:
    push bx
    push cx
    push es
    push ds
    
    mov bx, ctx_common_seg
    mov es, bx
    mov ds, bx
    mov cx, ax
    call get_tick
    dec cx
    shl cx, 1
    mov bx, 0x0000
    add bx, cx
    mov [es:bx], ax
    
    pop ds
    pop es
    pop cx
    pop bx
    
    ret

get_ctx_heartbeat:
    push bx
    push cx
    push es
    push ds
    
    mov bx, ctx_common_seg
    mov es, bx
    mov ds, bx
    mov cx, ax
    call get_tick
    dec cx
    shl cx, 1
    mov bx, 0x0000
    add bx, cx
    mov ax, [es:bx]
    
    pop ds
    pop es
    pop cx
    pop bx
    
    ret

dead_or_alive:
    cmp ax, bx
    je .dead
    mov cl, 'L'
    jmp .exit
    
.dead:
    mov cl, 'D'
.exit:

    ret
    

ctx_common_seg  equ 0x7000

ctx_k_task_heartbeat    equ 0x0000
ctx_d_task_heartbeat    equ 0x0002
ctx_p_task1_heartbeat   equ 0x0004
ctx_p_task2_heartbeat   equ 0x0006
ctx_p_task3_heartbeat   equ 0x0008

ctx_k_task_id   equ 0x0001
ctx_d_task_id   equ 0x0002
ctx_p_task1_id  equ 0x0003
ctx_p_task2_id  equ 0x0004
ctx_p_task3_id  equ 0x0005

