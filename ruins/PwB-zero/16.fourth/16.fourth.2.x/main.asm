;org 0x0000
bits 16

%include "routine.inc"

jmp setup
;********************************
; 各種定義
;********************************

section .data

parent_seg     equ 0x8000
k_task_seg     equ 0x9000

ctx_k_task_sp equ 0x7000

k_task_sector  equ 10       ; 子1はセクタ10から読み込む

irq0_vector    equ 0x20

;; === 先頭に追加 === ;;
context_ip     equ 0
context_cs     equ 2
context_flags  equ 4
context_ax     equ 6
context_bx     equ 8
context_cx     equ 10
context_dx     equ 12
context_si     equ 14
context_di     equ 16
context_bp     equ 18
context_ds     equ 20
context_es     equ 22
context_fs     equ 24
context_gs     equ 26
context_ss     equ 28
context_sp     equ 30
context_id     equ 32
context_size   equ 34

current_counter dw 0


ctx_k_task equ 0x9000

already_ex dw 0x0000

temp_ip dw 0
temp_cs dw 0
temp_flags  dw 0
temp_si dw 0
temp_ss dw 0
temp_sp dw 0
temp_ax dw 0
temp_bx dw 0

next_ip dw 0
next_cs dw 0
next_flags dw 0

call_counter dw 0x0000

section .data

putc_ptr: dd 0

section .text


;********************************
; 開始
;********************************

section .text

global _start

_start:

;********************************
; セットアップ
;********************************
setup:
    cli
    call init_env
    call load_k_task

    call init_pit
    call init_pic

    call init_ctx_k_task

    call install_irq0_handler
    ;call install_irq1_handler

    sti
    
    push 0x0200             ; flags
    push k_task_seg         ; segment
    push 0x0000             ; offset
    jmp k_task_seg:0x0000  ; 
    

.hang:
    hlt
    jmp .hang

._s_msg db 'executed!' , 0x00


;********************************
; 環境設定
;********************************
init_env:
    call set_own_seg
    
    mov ax, 0x0000
    mov [call_counter], ax
    
    mov ax, tick_addr
    mov [tick_ptr], ax

    ret


;********************************
; タスク情報初期化
;********************************
init_ctx_k_task:
    mov si, ctx_k_task
    mov ax, 0x0000
    mov [si + context_ip], ax
    mov ax, k_task_seg
    mov [si + context_cs], ax
    mov ax, 0x0200     ; 適当な flags（IF=1にしてもよい）
    mov [si + context_flags], ax    
    mov ax, 0x0001     ; 
    mov [si + context_id], ax    
    
    ; ctx_child1 初期化
    mov ax, ss
    mov [si + context_ss], ax
    mov ax, ctx_k_task_sp
    mov [si + context_sp], ax

    mov ax, ds
    mov [si + context_ds], ax
    mov ax, es
    mov [si + context_es], ax
    mov ax, 0
    mov [si + context_fs], ax
    mov [si + context_gs], ax

    ret

;********************************
; タスク情報読み込み関連
;********************************
load_k_task:
    mov ax, k_task_seg
    mov es, ax
    mov bx, 0x0000
    mov ch, 0x00
    mov cl, k_task_sector
    call read_sectors
    ret

read_sectors:
    push dx
    push ax
    mov dl, 0x80
    mov ah, 0x02
    mov al, 4            ; 固定で4セクタ読み込み
    int 0x13
    pop ax
    pop dx
    ret

;********************************
; 割り込み関連初期化
;********************************
init_pit:
    mov al, 0x36          ; mode 3, square wave
    out 0x43, al
    mov al, 0x9B          ; low byte (approx. 100Hz)
    ;mov al, 0xff
    out 0x40, al
    mov al, 0x2E          ; high byte
    ;mov al, 0xff
    out 0x40, al
    ret

init_pic:
    ; マスタ PIC 初期化
    mov al, 0x11       ; ICW1: エッジトリガ・ICW4有効
    out 0x20, al
    mov al, 0x20       ; ICW2: 割り込みベクタ 0x20 (IRQ0〜)
    out 0x21, al
    mov al, 0x04       ; ICW3: スレーブはIRQ2に接続
    out 0x21, al
    mov al, 0x01       ; ICW4: 8086モード
    out 0x21, al

    ; スレーブ PIC 初期化
    mov al, 0x11
    out 0xA0, al
    mov al, 0x28       ; ICW2: IRQ8〜が0x28〜になる
    out 0xA1, al
    mov al, 0x02       ; ICW3: スレーブIDは2番（IRQ2）
    out 0xA1, al
    mov al, 0x01       ; ICW4: 8086モード
    out 0xA1, al

    ; IRQ0 (PIT) + IRQ1 (Keyboard) を許可
    mov al, 0xFC       ; 1111 1100 → IRQ0/1だけ許可
    out 0x21, al
    mov al, 0xFF       ; 全部マスク（スレーブは全部禁止）
    out 0xA1, al
    
    ; 無効化
    ;in  al, 0x21
    ;or  al, 0x01
    ;out 0x21, al

    ; 有効化
    ;in  al, 0x21
    ;and al, 0xFE
    ;out 0x21, al

    ret

;********************************
; irq0関連設定
;********************************

install_irq0_handler:
    ; IRQ0 (INT 0x20) → offset 0x0000:0800 に配置されると仮定
    mov ax, 0x0000
    mov ds, ax
    mov word [irq0_vector * 4], irq0_handler     ; offset
    mov word [irq0_vector * 4 + 2], parent_seg   ; segment
    ret

irq0_handler:
    cli
    mov ax, cs
    mov ds, ax

    call get_cursor_pos
    mov bx, ax
    
    mov ah, 20
    mov al, 60
    call set_cursor_pos
    
    mov ax, ._s_msg
    call disp_str
    
    ; カウンタ情報の更新
    inc word [current_counter]
    call get_tick
    inc ax
    cmp ax, 65500
    jb .skip_clear
    mov ax, 0
.skip_clear:
    call set_tick

    call disp_hex
    
    mov ax, bx
    call set_cursor_pos

    mov al, 0x20
    out 0x20, al  ; EOI送信

    iret

._s_msg db 'h0:', 0x00

;********************************
; irq1関連設定
;********************************

install_irq1_handler:
    mov ax, 0x0000
    mov ds, ax
    mov word [0x21 * 4], irq1_handler     ; offset
    mov word [0x21 * 4 + 2], parent_seg   ; segment
    ret

irq1_handler:
    cli
    mov ax, cs
    mov ds, ax
    mov es, ax
    
    mov al, '!'
    call putc
    in al, 0x60           ; スキャンコードを読む
    
    iret


irq1_handler2:
    cli

    push ax
    push ds
    push es

    ;mov al, '!'
    ;call putc
    
    call get_cursor_pos
    mov cx, ax
    

    in al, 0x60           ; スキャンコードを読む
    mov bx, ax

    ;call cls
    
    mov ah, 22
    mov al, 60
    call set_cursor_pos
    
    mov ax, ._s_msg
    call disp_str
    
    mov ax, bx
    mov ah, 0x00
    call disp_hex
    
    mov al, ':'
    call putc
    
    mov al, bl
    and al, 0x80
    cmp al, 0x00
    jne .key_up
    cmp al, 0x00
    je .key_down
    jmp .skip2

.key_up:
    mov al, 'u'
    jmp .skip2

.key_down:
    mov al, 'd'

.skip2:
    call putc
    mov al, ':'
    call putc

    mov ah, bl
    call scancode_to_ascii
    ;mov bh, [._b_key_condition]
    ;call scancode_decode
    ;mov [._b_key_condition], bh
    
    mov al, bl
    cmp al, 0
    je .skip
    cmp al, 0x20
    jb .ctrl_skip
    cmp al, 0x7e
    ja .ctrl_skip
    jmp .normal_route

.ctrl_skip
    mov al, 0x20
    
.normal_route    

    call putc
    ;call write_log

.skip:
    push ax
    mov al, ':'
    call putc
    pop ax
    call disp_hex

    mov ax, cx
    call set_cursor_pos

    mov al, 0x20
    out 0x20, al           ; EOI

    pop es
    pop ds
    pop ax
    iret

._s_msg db 'h1:', 0x00
._b_key_condition db 0

;********************************
; 共通関数類
;********************************

disp_hex:
    push ax
    push bx
    push cx

    mov bx, ax        ; BX に値をコピー
    mov cx, 4         ; 4桁分ループ

.next_digit:
    rol bx, 4         ; 左に4ビット回転（上位桁から出す）
    mov al, bl
    and al, 0x0F      ; 下位4ビットだけ使う

    cmp al, 10
    jl .digit
    add al, 'A' - 10
    jmp .print
.digit:
    add al, '0'

.print:
    mov ah, 0x0E
    int 0x10          ; BIOSで表示
    loop .next_digit

    pop cx
    pop bx
    pop ax
    ret


;********************************
; スキャンコードのデコード
;********************************

; ah = スキャンコード → al = ASCII（英数のみ）
scancode_to_ascii:
    push bx
    push ds
    
    mov al, 0

    mov bx, cs
    mov ds, bx

    ;********************************
    ; スキャンコード    数字
    ;********************************
    cmp ah, 0x02
    je .num1
    cmp ah, 0x03
    je .num2
    cmp ah, 0x04
    je .num3
    cmp ah, 0x05
    je .num4
    cmp ah, 0x06
    je .num5
    cmp ah, 0x07
    je .num6
    cmp ah, 0x08
    je .num7
    cmp ah, 0x09
    je .num8
    cmp ah, 0xa
    je .num9
    cmp ah, 0xb
    je .num0

    ;********************************
    ; スキャンコード    記号
    ;********************************
    cmp ah, 0x0c
    je .minus
    cmp ah, 0x0d
    je .tilde
    cmp ah, 0x7d
    je .lslash

    cmp ah, 0x1a
    je .at
    cmp ah, 0x1b
    je .lsb

    cmp ah, 0x27
    je .semicolon
    cmp ah, 0x28
    je .colon
    cmp ah, 0x2b
    je .rsb

    cmp ah, 0x33
    je .conmma
    cmp ah, 0x34
    je .period
    cmp ah, 0x35
    je .slash
    cmp ah, 0x36
    je .bslash

    cmp ah, 0x39
    je .blank

    ;********************************
    ; スキャンコード    コントロールコード
    ;********************************
;    cmp ah, 0x01        ; esc
;    je .esc
;    cmp ah, 0x0e        ; bs
;    je .bs
;    cmp ah, 0x53        ; del
;    je .del
;    cmp ah, 0x1c        ; cr
;    je .cr


;    cmp ah, 0x48        ; ↑
;    je .up
;    cmp ah, 0x50        ; ↓
;    je .down
;    cmp ah, 0x4b        ; ←
;    je .left
;    cmp ah, 0x4d        ; →
;    je .left

    ;********************************
    ; スキャンコード    ステータスコード
    ;********************************
    cmp ah, 0x2a        ; 左シフト
    je .lshift
    cmp ah, 0xaa        ; 左シフトUp
    je .lshiftUp
    cmp ah, 0x36        ; 右シフト
    je .rshift
    cmp ah, 0xb6        ; 右シフトUp
    je .rshiftUp




    ;********************************
    ; スキャンコード    アルファベット
    ;********************************
    cmp ah, 0x10
    je .q
    cmp ah, 0x11
    je .w
    cmp ah, 0x12
    je .e
    cmp ah, 0x13
    je .r
    cmp ah, 0x14
    je .t
    cmp ah, 0x15
    je .y
    cmp ah, 0x16
    je .u
    cmp ah, 0x17
    je .i
    cmp ah, 0x18
    je .o
    cmp ah, 0x19
    je .p

    cmp ah, 0x1e
    je .a
    cmp ah, 0x1f
    je .s
    cmp ah, 0x20
    je .d
    cmp ah, 0x21
    je .f
    cmp ah, 0x22
    je .g
    cmp ah, 0x23
    je .h
    cmp ah, 0x24
    je .j
    cmp ah, 0x25
    je .k
    cmp ah, 0x26
    je .l

    cmp ah, 0x2c
    je .z
    cmp ah, 0x2d
    je .x
    cmp ah, 0x2e
    je .c
    cmp ah, 0x2f
    je .v
    cmp ah, 0x30
    je .b
    cmp ah, 0x31
    je .n
    cmp ah, 0x32
    je .m

    jmp .done

    ;********************************
    ; デコード  数字
    ;********************************
.num1: mov al, '1'
       jmp .done
.num2: mov al, '2'
       jmp .done
.num3: mov al, '3'
       jmp .done
.num4: mov al, '4'
       jmp .done
.num5: mov al, '5'
       jmp .done
.num6: mov al, '6'
       jmp .done
.num7: mov al, '7'
       jmp .done
.num8: mov al, '8'
       jmp .done
.num9: mov al, '9'
       jmp .done
.num0: mov al, '0'
       jmp .done

    ;********************************
    ; デコード  記号
    ;********************************
.minus:    mov al, '-'
        jmp .done
.tilde:    mov al, '^'
        jmp .done
.lslash:    mov al, '\\'
        jmp .done


.at:    mov al, '@'
        jmp .done
.lsb:   mov al, '['
        jmp .done

.semicolon:   mov al, ';'
        jmp .done
.colon: mov al, ':'
        jmp .done
.rsb:   mov al, ']'
        jmp .done

.conmma:   mov al, ','
        jmp .done
.period:   mov al, '.'
        jmp .done
.slash:   mov al, '/'
        jmp .done
.bslash:   mov al, '\\'
        jmp .done

.blank:   mov al, ' '
        jmp .done

    ;********************************
    ; デコード  コントロールコード
    ;********************************
;.esc:   mov al, 0x1b
;        jmp .done
;.bs:   mov al, 0x08
;        jmp .done
;.del:   mov al, 0x7f
;        jmp .done
;.cr:   mov al, 0x0d
        jmp .done

;.up:   mov al, 0x00
;        jmp .done
;.down:   mov al, 0x00
;        jmp .done
;.left:   mov al, 0x00
;        jmp .done
;.right:   mov al, 0x00
        jmp .done

    ;********************************
    ; デコード  ステータスコード
    ;********************************
.lshift:   or ah, 0x80
        jmp .done
.lshiftUp:   and ah, 0x7f
        jmp .done
.rshift:   or ah, 0x40
        jmp .done
.rshiftUp:   and ah, 0xbf
        jmp .done



    ;********************************
    ; デコード  アルファベット
    ;********************************
.q:    mov al, 'q'
       jmp .done
.w:    mov al, 'w'
       jmp .done
.e:    mov al, 'e'
       jmp .done
.r:    mov al, 'r'
       jmp .done
.t:    mov al, 't'
       jmp .done
.y:    mov al, 'y'
       jmp .done
.u:    mov al, 'u'
       jmp .done
.i:    mov al, 'i'
       jmp .done
.o:    mov al, 'o'
       jmp .done
.p:    mov al, 'p'
       jmp .done

.a:    mov al, 'a'
       jmp .done
.s:    mov al, 's'
       jmp .done
.d:    mov al, 'd'
       jmp .done
.f:    mov al, 'f'
       jmp .done
.g:    mov al, 'g'
       jmp .done
.h:    mov al, 'h'
       jmp .done
.j:    mov al, 'j'
       jmp .done
.k:    mov al, 'k'
       jmp .done
.l:    mov al, 'l'
       jmp .done

.z:    mov al, 'z'
       jmp .done
.x:    mov al, 'x'
       jmp .done
.c:    mov al, 'c'
       jmp .done
.v:    mov al, 'v'
       jmp .done
.b:    mov al, 'b'
       jmp .done
.n:    mov al, 'n'
       jmp .done
.m:    mov al, 'm'
       jmp .done

.done:
    pop ds
    pop bx
    ret

;********************************
; スキャンコードのデコード  新
;********************************

; al = スキャンコード → bl = ASCII（英数のみ）
;                     → bh ステータス
scancode_decode:
    push ds
    push es
    
    mov al, 0

    mov bx, cs
    mov ds, bx
    mov es, bx

    ;********************************
    ; スキャンコード    数字
    ;********************************
    cmp al, 0x02
    je .num1
    cmp al, 0x03
    je .num2
    cmp al, 0x04
    je .num3
    cmp al, 0x05
    je .num4
    cmp al, 0x06
    je .num5
    cmp al, 0x07
    je .num6
    cmp al, 0x08
    je .num7
    cmp al, 0x09
    je .num8
    cmp al, 0xa
    je .num9
    cmp al, 0xb
    je .num0

    jmp .done

    ;********************************
    ; デコード  数字
    ;********************************
.num1: mov bl, '1'
       jmp .done
.num2: mov bl, '2'
       jmp .done
.num3: mov bl, '3'
       jmp .done
.num4: mov bl, '4'
       jmp .done
.num5: mov bl, '5'
       jmp .done
.num6: mov bl, '6'
       jmp .done
.num7: mov bl, '7'
       jmp .done
.num8: mov bl, '8'
       jmp .done
.num9: mov bl, '9'
       jmp .done
.num0: mov bl, '0'
       jmp .done


.done:
    pop es
    pop ds
    ret



;%include "routine.asm"
