; in_str
; ax = pointer to target string (haystack)
; bx = pointer to search string (needle)
; return:
;   cx = index if found
;   ZF = 0 if found, ZF = 1 if not found
in_str:
    push si
    push di
    push dx

    mov si, ax      ; si = haystack
    mov di, bx      ; di = needle
    xor cx, cx      ; index counter
    cld             ; 確実に前方比較

.next_pos:
    push si         ; 検索開始位置保存
    push di         ; needle開始位置保存

    mov dx, si      ; dx = 比較用先頭位置

.compare_loop:
    lodsb           ; al = [si++]（haystack）
    scasb           ; compare al with [di++]（needle）
    jne .mismatch
    cmp al, 0       ; needle が終端？
    je .found       ; needle 末尾到達 = 完全一致

    cmp byte [di], 0
    jne .compare_loop

.found:
    pop di
    pop si
    clc             ; ZFクリア＝成功
    jmp .done

.mismatch:
    pop di
    pop si
    inc cx
    mov si, dx
    cmp byte [si], 0
    je .not_found
    inc si
    jmp .next_pos

.not_found:
    stc             ; エラー状態（ZF=1にするため）
    or cx, 0        ; 何もしないがZFを立てるため
    jmp .done

.done:
    pop dx
    pop di
    pop si
    ret

;********************************
; sub_str
;       文字列の一部を返す
; param : ax:文字列
;         bx:スタート位置（ゼロオリ）
;         cx:エンド位置（ゼロオリ）
; return: dx:切り出した文字列
;********************************
sub_str:
    push ax
    push bx
    push cx
    push si
    push di

    cmp bx, cx
    jb ._skip
    mov cx, bx
._skip:

    mov si, ax
    mov di, dx
    add si, bx
    sub cx, bx

._loop:
    cmp byte [si], 0x00
    je ._exit_loop
    cmp cx, 0x00
    je ._exit_loop
    mov bx, [si]
    mov [di], bx
    inc si
    inc di
    dec cx
    jmp ._loop
._exit_loop:
    inc di
    mov byte [di], 0x00

    pop di
    pop si
    pop cx
    pop bx
    pop ax

    ret

;********************************
; right_str
;       右から指定文字数の文字列を返す
; param : ax:文字列
;         bx:文字数
; return: cx:
;********************************
right_str:
    push ax
    push bx
    push dx
    push si
    push di

    mov si, ax
    mov di, cx

    push ds
    pop es

    mov dx, bx
    call str_len
    cmp dx, bx
    jb ._skip
    mov dx, bx
._skip:
    sub bx, dx
    add si, bx
    mov bx, dx

._loop:
    cmp byte [si], 0x00
    je ._exit_loop
    cmp bx, 0x00
    jz ._exit_loop
    mov dl, [si]
    mov [di], dl
    inc si
    inc di
    dec bx
    jmp ._loop

._exit_loop:
    mov byte [di], 0x00

    pop di
    pop si
    pop dx
    pop bx
    pop ax

    ret


;********************************
; left_str
;       左から指定文字数の文字列を返す
; param : ax:文字列
;         bx:文字数
; return: cx:
;********************************
left_str:
    push ax
    push bx
    push dx
    push si
    push di

    mov si, ax
    mov di, cx

    push ds
    pop es

    mov dx, bx
    call str_len
    cmp dx, bx
    jb ._skip
    mov dx, bx
._skip:
    mov bx, dx

._loop:
    cmp byte [si], 0x00
    je ._exit_loop
    cmp bx, 0x00
    jz ._exit_loop
    mov dl, [si]
    mov [di], dl
    inc si
    inc di
    dec bx
    jmp ._loop

._exit_loop:
    mov byte [di], 0x00

    pop di
    pop si
    pop dx
    pop bx
    pop ax

    ret


;********************************
; str_len
;       文字列の長さを返す
; param : ax
; return: bx
;********************************
str_len:
    push ax
    push si

    mov si, ax
    mov bx, 0

._loop:
    cmp byte [si], 0x00
    je ._exit_loop
    inc si
    inc bx
    jmp ._loop

._exit_loop:

    pop si
    pop ax

    ret

; ltrim
; ax = pointer to null-terminated string
; return:
;   ax = pointer to first non-space character

ltrim:
    push si

    mov si, ax
.ltrim_loop:
    cmp byte [si], 0x20  ; space?
    jne .done
    inc si
    jmp .ltrim_loop

.done:
    mov ax, si           ; 新しい先頭を返す
    pop si
    ret


; rtrim
; ax = pointer to null-terminated string
; modifies string in-place:
;   最後の非スペースの次の位置に 0 を書き込む

rtrim:
    push si
    push di

    mov si, ax
.find_end:
    cmp byte [si], 0
    je .scan_back
    inc si
    jmp .find_end

.scan_back:
    dec si              ; null の手前から逆に走査
.scan_loop:
    cmp si, ax          ; 文字列先頭まで来たら終わり
    jb .all_spaces      ; すべて空白だった
    cmp byte [si], 0x20
    jne .found_end
    dec si
    jmp .scan_loop

.all_spaces:
    push si
    mov si, ax
    mov byte [si], 0    ; 全部スペースなら空文字に
    pop si
    jmp .done

.found_end:
    inc si              ; 非スペースの直後を終端に
    mov byte [si], 0
.done:
    pop di
    pop si
    ret

;********************************
; rtrim
;       文字列の右側の空白を外す
; param : ax
; return: ax
;********************************
 rtrim2:
    push bx
    push cx
    push dx
    push si
    push di

    call str_len
    mov dx, bx

    mov si, ax
    mov cx, 0
._loop1:
    cmp byte [si], 0x00
    je ._exit_loop1
    cmp byte [si], ' '
    je ._skip1
    mov [._w_last_pos], cx
._skip1:
    inc si
    inc cx
    jmp ._loop1
._exit_loop1:

    mov si, ax
    mov di, ._s_tmp_buf
    mov cx, [._w_last_pos]
._loop2:
    cmp cx, 0x00
    je ._exit_loop2
    mov al, [si]
    mov [di], al
    inc si
    inc di
    dec cx
    jmp ._loop2
._exit_loop2:
    mov cl, 0x00
    mov [di], cl

    mov si, ._s_tmp_buf
    mov di, ax
._loop3:
    cmp byte [si], 0x00
    je ._exit_loop3
    mov al, [si]
    mov [di], al
    inc si
    inc di
    jmp ._loop3
._exit_loop3:
    mov cl, 0x00
    mov [di], cl

    pop di
    pop si
    pop dx
    pop cx
    pop bx

    ret

 ._w_last_pos dw 0
 ._s_tmp_buf times 128 db 0

str_cpy:
    mov si, ax
    mov di, bx
._loop:
    cmp byte [si], 0x00
    je ._exit_loop
    mov al, [si]
    mov [di], al
    inc si
    inc di
    jmp ._loop
._exit_loop:
    
    
    ret


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

    mov cx, msgq_seg
    mov ds, cx
    mov es, cx

    mov [.data], bx
    mov cx, [es:msgq_head_ofs]
    mov bx, [es:msgq_tail_ofs]

    
    ; 書き込み位置を計算
    ;inc cx
    mov dx, cx
    add cx, msgq_entry_size
    cmp cx, msgq_len
    jb .no_rap
    mov dx, 0
.no_rap:
    ;mov dx, dx
    mov cx, dx
    add cx, msgq_entry_size
    cmp cx, bx
    jbe .ok
    cmp dx, bx
    jbe .full
.ok:
    mov si, [es:msgq_head_ofs]
    
    ; 書き込み位置
    mov cx, [.data]
    
    mov [es:si + msgq_data_ofs], al         ; 宛先ID
    mov [es:si + msgq_data_ofs + 1], ah     ; 送信元ID
    mov [es:si + msgq_data_ofs + 2], cx     ; データ

    ; head更新
    add si, msgq_entry_size
    cmp si, msgq_len
    jb .skip
    mov si, 0
.skip:
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
    
    mov cx, msgq_seg
    mov ds, cx
    mov es, cx

    mov bx, [es:msgq_head_ofs]
    mov cx, [es:msgq_tail_ofs]
    mov dx, cx

    ; データの読み込み位置の特定
    add cx, msgq_entry_size
    cmp cx, msgq_len
    jb .skip
    mov cx, 0
.skip:
    cmp cx, bx
    je .no_msg

    mov si, cx
    add si, msgq_data_ofs

    
    ;push ax
    ;push bx
    
    ;mov ah, 1
    ;mov al, 0
    ;mov bx, [es:si]
    ;call disp_word_hexd
    
    ;mov ah, 1
    ;mov al, 5
    ;mov bx, [es:si + 2]
    ;call disp_word_hexd
    
    ;pop bx
    ;pop ax
    
    
    mov dl, [es:si]       ; 宛先
    cmp dl, al
    jne .no_msg

    mov al, dl
    mov ah, [es:si+1]     ; 送信元ID
    mov bx, [es:si+2]     ; データ


    ; クリア
    mov byte [es:si], 0
    mov byte [es:si+1], 0
    mov word [es:si+2], 0

    ; tail更新
    mov [es:msgq_tail_ofs], cx

    clc
    pop dx
    pop cx
    pop di
    pop si
    pop es
    pop ds

    push ax
    push bx
    push cx
    push dx
    
    mov cx, ax
    mov dx, bx
    
    mov ah, 1
    mov al, 10
    mov bx, ax
    call disp_word_hexd
    
    mov ah, 1
    mov al, 15
    mov bx, dx
    call disp_word_hexd
    
    pop dx
    pop cx
    pop bx
    pop ax

    ret

.no_msg:
    stc
    
    mov ax, 0x0000
    mov bx, 0x0000
    
    pop dx
    pop cx
    pop di
    pop si
    pop es
    pop ds

    ret

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

