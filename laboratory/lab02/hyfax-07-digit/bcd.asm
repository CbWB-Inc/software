; app.asm - S1 sample app (blocking key wait)
; build: nasm -f bin app.asm -o APP.BIN

BITS 16
; org 0x0000

%include 'hyfax.asm'

%define MON_SEG  0x0050        ; monitor側のセグメント（monitor.asmと合わせる）

%macro PUTC 1
    push ax
    mov al, %1
    out 0xE9, al
    pop ax
%endmacro

; extern exit_return
; extern phd1
; extern phd2
; extern phd4

start:
    PUTC 'B'
    PUTC ':'

    ; --- COMライク初期化（CS=DS=ES=SS=自分、SP設定） ---
    push cs
    pop  ds
    push cs
    pop  es
    push cs
    pop  ss
    mov  sp, 0xfffe

    ; --- メッセージ表示 ---
    mov si, msg_hello
    mov ah, 0x20              ; write(DS:SI, CX)
    int 0x80

    mov ah, svc_newline
    int 0x80

    PUTC 0x0d
    PUTC 0x0a

    ;
    ; i64_negateの動作確認
    ;
    ; mov di, i64hs_a
    ; call clear_i64hs
    ; mov ax, 5            ; i64hs_bの設定
    ; mov si, i64hs_a
    ; mov word [si + I64HS.LowLow], ax
    ; call i64_negate

    ; mov si, i64hs_a           ; 結果のダンプ
    ; mov cx, 10
    ; call dump_mem
    ; PUTC 0x0d
    ; PUTC 0x0a





    ;
    ; 四則演算の動作確認
    ;
    ; mov di, i64hs_a
    ; call clear_i64hs
    ; mov di, i64hs_t
    ; call clear_i64hs
    ; mov ax, 24           ; i64hs_aの設定
    ; mov si, i64hs_a
    ; mov word [si + I64HS.LowLow], ax
    ; call i64_negate
    ; mov di, phs_a           ; i64hs_aからphs_aを生成（被乗数）
    ; call phs_from_i64

    ; mov di, i64hs_a
    ; call clear_i64hs
    ; mov di, i64hs_t
    ; call clear_i64hs
    ; mov ax, 11            ; i64hs_bの設定
    ; mov si, i64hs_a
    ; mov word [si + I64HS.LowLow], ax
    ; ; call i64_negate
    ; mov di, phs_b           ; i64hs_aからphs_aを生成（被乗数）
    ; call phs_from_i64

    ; PUTC 0x0d
    ; PUTC 0x0a

    ; mov si, phs_a
    ; mov bp, phs_b
    ; mov di, phs_q
    ; mov bx, phs_r

    ;
    ; add、sub、mul、divに修正してそれぞれ確認
    ;
    ; call phs_div

    ; PUTC 0x0d
    ; PUTC 0x0a

    ; mov si, phs_a           ; 結果のダンプ
    ; mov cx, 23
    ; call dump_mem
    ; PUTC 0x0d
    ; PUTC 0x0a

    ; mov si, phs_b           ; 結果のダンプ
    ; mov cx, 23
    ; call dump_mem
    ; PUTC 0x0d
    ; PUTC 0x0a

    ; mov si, phs_q           ; 結果のダンプ
    ; mov cx, 23
    ; call dump_mem
    ; PUTC 0x0d
    ; PUTC 0x0a

    ; mov si, phs_r           ; 結果のダンプ
    ; mov cx, 23
    ; call dump_mem
    ; PUTC 0x0d
    ; PUTC 0x0a

    ; mov si, dhs_a           ; 結果のダンプ
    ; mov cx, 43
    ; call dump_mem
    ; PUTC 0x0d
    ; PUTC 0x0a

    ; mov si, dhs_b           ; 結果のダンプ
    ; mov cx, 43
    ; call dump_mem
    ; PUTC 0x0d
    ; PUTC 0x0a

    ; mov si, dhs_q           ; 結果のダンプ
    ; mov cx, 43
    ; call dump_mem
    ; PUTC 0x0d
    ; PUTC 0x0a

    ; mov si, dhs_r           ; 結果のダンプ
    ; mov cx, 43
    ; call dump_mem
    ; PUTC 0x0d
    ; PUTC 0x0a



    ; mov si, phs_a
    ; mov ah, svc_putphs
    ; int 0x80
    ; mov ah, svc_newline
    ; int 0x80


    push ds
    pop es
   
    ;
    ; phs_eval_u64の動作確認
    ;
    mov di, i64hs_a
    call clear_i64hs
    mov di, dhs_r
    call clear_i64hs
    mov ax, 0           ; i64hs_aの設定
    mov bx, 0
    mov cx, 0
    mov dx, 1
    mov si, i64hs_a
    mov word [si + I64HS.LowLow], ax
    mov word [si + I64HS.LowHigh], bx
    mov word [si + I64HS.HighLow], cx
    mov word [si + I64HS.HighHigh], dx
    ; call i64_negate
    mov di, phs_a           ; i64hs_aからphs_aを生成（被乗数）
    call phs_from_i64

    push ds
    pop es

    mov si, phs_a
    mov di, dhs_r
    call phs_eval_u64

; push ds
; push es
; pop ds          ; DS = ES にする
; mov si, di      ; SI = 出力先オフセット（dhs_r）
; mov cx, 8
; call dump_mem
; pop ds          ; DSを戻す
;     PUTC 0x0d
;     PUTC 0x0a

    ; call phd4
    ; PUTC 0x0d
    ; PUTC 0x0a

    ; pushf
    ; pop ax    
    ; call phd4
    ; PUTC 0x0d
    ; PUTC 0x0a
    
    mov si, phs_a           ; 結果のダンプ
    mov cx, 23
    call dump_mem
    PUTC 0x0d
    PUTC 0x0a

    mov si, i64hs_a           ; 結果のダンプ
    mov cx, 8
    call dump_mem
    PUTC 0x0d
    PUTC 0x0a

    mov si, dhs_r           ; 結果のダンプ
    mov cx, 8
    call dump_mem
    PUTC 0x0d
    PUTC 0x0a

    ; call phs_eval_u64_debug


    mov si, msg_wait
    mov ah, svc_write
    int 0x80

    mov ah, svc_getkey
    int 0x80


exit:
    ; call exit_return

    ; --- モニタへ戻る ---
    ; 既定：MON_SEG:0000 に戻る（monitor側の戻り口が0x0000想定）
    ; push word MON_SEG
    ; mov ax, 0
    push word TTS_SEG
    push word 0x0000
    retf
    

    ; 別戻り先にしたい場合（monitor側に monitor_restart がある等）：
    ; mon_ret_ptr: dw monitor_restart, MON_SEG
    ; jmp  far [mon_ret_ptr]


; phs_eval_u64_debug:
;     push di

;     ; clear output first
;     call i64hs_zero_esdi

;     ; len == 0 => 0 (success)
;     mov bx, [si + PHS_LEN]
;     test bx, bx
;     jz .ok

;     ; sign check (unsigned only)
;     mov al, [si + PHS_SIGN]
;     test al, al
;     jz .start

;     ; If PHS is not normalized, allow -0 only:
;     ; here len!=0, so treat as negative
;     pop di
;     call i64hs_zero_esdi
;     mov ax, ERR_PHS_NEG
;     stc
;     ret

; .start:
;     PUTC 'S'
;     PUTC ':'
;     push ax
;     mov al, bl
;     call phd2  ; BX (len) を出力
;     pop ax
;     PUTC 0x0d
;     PUTC 0x0a
    
;     ; iterate digits from MSB to LSB: i = len-1 .. 0
;     dec bx                  ; BX = i
    
;     ; CX = フラグ: 最初の桁かどうか (1=最初, 0=それ以降)
;     mov cx, 1

; .loop:
;     PUTC 'i'
;     PUTC '='
;     push ax
;     mov al, bl
;     call phd2  ; i を出力
;     pop ax
;     PUTC ' '
    
;     ; extract digit i into AL
;     mov dx, bx
;     shr dx, 1               ; byte index
;     push bx
;     mov bx, dx
;     mov al, [si + PHS_VAL + bx]
;     pop bx
;     test bl, 1
;     jz .low_nib
;     shr al, 4
;     jmp .digit_ok
; .low_nib:
;     and al, 0x0F
; .digit_ok:
;     ; defensive: digit must be 0..9
;     cmp al, 9
;     jbe .do_step

;     PUTC 'E'  ; Error
;     pop di
;     call i64hs_zero_esdi
;     mov ax, ERR_PHS_INV
;     stc
;     ret

; .do_step:
;     PUTC 'd'
;     PUTC '='
;     push ax
;     mov al, [esp]  ; digit
;     call phd2
;     pop ax
;     PUTC ' '
    
;     push ax                 ; digitを保存

;     ; 最初の桁でなければ *10
;     cmp cx, 0
;     je .mul10               ; CX==0 なら *10 実行
    
;     PUTC '['
;     PUTC 'F'  ; First digit
;     PUTC ']'
;     PUTC ' '
    
;     mov cx, 0               ; CX=0 にして次回から *10
;     jmp .add_digit          ; 最初の桁は *10 スキップ

; .mul10:
;     PUTC '['
;     PUTC '*'
;     PUTC ']'
;     PUTC ' '
    
;     call i64hs_mul10_checked_esdi
;     jc .overflow_popdigit

; .add_digit:
;     PUTC '['
;     PUTC '+'
;     PUTC ']'
;     PUTC ' '
    
;     pop ax                  ; digitを復帰
;     call i64hs_add_digit_checked_esdi
;     jc .overflow

;     ; acc を出力
;     PUTC 'a'
;     PUTC 'c'
;     PUTC 'c'
;     PUTC '='
;     push ax
;     mov ax, [es:di + I64_L0]
;     call phd4
;     pop ax
;     PUTC 0x0d
;     PUTC 0x0a

;     dec bx
;     jns .loop

; .ok:
;     PUTC 'O'
;     PUTC 'K'
;     PUTC 0x0d
;     PUTC 0x0a
;     pop di
;     clc
;     ret

; .overflow_popdigit:
;     PUTC 'O'  ; Overflow
;     PUTC 'V'
;     PUTC 'F'
;     PUTC '1'
;     PUTC 0x0d
;     PUTC 0x0a
;     pop ax          ; digit退避分を捨てる
;     jmp .overflow

; .overflow:
;     PUTC 'O'  ; Overflow
;     PUTC 'V'
;     PUTC 'F'
;     PUTC '2'
;     PUTC 0x0d
;     PUTC 0x0a
;     pop di
;     call i64hs_zero_esdi
;     mov ax, ERR_PHS_OVF
;     stc
;     ret





phs_a:
    times 20 db 0
    dw 0
    db 0

phs_b:
    times 20 db 0
    dw 0
    db 0

phs_q:
    times 20 db 0
    dw 0
    db 0

phs_r:
    times 20 db 0
    dw 0
    db 0

i64hs_a:
    times 4 dw 0

i64hs_b:
    times 4 dw 0

i64hs_t:
    times 4 dw 0

%include 'common.asm'
%include 'bcdlib.asm'

; ---- data ----
msg_hello:    db 'Hello from BCD', 13, 10, 0

msg_wait:     db 'Press any key to return shell...', 13, 10, 0

msg_nl:       db 13, 10, 0

keybuf:       times 2 db 0

; times 3072-($-$$) db 0