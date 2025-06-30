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
disp_strd2:
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


disp_strd:
    push ax
    push bx
    push cx
    push si

    mov si, bx
    mov cx, ax

    mov bh, 0x07
.loop:
    lodsb
    cmp al, 0x00
    je .exit
    mov bl, al
    mov ax, cx
    call putcd
    inc cl
    
    jmp .loop

.exit:
    
    pop si
    pop cx
    pop bx
    pop ax
    ret


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
    


;--------------------------------------
; 乱数関連
;--------------------------------------
;--------------------------------------
; set_seed
; - AX に与えた値を rng_state に設定
;--------------------------------------
set_seed:
    mov [rng_state], ax
    ret

;--------------------------------------
; xorshift16
; - 16bitの乱数を生成
; - 出力: AX に乱数値
; - 使用レジスタ: DX
;--------------------------------------
xorshift16:

    push dx

    mov ax, [rng_state] ; 現在の状態をAXに

    ; Xorshiftステップ: xor-shift-right 7
    mov dx, ax
    shr dx, 7
    xor ax, dx

    ; Xorshiftステップ: xor-shift-left 9
    mov dx, ax
    shl dx, 9
    xor ax, dx

    ; Xorshiftステップ: xor-shift-right 13
    mov dx, ax
    shr dx, 13
    xor ax, dx
    
    ;cmp ax, 0x0008
    ;jne .exit
    ;inc ax
    ;jmp .exit
    ;cmp ax, 0xffff
    ;jne .exit
    ;dec ax

.exit:
    ; 結果を保存
    mov [rng_state], ax

    pop dx
    ret

rng_state dw 0xACE1  ; 初期シード（非ゼロ）

_wait:
    cmp ax, 0x0000
    je .exit
.loop:
    sti
    ;hlt
    dec ax
    
    cmp ax, 0x0000
    je .exit
    jmp .loop
.exit:
    cli
    ret

;********************************
; メッセージ送信（キューに書き込む）
; 入力: AL=宛先ID, AH=送信元ID, BX=データ
; 出力: ZF=0:成功, ZF=1:満杯
;********************************
send_msg:
    push ds
    push es
    push si
    push di
    push cx
    push dx

    mov ax, msgq_seg
    mov ds, ax
    mov es, ax

    mov [.data], bx
    mov cx, [es:msgq_head_ofs]
    mov dx, [es:msgq_tail_ofs]

    ; 次のheadを仮計算
    mov si, cx
    inc si
    cmp si, msgq_len
    jb .no_wrap
    xor si, si
.no_wrap:

    ; tailとぶつかる＝満杯
    cmp si, dx
    je .full

    ; 書き込み位置
    imul bx, msgq_entry_size
    add bx, msgq_data_ofs
    mov cx, [.data]
    
    mov [es:bx], al         ; 宛先ID
    mov [es:bx+1], ah       ; 送信元ID
    mov [es:bx+2], cx       ; データ

    ; head更新
    mov [es:msgq_head_ofs], si
    clc
    pop dx
    pop cx
    pop di
    pop si
    pop es
    pop ds
    ret

.full:
    stc
    pop dx
    pop cx
    pop di
    pop si
    pop es
    pop ds
    ret

.data dw 0

;********************************
; 自分宛メッセージ受信
; 入力: AL = 自分のctx_id
; 出力: ZF=0 → AH=送信元ID, BX=データ
;********************************
recv_my_msg:
    push ds
    push es
    push si
    push di
    push cx
    push dx

    mov ax, msgq_seg
    mov ds, ax
    mov es, ax

    mov si, [es:msgq_tail_ofs]
    cmp si, [es:msgq_head_ofs]
    je .no_msg

    imul si, msgq_entry_size
    add si, msgq_data_ofs

    mov dl, [es:si]       ; 宛先
    cmp dl, al
    jne .no_msg

    mov ah, [es:si+1]     ; 送信元ID
    mov bx, [es:si+2]     ; データ

    ; クリア
    mov byte [es:si], 0
    mov byte [es:si+1], 0
    mov word [es:si+2], 0

    ; tail更新
    mov di, [es:msgq_tail_ofs]
    inc di
    cmp di, msgq_len
    jb .ok
    xor di, di
.ok:
    mov [es:msgq_tail_ofs], di

    clc
    pop dx
    pop cx
    pop di
    pop si
    pop es
    pop ds
    ret

.no_msg:
    stc
    mov ah, 17
    mov al, 10
    mov bx, ._s_no_msg
    call disp_strd
    
    pop dx
    pop cx
    pop di
    pop si
    pop es
    pop ds
    ret


._s_no_msg db '---- ----', 0x00

;********************************
; データ領域
;********************************
msgq_seg        equ 0x9c00
msgq_head_ofs   equ 0x0000
msgq_tail_ofs   equ 0x0002
msgq_data_ofs   equ 0x0004
msgq_entry_size equ 4
msgq_len        equ 16


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

