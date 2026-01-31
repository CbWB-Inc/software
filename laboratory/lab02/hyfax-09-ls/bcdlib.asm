; bcdlib.asm
; Decimal (BCD) core library
; PHS API / internal DHS

BITS 16
; org 0x0000

work_area resw 4            ; 作業用I64HS (8バイト)


; ----------------------------------------
; clear_i64hs
;   64ビット値を0クリアする
; 入力:
;   DS:SI = I64HS構造体
; 出力:
;   DS:SI = クリアした値
; 破壊:
;   AX
; ----------------------------------------
clear_i64hs:
    push ax
    push di

    xor ax, ax
    mov [di + I64HS.LowHigh], ax
    mov [di + I64HS.HighLow], ax
    mov [di + I64HS.HighHigh], ax

    pop di
    pop ax
    ret


; ----------------------------------------
; i64_negate
;   64ビット値の2の補数を取る (符号反転)
; 入力:
;   DS:DI = I64HS構造体
; 出力:
;   DS:DI = 反転後の値
; 破壊:
;   AX
; ----------------------------------------
i64_negate:
    push bx
    push cx
    
    ; ビット反転 (NOT)
    mov bx, si
    mov cx, 4
.not_loop:
    mov ax, [bx]
    not ax
    mov [bx], ax
    add bx, 2
    loop .not_loop
    
    ; +1 (加算)
    mov bx, si
    mov ax, [bx + I64HS.LowLow]
    add ax, 1
    mov [bx + I64HS.LowLow], ax
    
    mov ax, [bx + I64HS.LowHigh]
    adc ax, 0
    mov [bx + I64HS.LowHigh], ax
    
    mov ax, [bx + I64HS.HighLow]
    adc ax, 0
    mov [bx + I64HS.HighLow], ax
    
    mov ax, [bx + I64HS.HighHigh]
    adc ax, 0
    mov [bx + I64HS.HighHigh], ax
    
    pop cx
    pop bx
    ret

; ----------------------------------------
; i64_is_zero
;   64ビット値がゼロかチェック
; 入力:
;   DS:SI = I64HS構造体
; 出力:
;   ZF = 1 (ゼロの場合)
; ----------------------------------------
i64_is_zero:
    push ax
    push si
    
    mov ax, [si + I64HS.LowLow]
    or ax, [si + I64HS.LowHigh]
    or ax, [si + I64HS.HighLow]
    or ax, [si + I64HS.HighHigh]
    
    pop si
    pop ax
    ret

; ----------------------------------------
; i64_div_word
;   64ビット値を16ビット値で割る
; 入力:
;   DS:SI = I64HS構造体 (被除数、結果もここに格納)
;   CX = 除数 (16ビット)
; 出力:
;   DS:SI = 商
;   DX = 余り
; ----------------------------------------
i64_div_word:
    push ax
    push bx
    push si
    
    xor dx, dx              ; 余り初期化
    
    ; 最上位ワードから順に処理
    mov bx, si
    add bx, 6               ; HighHigh位置
    mov ax, [bx]
    div cx
    mov [bx], ax            ; 商を格納
    
    ; HighLow
    sub bx, 2
    mov ax, [bx]
    div cx
    mov [bx], ax
    
    ; LowHigh
    sub bx, 2
    mov ax, [bx]
    div cx
    mov [bx], ax
    
    ; LowLow
    sub bx, 2
    mov ax, [bx]
    div cx
    mov [bx], ax
    
    ; DXに最終余りが残る
    
    pop si
    pop bx
    pop ax
    ret

; ----------------------------------------
; i64_abs
;   符号判定して絶対値化
; 入力:
;   DS:SI = I64HS
; 出力:
;   ZF = 0
;   pac_sign = 0 or 1
;   DS:SI = 絶対値
; ----------------------------------------
i64_abs:
    mov ax, [si + I64HS.HighHigh]
    test ax, 0x8000
    jz .positive

    ; 負数
    mov byte [pac_sign], 1
    call i64_negate
    ret

.positive:
    mov byte [pac_sign], 0
    ret


; ES:DI = BCDバッファ
; CX = バイト数 (10)
bcd_add3:
    push ax
    push cx
    push di

.loop:
    mov al, [es:di]

    ; 下位ニブル
    mov ah, al
    and ah, 0x0F
    cmp ah, 5
    jb .hi
    add al, 0x03

.hi:
    ; 上位ニブル
    mov ah, al
    shr ah, 4
    cmp ah, 5
    jb .next
    add al, 0x30

.next:
    mov [es:di], al
    inc di
    loop .loop

    pop di
    pop cx
    pop ax
    ret

; ES:DI = BCD
; CX = バイト数
bcd_shl1:
    push ax
    push cx
    push di

    ; clc
.loop:
    mov al, [es:di]
    rcl al, 1
    mov [es:di], al
    inc di
    loop .loop

    pop di
    pop cx
    pop ax
    ret

; DS:SI = I64HS
i64_shl1:
    push ax

    shl word [si + I64HS.LowLow], 1
    rcl word [si + I64HS.LowHigh], 1
    rcl word [si + I64HS.HighLow], 1
    rcl word [si + I64HS.HighHigh], 1

    pop ax
    ret

pac_sign    db 0        ; 0=正, 1=負
pac_bcd     times 10 db 0   ; packed BCD (20桁)


; -------------------------------------------------
; phs_from_i64
;   符号付き I64HS → PHS (pac BCD)
; 入力:
;   DS:SI = I64HS
;   ES:DI = PHS
; -------------------------------------------------
; PHS_VAL  = packed BCD(絶対値)
; PHS_LEN  = 桁数(10進)
; PHS_SIGN = 符号
phs_from_i64:
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    mov bp, di              ; BP = PHS ptr を保持(DIが途中で壊れるので)

    ; -----------------------------
    ; 符号判定(入力は破壊しない:work_areaへコピーしてから)
    ; -----------------------------
    ; work_area = 入力コピー
    push si
    push di
    mov di, work_area
    mov cx, 4
.copy_in:
    mov ax, [si]
    mov [di], ax
    add si, 2
    add di, 2
    loop .copy_in
    pop di
    pop si

    ; work_area の符号で判定
    mov si, work_area
    mov ax, [si + I64HS.HighHigh]
    test ax, 0x8000
    jz .positive

    mov byte [es:bp + PHS_SIGN], 1
    call i64_negate          ; work_area を絶対値化
    jmp .sign_done
.positive:
    mov byte [es:bp + PHS_SIGN], 0
.sign_done:
    ; ---- zero normalization ----
    mov ax, [si + I64HS.LowLow]
    or  ax, [si + I64HS.LowHigh]
    or  ax, [si + I64HS.HighLow]
    or  ax, [si + I64HS.HighHigh]
    jnz .nz

    ; value == 0 → force +0
    mov byte [es:bp + PHS_SIGN], 0

.nz:

    ; -----------------------------
    ; PHS_VAL クリア
    ; -----------------------------
    lea bx, [ds:bp + PHS_VAL]
    xor ax, ax
    mov cx, 20
.clear_val:
    mov [es:bx], al
    inc bx
    loop .clear_val

    ; -----------------------------
    ; double dabble(64回)
    ;   DS:SI = work_area 固定
    ;   ES:DI = BCD base
    ; -----------------------------
    mov si, work_area
    lea di, [ds:bp + PHS_VAL]   ; 先頭10バイトだけ使う(20桁=10バイト)
    mov cx, 64
.dd_loop:
    push cx
    mov cx, 10
    call bcd_add3
    pop cx

    call i64_shl1

    push cx
    mov cx, 10
    call bcd_shl1
    pop cx

    loop .dd_loop

    ; -----------------------------
    ; len 算出(MSB → LSB)
    ; -----------------------------
    mov di, bp              ; di = PHS base

    mov dx, 19              ; 最大桁 index(0..19)
.len_scan:
    mov bx, dx
    shr bx, 1           ; byte index

    mov al, [es:di + PHS_VAL + bx]
    test dl, 1
    jz  .low
    shr al, 4            ; 奇数桁 → high nibble
    jmp .chk
.low:
    and al, 0x0F         ; 偶数桁 → low nibble
.chk:
    cmp al, 0
    jne .found

    dec dx
    jns .len_scan

    ; 全部 0 の場合 → PHS規約: len=0, sign=0
    mov word [es:bp + PHS_LEN], 0
    mov byte [es:bp + PHS_SIGN], 0
    jmp .done

.found:
    inc dx               ; index → 桁数
    mov [es:di + PHS_LEN], dx


    ; ---- PHS zero normalization (MUST be last) ----
    mov ax, [es:di + PHS_LEN]
    test ax, ax
    jnz .nz_i64

    ; len == 0 → force +0
    mov byte [es:di + PHS_SIGN], 0

.nz_i64:

.done:
    push ds
    mov ax, ds
    mov ds, ax
    mov si, bp
    call phs_normalize
    pop ds

    ; ---- PHS invariant: len==0 => sign=0 ----
    mov ax, [es:di + PHS_LEN]
    test ax, ax
    jnz .ret_ok
    mov byte [es:di + PHS_SIGN], 0
.ret_ok:

    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; -------------------------------------------------
; phs_eval_u64
;   PHS (packed BCD, unsigned) -> I64HS (u64)
; input:
;   DS:SI = PHS*
;   ES:DI = I64HS* (output)
; output:
;   CF=0 : success (I64HS filled)
;   CF=1 : failure
;     AX = 1 (NEGATIVE) / 2 (OVERFLOW) / 3 (INVALID)
; note:
;   On failure, output I64HS is cleared to 0.
; destroys:
;   AX,BX,CX,DX,SI
; -------------------------------------------------

%define ERR_PHS_NEG   1
%define ERR_PHS_OVF   2
%define ERR_PHS_INV   3

%define I64_L0  0   ; LowLow
%define I64_L1  2   ; LowHigh
%define I64_H0  4   ; HighLow
%define I64_H1  6   ; HighHigh

; ES:DI = I64HS*
i64hs_zero_esdi:
    xor ax, ax
    mov [es:di + I64_L0], ax
    mov [es:di + I64_L1], ax
    mov [es:di + I64_H0], ax
    mov [es:di + I64_H1], ax
    ret

; ES:DI = I64HS*
; out: CF=1 if overflow
i64hs_add_digit_checked_esdi:
    ; input: AL = digit (0..9)
    xor ah, ah
    add [es:di + I64_L0], ax
    adc word [es:di + I64_L1], 0
    adc word [es:di + I64_H0], 0
    adc word [es:di + I64_H1], 0
    ret

; ============================================
; i64hs_mul10_checked_esdi 完全修正版
; ============================================
; 
; 修正1: SI レジスタを保護
; 修正2: 最終加算後のオーバーフローチェックを追加
; ============================================

; ES:DI = I64HS*
; out: CF=1 if overflow
i64hs_mul10_checked_esdi:
    push si              ; SI を保存
    push bx              ; ★★★ BX を保存 ★★★
    push cx              ; ★★★ CX を保存 ★★★
    
    ; tmp = acc*2, push to stack
    mov ax, [es:di + I64_L0]
    mov dx, [es:di + I64_L1]
    mov cx, [es:di + I64_H0]
    mov bx, [es:di + I64_H1]

    shl ax, 1
    rcl dx, 1
    rcl cx, 1
    rcl bx, 1
    jc .ovf              ; overflow on *2

    push bx
    push cx
    push dx
    push ax

    ; acc*8 (<<3) from original acc (reload)
    mov ax, [es:di + I64_L0]
    mov dx, [es:di + I64_L1]
    mov cx, [es:di + I64_H0]
    mov bx, [es:di + I64_H1]

    mov si, 3
.shift_loop:
    shl ax, 1
    rcl dx, 1
    rcl cx, 1
    rcl bx, 1
    jc .ovf_pop          ; overflow on *8
    dec si
    jnz .shift_loop

    mov [es:di + I64_L0], ax
    mov [es:di + I64_L1], dx
    mov [es:di + I64_H0], cx
    mov [es:di + I64_H1], bx

    ; acc += tmp
    pop ax          ; tmp low
    add [es:di + I64_L0], ax
    pop ax          ; tmp mid1
    adc [es:di + I64_L1], ax
    pop ax          ; tmp mid2
    adc [es:di + I64_H0], ax
    pop ax          ; tmp high
    adc [es:di + I64_H1], ax
    
    ; ★★★ オーバーフローチェック ★★★
    jc .ovf_final
    
    pop cx           ; ★★★ CX を復帰 ★★★
    pop bx           ; ★★★ BX を復帰 ★★★
    pop si
    ret             ; CFは既にクリアされている（jcを通過したので）

.ovf_final:
    pop cx           ; ★★★ CX を復帰 ★★★
    pop bx           ; ★★★ BX を復帰 ★★★
    pop si
    stc
    ret

.ovf_pop:
    add sp, 8
.ovf:
    pop cx           ; ★★★ CX を復帰 ★★★
    pop bx           ; ★★★ BX を復帰 ★★★
    pop si
    stc
    ret

; ============================================
; 動作確認
; ============================================
; 
; 65536の変換:
; i=4 (桁6): SI保持, acc=6
; i=3 (桁5): SI保持, acc=60+5=65
; i=2 (桁5): SI保持 ← ここでSIが壊れていたため、以降の桁が読めなかった
; i=1 (桁3): SI保持, acc=650+5→6550+3=6553
; i=0 (桁6): SI保持, acc=65530+6=65536 ✓


; ---- main API ----
phs_eval_u64:
    push di

    ; clear output first
    call i64hs_zero_esdi

    ; len == 0 => 0 (success)
    mov bx, [si + PHS_LEN]
    test bx, bx
    jz .ok

    ; sign check (unsigned only)
    mov al, [si + PHS_SIGN]
    test al, al
    jz .start

    ; If PHS is not normalized, allow -0 only:
    ; here len!=0, so treat as negative
    pop di
    call i64hs_zero_esdi
    mov ax, ERR_PHS_NEG
    stc
    ret

.start:
    ; iterate digits from MSB to LSB: i = len-1 .. 0
    dec bx                  ; BX = i

    ; CX = フラグ: 最初の桁かどうか (1=最初, 0=それ以降)
    mov cx, 1

.loop:
    ; extract digit i into AL
    mov dx, bx
    shr dx, 1               ; byte index
    push bx
    mov bx, dx
    mov al, [si + PHS_VAL + bx]
    pop bx
    test bl, 1
    jz .low_nib
    shr al, 4
    jmp .digit_ok
.low_nib:
    and al, 0x0F
.digit_ok:
    ; defensive: digit must be 0..9
    cmp al, 9
    jbe .do_step

    pop di
    call i64hs_zero_esdi
    mov ax, ERR_PHS_INV
    stc
    ret

.do_step:
    push ax                 ; digitを保存

    ; 最初の桁でなければ *10
    cmp cx, 0
    je .mul10               ; CX==0 なら *10 実行
    mov cx, 0               ; CX=0 にして次回から *10
    jmp .add_digit          ; 最初の桁は *10 スキップ

.mul10:
    call i64hs_mul10_checked_esdi
    jc .overflow_popdigit

.add_digit:
    pop ax                  ; digitを復帰
    call i64hs_add_digit_checked_esdi
    jc .overflow

    dec bx
    jns .loop
    ; jge .loop

.ok:
    pop di
    clc
    ret

.overflow_popdigit:
    pop ax          ; digit退避分を捨てる
    jmp .overflow

.overflow:
    pop di
    call i64hs_zero_esdi
    mov ax, ERR_PHS_OVF
    stc
    ret

; ===============================
; phs_normalize
;   DS:SI = PHS
;   PHS_LEN を有効桁数に正規化
;   ゼロなら sign=0, len=0 にする
; ===============================

phs_normalize:
    push ax
    push bx
    push cx
    push dx
    push di

    ; cx = len
    mov cx, [si + PHS_LEN]
    test cx, cx
    jnz .check_top

    ; len == 0 → 0(PHS規約)
    mov byte [si + PHS_SIGN], 0
    jmp .done

.check_top:
    ; di = val base
    lea di, [si + PHS_VAL]

.normalize_loop:
    cmp cx, 1
    jbe .check_zero      ; len==1 まで来たら終了候補

    ; top digit index = cx-1
    mov dx, cx
    dec dx

    ; byte index = dx / 2
    mov bx, dx
    shr bx, 1

    mov al, [di + bx]

    ; nibble 選択
    test dl, 1
    jz .low_nib
    shr al, 4
    jmp .chk
.low_nib:
    and al, 0x0F
.chk:
    test al, al
    jne .done_len        ; 非0ならここで終了

    ; 上位 0 桁を捨てる
    dec cx
    jmp .normalize_loop

.done_len:
    mov [si + PHS_LEN], cx
    jmp .done

.check_zero:
    ; len==1 だが digit==0 なら len=0 に
    mov al, [di]
    and al, 0x0F
    test al, al
    jnz .done_len

    mov word [si + PHS_LEN], 0
    mov byte [si + PHS_SIGN], 0

.done:
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    ret

;--------------------------------------------------
; phs_unpack
;   SI = PHS*
;   DI = DHS*
; destroys: AX,BX,CX,DX
;--------------------------------------------------
phs_unpack:
    ; ---- copy len / sign ----
    mov ax, [si + PHS_LEN]
    mov [di + DHS_LEN], ax

    mov al, [si + PHS_SIGN]
    mov [di + DHS_SIGN], al

    ; ---- clear DHS_VAL (40 bytes) ----
    push si
    push di
    lea bx, [di + DHS_VAL]
    mov cx, 40
    xor ax, ax
.clr:
    mov [bx], al
    inc bx
    loop .clr
    pop di
    pop si

    ; ---- unpack digits ----
    ; BX = digit index (0..len-1)
    xor bx, bx
    mov cx, [si + PHS_LEN]

.loop:
    cmp bx, cx
    jae .done

    ; byte index = bx >> 1
    mov dx, bx
    shr dx, 1

    ; read packed byte
    push bx
    mov bx, dx
    mov al, [si + PHS_VAL + bx]
    pop bx

    ; even digit -> low nibble, odd -> high nibble
    test bl, 1
    jz .low

    ; odd: high nibble
    shr al, 4
    jmp .store

.low:
    ; even: low nibble
    and al, 0x0F

.store:
    mov [di + DHS_VAL + bx], al

    inc bx
    jmp .loop

.done:
    ret

;--------------------------------------------------
; phs_pack
;   SI = DHS*
;   DI = PHS*
; destroys: AX,BX,CX,DX
;--------------------------------------------------
phs_pack:
    ; ---- copy len / sign ----
    mov ax, [si + DHS_LEN]
    mov [di + PHS_LEN], ax

    mov al, [si + DHS_SIGN]
    mov [di + PHS_SIGN], al

    ; ---- clear PHS_VAL (20 bytes) ----
    push si
    push di
    lea bx, [di + PHS_VAL]
    mov cx, 20
    xor ax, ax
.clr:
    mov [bx], al
    inc bx
    loop .clr
    pop di
    pop si

    ; ---- pack digits ----
    ; BX = digit index (0..len-1)
    xor bx, bx
    mov cx, [si + DHS_LEN]

.loop:
    cmp bx, cx
    jae .done

    ; get digit (0..9)
    mov al, [si + DHS_VAL + bx]
    and al, 0x0F

    ; byte index = bx >> 1
    mov dx, bx
    shr dx, 1

    ; read current packed byte
    push bx
    mov bx, dx
    mov ah, [di + PHS_VAL + bx]
    pop bx

    ; even digit -> low nibble, odd -> high nibble
    test bl, 1
    jz .low

    ; odd: high nibble
    shl al, 4
    and ah, 0x0F          ; keep low nibble
    or  ah, al
    push bx
    mov bx, dx
    mov [di + PHS_VAL + bx], ah
    pop bx
    jmp .next

.low:
    ; even: low nibble
    and ah, 0xF0          ; keep high nibble
    or  ah, al
    push bx
    mov bx, dx
    mov [di + PHS_VAL + bx], ah
    pop bx

.next:
    inc bx
    jmp .loop

.done:
    ; normalize to ensure zero has sign=0
    push si
    mov si, di
    call phs_normalize
    pop si
    ret

;--------------------------------------------------
; dhs_add_abs
;   SI = DHS *a   (non-negative)
;   BP = DHS *b   (non-negative)
;   DI = DHS *r   (result)
; destroys: AX,BX,CX,DX
;--------------------------------------------------
dhs_add_abs:
    ; ---- clear r.val (40 bytes) ----
    push si
    push bp
    push di
    lea bx, [di + DHS_VAL]
    mov cx, 40
    xor ax, ax
.clr:
    mov [bx], al
    inc bx
    loop .clr
    pop di
    pop bp
    pop si

    ; ---- r.sign = 0 ----
    mov byte [di + DHS_SIGN], 0

    ; ---- max len ----
    mov ax, [si + DHS_LEN]
    mov bx, [ds:bp + DHS_LEN]
    cmp ax, bx
    cmovb ax, bx           ; AX = max(len_a, len_b)
    mov cx, ax             ; CX = maxlen

    xor dx, dx             ; DL = carry (0/1)
    xor bx, bx             ; BX = index i

.loop:
    cmp bx, cx
    jae .after

    ; al = a[i] (or 0)
    mov al, 0
    cmp bx, [si + DHS_LEN]
    jae .a0
    mov al, [si + DHS_VAL + bx]
.a0:

    ; ah = b[i] (or 0)
    mov ah, 0
    cmp bx, [ds:bp + DHS_LEN]
    jae .b0
    push di
    mov di, bp
    mov ah, [di + DHS_VAL + bx]
    pop di
.b0:

    ; sum = al + ah + carry
    add al, ah
    add al, dl

    ; adjust
    cmp al, 10
    jb .store
    sub al, 10
    mov dl, 1
    jmp .st
.store:
    xor dl, dl
.st:
    mov [di + DHS_VAL + bx], al

    inc bx
    jmp .loop

.after:
    ; final carry
    test dl, dl
    jz .len
    cmp cx, 40
    jae .len               ; overflow beyond buffer: drop
    push bx
    mov bx, cx
    mov [di + DHS_VAL + bx], dl
    pop bx
    inc cx

.len:
    mov [di + DHS_LEN], cx
    ret

;--------------------------------------------------
; dhs_cmp_abs
;   SI = DHS *a
;   BP = DHS *b
; out:
;   CF=1 if a<b
;   ZF=1 if a=b
; destroys: AX,BX,CX
;--------------------------------------------------
dhs_cmp_abs:
    ; in:  SI = &DHS a
    ;      BP = &DHS b
    ; out: CF=1 if |a| < |b|, CF=0 otherwise

    ; compare lengths
    mov ax, [si + DHS_LEN]
    mov dx, [ds:bp + DHS_LEN]
    cmp ax, dx
    jb .lt
    ja .ge

    ; same length: compare from highest digit
    mov cx, ax
    jcxz .ge
    dec cx
.cmp_loop:
    push bx
    push di
    mov bx, cx
    mov al, [si + DHS_VAL + bx]
    mov di, bp
    mov dl, [di + DHS_VAL + bx]
    pop di
    pop bx
    cmp al, dl
    jb .lt
    ja .ge
    dec cx
    jns .cmp_loop

.ge:
    clc
    ret
.lt:
    stc
    ret

tmp_borrow db 0

dhs_sub_abs:
    ; SI = minuend (DHS)         ; a
    ; BP = subtrahend (DHS)      ; b
    ; DI = result (DHS)          ; r
    ; assume |a| >= |b|
    ;
    ; r = a - b  (absolute, always non-negative)

    ; ---- init result header ----
    mov byte [di + DHS_SIGN], 0
    mov ax, [si + DHS_LEN]
    mov [di + DHS_LEN], ax

    ; ---- clear result digits (40 bytes) ----
    push di
    lea di, [di + DHS_VAL]
    mov cx, 40
    xor ax, ax
    rep stosb
    pop di

    ; ---- subtract digits LSB -> MSB ----
    mov cx, [si + DHS_LEN]
    jcxz .norm_done

    xor bx, bx                ; i = 0
    mov byte [tmp_borrow], 0  ; borrow = 0

.sub_loop:
    ; al = a[i]
    mov al, [si + DHS_VAL + bx]
    
    ; ah = b[i] (or 0 if i >= b.len)
    push bx
    mov dx, [ds:bp + DHS_LEN]
    cmp bx, dx
    pop bx
    jae .b_is_0
    
    push si
    mov si, bp
    mov ah, [si + DHS_VAL + bx]
    pop si
    jmp .got_b
.b_is_0:
    xor ah, ah
.got_b:

    ; t = ah + borrow
    add ah, [tmp_borrow]
    
    ; if al < t: need borrow
    cmp al, ah
    jb  .need_borrow
    
    ; no borrow
    sub al, ah
    mov byte [tmp_borrow], 0
    jmp .store

.need_borrow:
    add al, 10
    sub al, ah
    mov byte [tmp_borrow], 1

.store:
    mov [di + DHS_VAL + bx], al
    inc bx
    dec cx
    jnz .sub_loop

.norm_done:
    ; ---- normalize result length ----
    push si
    mov si, di
    call dhs_norm
    pop si
    ret

;--------------------------------------------------
; phs_add
;   SI = PHS *a
;   BP = PHS *b
;   DI = PHS *r
;--------------------------------------------------
phs_add:
    push di

    ; unpack a -> dhs_a
    mov di, dhs_a
    call phs_unpack

    ; unpack b -> dhs_b
    push si
    mov si, bp
    mov di, dhs_b
    call phs_unpack
    pop si

    ; check signs
    mov al, [dhs_a + DHS_SIGN]
    mov ah, [dhs_b + DHS_SIGN]
    cmp al, ah
    je .same_sign

    ; different signs → use subtraction
    ; compare |a| vs |b|
    mov si, dhs_a
    mov bp, dhs_b
    push cx
    call dhs_cmp_abs
    pop cx
    jc .b_gt_a

.a_ge_b:
    ; r = a - b
    mov si, dhs_a
    mov bp, dhs_b
    mov di, dhs_r
    push cx
    call dhs_sub_abs
    pop cx

    ; r.sign = a.sign
    mov al, [dhs_a + DHS_SIGN]
    mov [dhs_r + DHS_SIGN], al
    jmp .pack

.b_gt_a:
    ; r = b - a
    mov si, dhs_b
    mov bp, dhs_a
    mov di, dhs_r
    push cx
    call dhs_sub_abs
    pop cx

    ; r.sign = b.sign
    mov al, [dhs_b + DHS_SIGN]
    mov [dhs_r + DHS_SIGN], al
    jmp .pack

.same_sign:
    ; same sign → add absolute values
    mov si, dhs_a
    mov bp, dhs_b
    mov di, dhs_r
    call dhs_add_abs

    ; r.sign = common sign
    mov al, [dhs_a + DHS_SIGN]
    mov [dhs_r + DHS_SIGN], al

.pack:
    ; ---- PHS zero normalization ----
    mov ax, [dhs_r + DHS_LEN]
    test ax, ax
    jnz .nz
    mov byte [dhs_r + DHS_SIGN], 0   ; kill -0
.nz:
    ; ---- pack result ----
    mov si, dhs_r
    pop di
    call phs_pack
    ret


dhs_a:
    times 40 db 0
    dw 0
    db 0

dhs_b:
    times 40 db 0
    dw 0
    db 0

dhs_q:
    times 40 db 0
    dw 0
    db 0

tmp_div_qdigit db 0
tmp_div_guard  db 0
dhs_div_b_local dw 0

dhs_r:
    times 40 db 0
    dw 0
    db 0

dhs_div_tmp:
    times 40 db 0
    dw 0
    db 0

;--------------------------------------------------
; phs_sub
;   SI = PHS *a
;   BP = PHS *b
;   DI = PHS *r
;--------------------------------------------------
phs_sub:
    ; ---- flip b.sign temporarily ----
    mov al, [ds:bp + PHS_SIGN]
    xor byte [ds:bp + PHS_SIGN], 1
    push ax
    push bp

    call phs_add

    ; ---- restore b.sign ----
    pop bp
    pop ax
    mov [ds:bp + PHS_SIGN], al
    ret

;--------------------------------------------------
; dhs_mul_abs
;   SI = DHS *a
;   BP = DHS *b
;   DI = DHS *r
; destroys: AX,BX,CX,DX,SI,BP
;--------------------------------------------------
dhs_mul_abs:
    ; ---- clear r ----
    lea bx, [di + DHS_VAL]
    mov cx, 40
    xor ax, ax
.mclr:
    mov [bx], al
    inc bx
    loop .mclr
    mov byte [di + DHS_SIGN], 0
    mov word [di + DHS_LEN], 0

    ; if a.len==0 or b.len==0 -> zero
    mov ax, [si + DHS_LEN]
    test ax, ax
    jz .done
    mov ax, [ds:bp + DHS_LEN]
    test ax, ax
    jz .done

    xor bx, bx              ; i = 0
.outer:
    cmp bx, [si + DHS_LEN]
    jae .normalize

    xor cx, cx              ; carry = 0
    xor dx, dx              ; j = 0
.inner:
    cmp dx, [ds:bp + DHS_LEN]
    jae .carry_out

    ; al = a[i] * b[j]
    mov al, [si + DHS_VAL + bx]
    push di
    push bx
    mov di, bp
    mov bx, dx
    mov ah, [di + DHS_VAL + bx]
    pop bx
    pop di
    mul ah                  ; AX = al * ah (0..81)

    ; add existing r[i+j] and carry
    push bx
    add bx, dx
    add al, [di + DHS_VAL + bx]
    pop bx
    adc ah, 0
    add al, cl              ; cl = carry (0..?)
    adc ah, 0

    ; new digit / carry
    aam                 ; AH = AL/10, AL = AL%10
    mov cl, ah          ; carry = AH
.store:
    push bx
    add bx, dx
    mov [di + DHS_VAL + bx], al
    pop bx

    inc dx
    jmp .inner

.carry_out:
    test cl, cl
    jz .next_i
    push bx
    add bx, dx
    mov [di + DHS_VAL + bx], cl
    pop bx

.next_i:
    inc bx
    jmp .outer

.normalize:
    ; ---- compute len ----
    mov cx, 40
    dec cx
.nloop:
    push bx
    mov bx, cx
    mov al, [di + DHS_VAL + bx]
    pop bx
    test al, al
    jnz .setlen
    test cx, cx
    jz .done
    dec cx
    jmp .nloop
.setlen:
    inc cx
    mov [di + DHS_LEN], cx

.done:
    ret

;--------------------------------------------------
; phs_mul
;   SI = PHS *a
;   BP = PHS *b
;   DI = PHS *r
;--------------------------------------------------
phs_mul:
    push di

    mov di, dhs_a
    call phs_unpack

    push si
    mov si, bp
    mov di, dhs_b
    call phs_unpack
    pop si

    ; r.sign = a.sign XOR b.sign
    mov al, [dhs_a + DHS_SIGN]
    xor al, [dhs_b + DHS_SIGN]
    push ax

    mov si, dhs_a
    mov bp, dhs_b
    mov di, dhs_r
    call dhs_mul_abs

    pop ax
    mov [dhs_r + DHS_SIGN], al

    ; ---- zero normalization ----
    mov ax, [dhs_r + DHS_LEN]
    test ax, ax
    jnz .nz
    mov byte [dhs_r + DHS_SIGN], 0
.nz:

    pop di
    mov si, dhs_r
    call phs_pack
    ret

;--------------------------------------
; phs_cmp
;   SI = PHS *a
;   BP = PHS *b
; return flags:
;   ZF=1 : equal
;   CF=1 : a < b
;--------------------------------------
phs_cmp:
    mov al, [si + PHS_SIGN]
    mov [orig_a_sign], al
    mov ah, [ds:bp + PHS_SIGN]
    cmp al, ah
    je  .same_sign

    ; 符号が違う
    test al, al
    jz  .a_pos_b_neg   ; a=+, b=-

    ; a=-, b=+  → a < b  (CF=1, ZF=0)
    mov ax, 0
    cmp ax, 1
    ret

.a_pos_b_neg:
    ; a=+, b=-  → a > b  (CF=0, ZF=0)
    mov ax, 1
    cmp ax, 0
    ret

.same_sign:
    ; 両方 0 の場合(len=0)
    mov ax, [si + PHS_LEN]
    or  ax, [ds:bp + PHS_LEN]
    jnz .do_abs

    ; both zero
    xor ax, ax          ; ZF=1, CF=0
    ret

.do_abs:
    ; unpack a,b → dhs_a, dhs_b
    push si
    push bp

    mov di, dhs_a
    call phs_unpack
    mov si, bp
    mov di, dhs_b
    call phs_unpack

    pop bp
    pop si

    ; compare |a| ? |b|
    mov si, dhs_a
    mov bp, dhs_b
    push cx
    call dhs_cmp_abs    ; CF/ZF set for abs compare
    pop cx

    ; if a is negative, invert result (except equal)
    mov al, [orig_a_sign]
    test al, al
    jz .done            ; positive-positive → keep result

    ; negative-negative
    jz .done            ; ZF=1 (equal) → do not invert
    cmc                 ; invert CF only

.done:
    ret

orig_a_sign db 0


;--------------------------------------
; dhs_div_abs
;--------------------------------------
; dhs_div_abs (FIXED: preserves SI=a)
; SI = DHS *a   (dividend)
; BP = DHS *b   (divisor)
; DI = DHS *q   (quotient)
; BX = DHS *r   (remainder)
; return CF=1 if b==0
;--------------------------------------
dhs_div_abs:
    push es
    push ds
    pop es

    mov [dhs_div_b_local], bp
    mov [tmp_div_dhs_q_ptr], di   ; 新しいワーク変数
    ; mov ax, bp
    ; PUTC '['
    ; call phd4
    ; PUTC ']'


     ; b==0 ?
    mov ax, [ds:bp + DHS_LEN]
    test ax, ax
    jnz .b_ok
    stc
    pop es
    ret
.b_ok:
    clc

    push si              ; ★ aポインタ退避

    ; --- clear Q ---
    push di
    mov cx, 40
    lea si, [di + DHS_VAL]
    xor al, al
.qclr:
    mov [si], al
    inc si
    loop .qclr
    mov word [di + DHS_LEN], 0
    pop di

    ; --- clear R ---
    push bx
    mov cx, 40
    lea si, [bx + DHS_VAL]
    xor al, al
.rclr:
    mov [si], al
    inc si
    loop .rclr
    mov word [bx + DHS_LEN], 0
    pop bx

    pop si               ; ★ aポインタ復帰(これが重要)

    ; --- main loop: i = a.len-1 .. 0 ---
    mov cx, [si + DHS_LEN]
    test cx, cx
    jz .done
    ; jcxz .done
    dec cx

    ; ; デバッグ: .loop_i開始直前のBXとRの値を確認
    ; push ax
    ; PUTC 'B'
    ; PUTC 'E'
    ; PUTC 'F'
    ; PUTC 'O'
    ; PUTC 'R'
    ; PUTC 'E'
    ; PUTC '_'
    ; PUTC 'L'
    ; PUTC 'O'
    ; PUTC 'O'
    ; PUTC 'P'
    ; PUTC ':'
    ; PUTC 'B'
    ; PUTC 'X'
    ; PUTC '='
    ; mov ax, bx
    ; call phd4
    ; PUTC ' '
    ; PUTC 'd'
    ; PUTC 'h'
    ; PUTC 's'
    ; PUTC '_'
    ; PUTC 'r'
    ; PUTC '='
    ; mov ax, dhs_r
    ; call phd4
    ; PUTC 0x0d
    ; PUTC 0x0a
    ; pop ax

.loop_i:
    ; ; デバッグ: Rの値を出力
    ; push si
    ; push bx
    ; push cx
    ; mov si, bx
    ; mov cx, 43
    ; call dump_mem
    ; PUTC 0x0d
    ; PUTC 0x0a
    ; pop cx
    ; pop bx
    ; pop si
    
    ; R = R * 10
    push si
    push bx
    mov si, bx
    call dhs_mul10
    pop bx
    pop si

    ; ; デバッグ: Rの値を出力
    ; push si
    ; push bx
    ; push cx
    ; push ax
    ; PUTC 'S'
    ; PUTC 'I'
    ; PUTC '='
    ; mov ax, si
    ; call phd4
    ; PUTC ' '
    ; PUTC 'd'
    ; PUTC 'h'
    ; PUTC 's'
    ; PUTC '_'
    ; PUTC 'a'
    ; PUTC '='
    ; mov ax, dhs_a
    ; call phd4
    ; PUTC ' '
    ; PUTC 'i'
    ; PUTC '='
    ; mov ax, cx
    ; call phd4
    ; PUTC ' '
    ; PUTC 'a'
    ; PUTC '['
    ; PUTC 'i'
    ; PUTC ']'
    ; PUTC '='
    ; push bx
    ; mov bx, cx
    ; mov al, [si + DHS_VAL + bx]
    ; pop bx
    ; call phd2
    ; PUTC 0x0d
    ; PUTC 0x0a
    ; pop ax
    ; pop cx
    ; pop bx
    ; pop si

    ; R += a[i]
    push bx
    push si
    mov bx, cx
    mov al, [si + DHS_VAL + bx]
    pop si
    pop bx

    ; ; デバッグ: 追加する桁を表示
    ; push ax
    ; PUTC '['
    ; call phd2
    ; PUTC ']'
    ; PUTC 0x0d
    ; PUTC 0x0a
    ; pop ax

    push si
    push bx          ; BXを保存（dhs_add_digitがBXを破壊するため）
    push cx
    mov si, bx
    call dhs_add_digit
    pop cx
    pop bx           ; BXを復元
    pop si
    
    ; ; SI_RESTORED を表示
    ; push si
    ; push ax
    ; PUTC 'S'
    ; PUTC 'I'
    ; PUTC '_'
    ; PUTC 'R'
    ; PUTC 'E'
    ; PUTC 'S'
    ; PUTC 'T'
    ; PUTC 'O'
    ; PUTC 'R'
    ; PUTC 'E'
    ; PUTC 'D'
    ; PUTC '='
    ; mov ax, si
    ; call phd4
    ; PUTC 0x0d
    ; PUTC 0x0a
    ; pop ax
    ; pop si

    ; ; AFTER_ADD: BX と len を表示
    ; push si
    ; push bx
    ; push cx
    ; push ax
    ; PUTC 'A'
    ; PUTC 'F'
    ; PUTC 'T'
    ; PUTC 'E'
    ; PUTC 'R'
    ; PUTC '_'
    ; PUTC 'A'
    ; PUTC 'D'
    ; PUTC 'D'
    ; PUTC ':'
    ; PUTC 'B'
    ; PUTC 'X'
    ; PUTC '='
    ; mov ax, bx
    ; call phd4
    ; PUTC ' '
    ; PUTC 'l'
    ; PUTC 'e'
    ; PUTC 'n'
    ; PUTC '='
    ; mov ax, [bx + DHS_LEN]
    ; call phd4
    ; PUTC 0x0d
    ; PUTC 0x0a
    ; pop ax
    ; pop cx
    ; pop bx
    ; pop si
    
    ; ; デバッグ: Rの値を出力
    ; push si
    ; push bx
    ; push cx
    ; mov si, bx
    ; mov cx, 43
    ; call dump_mem
    ; PUTC 0x0d
    ; PUTC 0x0a
    ; pop cx
    ; pop bx
    ; pop si

    ; q_digit = 0
    xor dl, dl

    ; デバッグ: tmp_div_qdigit のアドレスを出力
    ; push ax
    ; PUTC 't'
    ; PUTC 'm'
    ; PUTC 'p'
    ; PUTC '_'
    ; PUTC 'q'
    ; PUTC '='
    ; mov ax, tmp_div_qdigit
    ; call phd4
    ; PUTC ' '
    ; PUTC '('
    ; mov ax, dhs_r
    ; add ax, 40
    ; call phd4
    ; PUTC ')'
    ; PUTC 0x0d
    ; PUTC 0x0a
    ; pop ax

    mov byte [tmp_div_qdigit], 0
    mov byte [tmp_div_guard], 10      ; 最大10回(0..9が上限)

.try_sub:
    dec byte [tmp_div_guard]
    jz .store_qdigit

    ; ; デバッグ: R の内容を再度出力
    ; push si
    ; push bx
    ; push cx
    ; PUTC 'R'
    ; PUTC '_'
    ; PUTC 'd'
    ; PUTC 'u'
    ; PUTC 'm'
    ; PUTC 'p'
    ; PUTC ':'
    ; mov si, bx
    ; mov cx, 43
    ; call dump_mem
    ; PUTC 0x0d
    ; PUTC 0x0a
    ; pop cx
    ; pop bx
    ; pop si

    ; if R < B => store
    mov bp, [dhs_div_b_local]
    
    ; ; デバッグ: BX と BP のアドレスを出力
    ; push ax
    ; PUTC 'B'
    ; PUTC 'X'
    ; PUTC '='
    ; mov ax, bx
    ; call phd4
    ; PUTC ' '
    ; PUTC 'B'
    ; PUTC 'P'
    ; PUTC '='
    ; mov ax, bp
    ; call phd4
    ; PUTC ' '
    ; PUTC 'd'
    ; PUTC 'h'
    ; PUTC 's'
    ; PUTC '_'
    ; PUTC 'r'
    ; PUTC '='
    ; mov ax, dhs_r
    ; call phd4
    ; PUTC 0x0d
    ; PUTC 0x0a
    ; pop ax
    
    ; ; デバッグ: R と B の情報を出力
    ; push si
    ; push bx
    ; push ax
    ; push dx
    ; PUTC 'R'
    ; PUTC '='
    ; mov ax, [bx + DHS_LEN]
    ; call phd4
    ; PUTC ':'
    ; mov al, [bx + DHS_VAL]
    ; call phd2
    ; PUTC ' '
    ; PUTC 'B'
    ; PUTC '='
    ; mov ax, [ds:bp + DHS_LEN]
    ; call phd4
    ; PUTC ':'
    ; mov al, [ds:bp + DHS_VAL]
    ; call phd2
    ; PUTC 0x0d
    ; PUTC 0x0a
    ; pop dx
    ; pop ax
    ; pop bx
    ; pop si
    
    push si
    push bx          ; ★追加
    push cx

    mov si, bx
    call dhs_cmp_abs

    pop cx
    pop bx           ; ★追加
    pop si
    
;     ; デバッグ: 比較結果を出力
;     ; まず結果を表示してから、もう一度フラグを設定
;     jc .show_lt
;     pushf          ; CF=0 を保存
;     PUTC 'G'
;     PUTC 'E'
;     jmp .show_done
; .show_lt:
;     pushf          ; CF=1 を保存
;     PUTC 'L'
;     PUTC 'T'
; .show_done:
;     PUTC 0x0d
;     PUTC 0x0a
    
    ; CF を復元
    ; popf
    
    jc .store_qdigit        ; CF=1 if R<B

    ; ; デバッグ: 引き算が実行されることを確認
    ; PUTC 'S'
    ; PUTC 'U'
    ; PUTC 'B'
    ; PUTC '!'
    ; PUTC 0x0d
    ; PUTC 0x0a

    ; R -= B;
     ; R -= B
    mov bp, [dhs_div_b_local]
    push di          ; ★DI (Q のアドレス) を保存
    push si
    push bx          ; ★追加:Rポインタ保持

    mov si, bx
    mov di, dhs_div_tmp
    push cx
    call dhs_sub_abs
    pop cx

    pop bx           ; ★BX を復元(dhs_sub_abs が BX を破壊するため)
    push bx          ; ★再度保存

    mov si, dhs_div_tmp
    mov di, bx
    call dhs_copy

    pop bx           ; ★追加
    pop si
    pop di           ; ★DI を復元

    ; ; デバッグ: 引き算後の R を確認
    ; push si
    ; push bx
    ; push cx
    ; PUTC 'A'
    ; PUTC 'F'
    ; PUTC 'T'
    ; PUTC '_'
    ; PUTC 'S'
    ; PUTC 'U'
    ; PUTC 'B'
    ; PUTC ':'
    ; mov si, bx
    ; mov cx, 43
    ; call dump_mem
    ; PUTC 0x0d
    ; PUTC 0x0a
    ; pop cx
    ; pop bx
    ; pop si

    inc byte [tmp_div_qdigit]
    jmp .try_sub


.store_qdigit:
    mov di, [tmp_div_dhs_q_ptr]
    mov al, [tmp_div_qdigit]
    
    ; ; デバッグ: 格納する商の桁を表示
    ; push ax
    ; PUTC 'Q'
    ; PUTC 'D'
    ; PUTC 'I'
    ; PUTC 'G'
    ; PUTC 'I'
    ; PUTC 'T'
    ; PUTC '='
    ; call phd2
    ; PUTC ' '
    ; PUTC 'C'
    ; PUTC 'X'
    ; PUTC '='
    ; mov ax, cx
    ; call phd4
    ; PUTC ' '
    ; PUTC 'D'
    ; PUTC 'I'
    ; PUTC '='
    ; mov ax, di
    ; call phd4
    ; PUTC ' '
    ; PUTC 'd'
    ; PUTC 'h'
    ; PUTC 's'
    ; PUTC '_'
    ; PUTC 'q'
    ; PUTC '='
    ; mov ax, dhs_q
    ; call phd4
    ; PUTC 0x0d
    ; PUTC 0x0a
    ; pop ax
    
    push bx
    mov bx, cx
    mov [di + DHS_VAL + bx], al
    pop bx

    dec cx
    jns .loop_i

.done:
    ; 商の長さを計算: a.lenと同じ長さから始めて、実際の桁数を求める
    ; push si
    ; mov si, [tmp_div_phs_a_ptr]
    ; mov cx, [si + PHS_LEN]    ; 被除数の桁数
    ; pop si

    ; q.len を仮セット（a.len）
    push ax
    mov ax, [si + DHS_LEN]        ; SI は a を指してる前提（今の実装はそう）
    mov [di + DHS_LEN], ax        ; DI は q
    pop ax

    ; Q のlen正規化
    push si
    mov si, di        ; si = DHS*q
    call dhs_norm
    pop si

    ; R も念のため（余り側はsubで縮むので）
    push si
    mov si, bx        ; si = dhs_r
    call dhs_norm
    pop si

    pop es
    ret

    ; 商の最上位桁を探す
    test cx, cx
    jz .q_zero
    dec cx
.find_q_len:
    push bx
    mov bx, cx
    cmp byte [di + DHS_VAL + bx], 0
    pop bx
    jne .set_q_len
    test cx, cx
    jz .q_zero
    dec cx
    jmp .find_q_len
    
.set_q_len:
    inc cx
    mov [di + DHS_LEN], cx
    pop es
    ret
    
.q_zero:
    mov word [di + DHS_LEN], 0
    pop es
    ret

;--------------------------------------
; dhs_mul_digit
;--------------------------------------
; dhs_mul_digit
;   SI = DHS *x
;   AL = digit (0..10)   ; 10 を使うのが div 用
; result:
;   x *= AL
; destroys: AX,BX,CX,DX
; preserves: flags 不問
;--------------------------------------
; dhs_mul_digit (digit 0..9 専用)
;   SI = DHS *x
;   AL = digit (0..9)
;--------------------------------------
dhs_mul_digit:
    ; AL = digit (0..9), x *= digit (SI)
    ; NOTE: keeps result within 40 digits (drops overflow carry)

    ; digit==0 → x=0
    test al, al
    jnz .digit_nonzero
    mov word [si + DHS_LEN], 0
    ret
.digit_nonzero:

    mov cx, [si + DHS_LEN]
    test cx, cx
    jz .done

    and al, 0x0F
    mov dl, al              ; digit

    xor di, di              ; index
    xor bl, bl              ; carry (0..9)

.loop:
    cmp di, cx
    jae .carry_out

    push bx
    mov bx, di
    mov al, [si + DHS_VAL + bx]   ; 0..9
    pop bx

    mul dl                         ; AX = AL*DL (0..81)
    add al, bl                     ; +carry (0..90)
    aam                            ; AH=carry(0..9), AL=digit(0..9)

    push bx
    mov bx, di
    mov [si + DHS_VAL + bx], al
    pop bx

    mov bl, ah
    inc di
    jmp .loop

.carry_out:
    test bl, bl
    jz .setlen

    cmp di, 40
    jae .setlen                    ; overflow: drop carry

    push bx
    mov bx, di
    mov [si + DHS_VAL + bx], bl
    pop bx
    inc di

.setlen:
    cmp di, 40
    jbe .oklen
    mov di, 40
.oklen:
    mov [si + DHS_LEN], di
.done:
    ret


mul_src db 0

;--------------------------------------
; dhs_add_digit
;--------------------------------------
; dhs_add_digit
;   SI = DHS *x
;   AL = digit (0..9)
;   x += digit
; destroys: AX,BX,CX,DX,DI
;--------------------------------------
dhs_add_digit:
    ; AL = digit (0..9), x += digit (SI)
    ; NOTE: keeps result within 40 digits (drops overflow carry)

    and al, 0x0F
    cmp al, 9
    jbe .okdigit
    xor al, al
.okdigit:
    mov bl, al              ; carry (0..9)

    mov cx, [si + DHS_LEN]
    test cx, cx
    jnz .have_len

    ; len=0
    test bl, bl
    jz .done
    mov [si + DHS_VAL + 0], bl
    mov word [si + DHS_LEN], 1
    ret

.have_len:
    xor di, di              ; index=0

.loop:
    cmp di, cx
    jb .inrange

    ; extend if carry != 0
    test bl, bl
    jz .done_update_len     

    cmp di, 40
    jae .done               ; overflow: drop carry

    push bx
    mov bx, di
    mov [si + DHS_VAL + bx], bl
    pop bx
    inc di
    mov [si + DHS_LEN], di
    ret

.inrange:
    push bx
    mov bx, di
    mov al, [si + DHS_VAL + bx]
    pop bx

    add al, bl
    cmp al, 10
    jb .no_carry
    sub al, 10
    mov bl, 1
    jmp .store
.no_carry:
    xor bl, bl
.store:
    push bx
    mov bx, di
    mov [si + DHS_VAL + bx], al
    pop bx

    inc di
    jmp .loop

.done_update_len:           ; ← 追加
    mov [si + DHS_LEN], di
.done:
    ret


;--------------------------------------
; phs_mul_digit
;--------------------------------------
; phs_mul_digit
;   SI = PHS *a
;   AL = digit (0..9)   ; (×10 は別: dhs_mul10)
;   DI = PHS *r
;--------------------------------------
;--------------------------------------
; phs_mul_digit
;   SI = PHS *a
;   AL = digit (0..9)
;   DI = PHS *r
;--------------------------------------
phs_mul_digit:
    mov [bcd_tmp_digit], al   ; digit save
    push di                   ; save r

    ; r = a
    call phs_copy             ; SI=a, DI=r (SI/DI壊れるけどOK)

    ; if r == 0 -> normalize and return
    mov ax, [di + PHS_LEN]
    test ax, ax
    jnz .doit
    mov byte [di + PHS_SIGN], 0
    pop di
    ret

.doit:
    ; unpack r -> dhs_r
    push si
    mov si, di
    mov di, dhs_r
    call phs_unpack
    pop si

    ; dhs_r *= digit
    mov al, [bcd_tmp_digit]
    mov si, dhs_r
    call dhs_mul_digit

    ; pack dhs_r -> phs_tmp
    mov si, dhs_r
    mov di, phs_tmp
    call phs_pack

    ; 0正規化(len==0ならsign=0)
    mov ax, [di + PHS_LEN]
    test ax, ax
    jnz .copyback
    mov byte [di + PHS_SIGN], 0

.copyback:
    ; phs_tmp -> r
    pop di                    ; restore r
    mov si, phs_tmp
    call phs_copy
    ret


;--------------------------------------
; phs_add_digit
;--------------------------------------
; phs_add_digit
;   SI = PHS *a
;   AL = digit (0..9)
;   DI = PHS *r
;--------------------------------------
;--------------------------------------
; phs_add_digit
;   SI = PHS *a
;   AL = digit (0..9)
;   DI = PHS *r
;--------------------------------------
phs_add_digit:
    mov [bcd_tmp_digit], al
    push di                   ; save r

    ; r = a
    call phs_copy

    ; unpack r -> dhs_r
    push si
    mov si, di
    mov di, dhs_r
    call phs_unpack
    pop si

    ; dhs_r += digit
    mov al, [bcd_tmp_digit]
    mov si, dhs_r
    push cx
    call dhs_add_digit
    pop cx

    ; pack dhs_r -> phs_tmp
    mov si, dhs_r
    mov di, phs_tmp
    call phs_pack

    ; 0正規化
    mov ax, [di + PHS_LEN]
    test ax, ax
    jnz .copyback
    mov byte [di + PHS_SIGN], 0

.copyback:
    pop di                    ; restore r
    mov si, phs_tmp
    call phs_copy
    ret

r_phs_tmp times 23 db 0
phs_tmp times 23 db 0
bcd_tmp_digit db 0

;--------------------------------------
; phs_copy
;--------------------------------------
; phs_copy
;   SI = PHS *src
;   DI = PHS *dst
; preserves: SI, DI
; destroys: AX, CX
;--------------------------------------
phs_copy:
    push si
    push di
    mov cx, 23

.copy:
    mov al, [si]
    mov [di], al
    inc si
    inc di
    loop .copy

    pop di
    pop si
    ret


;--------------------------------------
; dhs_mul10
;   SI = DHS *x
;   x *= 10   (decimal shift left)
;--------------------------------------
dhs_mul10:
    push cx
    mov cx, [si + DHS_LEN]
    test cx, cx
    jz .done

    cmp cx, 40
    jae .done          ; これを追加:これ以上伸ばさない(ヘッダ保護)

    dec cx
.shift:
    push bx
    mov bx, cx
    mov al, [si + DHS_VAL + bx]
    mov [si + DHS_VAL + bx + 1], al
    pop bx
    dec cx
    jns .shift

    mov byte [si + DHS_VAL], 0
    inc word [si + DHS_LEN]
.done:
    pop cx
    ret

;--------------------------------------
; phs_div
;--------------------------------------
; phs_div
;   SI = PHS *a   (dividend)
;   BP = PHS *b   (divisor)
;   DI = PHS *q   (quotient)
;   BX = PHS *r   (remainder)
; return:
;   CF=1 → divide by zero
;   CF=0 → ok
;--------------------------------------
tmp_div_phs_a_ptr   dw 0
tmp_div_phs_b_ptr   dw 0
tmp_div_phs_q_ptr   dw 0
tmp_div_phs_r_ptr   dw 0
tmp_div_asign   db 0
tmp_div_bsign   db 0
tmp_div_dhs_a_ptr   dw 0
tmp_div_dhs_b_ptr   dw 0
tmp_div_dhs_q_ptr   dw 0
tmp_div_dhs_r_ptr   dw 0

phs_div:
;     PUTC '('
;     mov ax, dhs_a
;     call phd4
;     PUTC ')'
;    PUTC '('
;     mov ax, dhs_b
;     call phd4
;     PUTC ')'
;    PUTC '('
;     mov ax, dhs_q
;     call phd4
;     PUTC ')'
;    PUTC '('
;     mov ax, dhs_r
;     call phd4
;     PUTC ')'
;    PUTC '('
;     mov ax, DHS_SIGN
;     call phd2
;     PUTC ')'

    push si
    mov si, dhs_q
    call dhs_clear
    mov si, dhs_r
    call dhs_clear
    pop si

    ; save pointers
    mov [tmp_div_phs_a_ptr], si
    mov [tmp_div_phs_b_ptr], bp
    mov [tmp_div_phs_q_ptr], di
    mov [tmp_div_phs_r_ptr], bx

    ; save signs
    mov al, [si + PHS_SIGN]
    mov [tmp_div_asign], al
    mov al, [bp + PHS_SIGN]
    mov [tmp_div_bsign], al

    ; divide by zero?
    mov ax, [bp + PHS_LEN]
    test ax, ax
    jnz .b_ok
    stc
    ret
.b_ok:
    clc

    ; a == 0 ?
    mov ax, [si + PHS_LEN]
; PUTC '('
; call phd4
; PUTC ')'
; PUTC 0x0d
; PUTC 0x0a
    test ax, ax
    jnz .a_nonzero

    ; PUTC '('
    ; mov ax, dhs_b
    ; call phd4
    ; PUTC ')'

    ; q=0, r=0
    mov di, [tmp_div_phs_q_ptr]
    mov word [di + PHS_LEN], 0
    mov byte [di + PHS_SIGN], 0
    mov di, [tmp_div_phs_r_ptr]
    mov word [di + PHS_LEN], 0
    mov byte [di + PHS_SIGN], 0
    ; ret
    jmp .done

.a_nonzero:
    ; unpack a -> dhs_a
    mov si, [tmp_div_phs_a_ptr]
    mov di, dhs_a
    call phs_unpack

; PUTC 'A'
; PUTC ':'
; mov si, dhs_a
; mov cx, 43
; call dump_mem
; PUTC 0x0d
; PUTC 0x0a

    ; unpack b -> dhs_b
    mov si, [tmp_div_phs_b_ptr]
    mov di, dhs_b
    call phs_unpack

; PUTC 'B'
; PUTC ':'
; mov si, dhs_b
; mov cx, 43
; call dump_mem
; PUTC 0x0d
; PUTC 0x0a 


    ; abs division: dhs_q, dhs_r
    mov si, dhs_a
    mov bp, dhs_b
    mov di, dhs_q
    mov bx, dhs_r
    call dhs_div_abs
 
; PUTC 'Q'
; PUTC ':'
; mov si, dhs_q
; mov cx, 43
; call dump_mem
; PUTC 0x0d
; PUTC 0x0a

; PUTC 'R'
; PUTC ':'
; mov si, dhs_r
; mov cx, 43
; call dump_mem
; PUTC 0x0d
; PUTC 0x0a 
 
 
    jc .done              ; 念のため(b==0のとき)

    ; pack quotient -> PHS q
    mov si, dhs_q
    mov di, [tmp_div_phs_q_ptr]
    call phs_pack

    ; q.sign = a.sign XOR b.sign
    mov al, [tmp_div_asign]
    xor al, [tmp_div_bsign]
    mov [di + PHS_SIGN], al
    ; zero normalize
    mov ax, [di + PHS_LEN]
    test ax, ax
    jnz .q_ok
    mov byte [di + PHS_SIGN], 0
.q_ok:

    ; pack remainder -> PHS r
    mov si, dhs_r
    mov di, [tmp_div_phs_r_ptr]
    call phs_pack

    ; r.sign = a.sign
    mov al, [tmp_div_asign]
    mov [di + PHS_SIGN], al
    ; zero normalize
    mov ax, [di + PHS_LEN]
    test ax, ax
    jnz .r_ok
    mov byte [di + PHS_SIGN], 0
.r_ok:

.done:
    ret




;--------------------------------------
; dhs_clear
;--------------------------------------
; SI = DHS*
dhs_clear:
    push ax
    push cx
    push di

    lea di, [si + DHS.val]
    xor ax, ax
    mov cx, 40
.rep:
    mov [di], al
    inc di
    loop .rep

    mov word [si + DHS.len], 0
    mov byte [si + DHS.sign], 0

    pop di
    pop cx
    pop ax
    ret

; si = DHS*
dhs_norm:
    mov cx, [si + DHS_LEN]
    jcxz .done

    dec cx
.loop:
    push bx
    mov bx, cx
    mov al, [si + DHS_VAL + bx]
    pop bx
    cmp al, 0
    jne .set_len
    dec cx
    jns .loop

    ; 全部 0
    mov word [si + DHS_LEN], 0
    ret

.set_len:
    inc cx
    mov [si + DHS_LEN], cx
.done:
    ret

; dhs_copy
;   SI = DHS *src
;   DI = DHS *dst
; destroys: AX,CX
dhs_copy:
    push si
    push di
    mov cx, 43
.copy:
    mov al, [si]
    mov [di], al
    inc si
    inc di
    loop .copy
    pop di
    pop si
    ret

; %if DHS_VAL != 0
;     %error DHS_VAL offset is wrong
; %endif
; %if DHS_LEN != 40
;     %error DHS_LEN offset is wrong
; %endif
; %if DHS_SIGN != 42
;     %error DHS_SIGN offset is wrong
; %endif
