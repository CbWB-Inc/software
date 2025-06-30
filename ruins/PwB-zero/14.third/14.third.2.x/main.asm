org 0x0000
section .data
ctx_current dw 0x0000

section .text
jmp setup



parent_seg     equ 0x9000
k_task_seg     equ 0x3000
d_task_seg     equ 0x3400
p_task_seg     equ 0x3800


k_task_sector  equ 6       ; 子1はセクタ6から読み込む
d_task_sector  equ 10      ; 子2はセクタ10から読み込む
p_task_sector  equ 14      ; 子3はセクタ10から読み込む

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
context_sleep  equ 36
context_size   equ 38   ; ← 2バイト増やす

current_counter dw 0

;ctx_current dw 0x0000
ctx_next  dw 0x0000
ctx_temp    dw 0

;ctx_current equ 0x8100
ctx_k_task equ 0x8200
ctx_d_task equ 0x8300
ctx_p_task equ 0x8400

ctx_k_task_sp equ 0x7000
ctx_d_task_sp equ 0x7800
ctx_p_task_sp equ 0x8000

already_switched db 0x00

already_ex  dw 0x00

temp_ip     dw 0
temp_cs     dw 0
temp_flags  dw 0
temp_si     dw 0
temp_di     dw 0
temp_ds     dw 0
temp_es     dw 0


tick_h  dw 0x0000
tick_l  dw 0x0000

saved_sp dw 0
saved_ss dw 0
saved_sp_raw dw 0

setup:
    cli
    
    push ax
    push es
    mov ax, c_seg
    mov es, ax
    mov ax, 0x0000
    mov [es:c_off], ax
    pop es
    pop ax
    
    mov ax, cs
    mov ds, ax
    mov es, ax
    
    
    call load_k_task
    call load_d_task
    call load_p_task
    
    call init_pit
    call init_pic
    
    call init_ctx_k_task
    call init_ctx_d_task
    call init_ctx_p_task
    
    mov ax, ctx_k_task
    mov [ctx_current], ax
    
   
    call install_irq0_handler
    
    


    mov ax, 0x0000
    mov [tick_h], ax
    mov [tick_l], ax
    
    sti


    push 0x0200
    push 0x3000
    push 0x0000
    jmp k_task_seg:0x0000
    

.hang:
    hlt
    jmp .hang


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
    mov ax, 0
    mov [si + context_sleep], ax

    ret

init_ctx_d_task:
    mov si, ctx_d_task
    mov ax, 0x0000
    mov [si + context_ip], ax
    mov ax, d_task_seg
    mov [si + context_cs], ax
    mov ax, 0x0200     ; 適当な flags（IF=1にしてもよい）
    mov [si + context_flags], ax    
    mov ax, 0x0002     ; 
    mov [si + context_id], ax    
    
    ; ctx_child2 初期化
    mov ax, ss
    mov [si + context_ss], ax
    mov ax, ctx_d_task_sp
    ;mov ax, ctx_child1_sp
    mov [si + context_sp], ax

    mov ax, ds
    mov [si + context_ds], ax
    mov ax, es
    mov [si + context_es], ax
    mov ax, 0
    mov [si + context_fs], ax
    mov [si + context_gs], ax
    mov ax, 0
    mov [si + context_sleep], ax

    ret

init_ctx_p_task:
    mov si, ctx_p_task
    mov ax, 0x0000
    mov [si + context_ip], ax
    mov ax, p_task_seg
    mov [si + context_cs], ax
    mov ax, 0x0200     ; 適当な flags（IF=1にしてもよい）
    mov [si + context_flags], ax    
    mov ax, 0x0002     ; 
    mov [si + context_id], ax    
    
    ; ctx_child2 初期化
    mov ax, ss
    mov [si + context_ss], ax
    mov ax, ctx_p_task_sp
    ;mov ax, ctx_child1_sp
    mov [si + context_sp], ax

    mov ax, ds
    mov [si + context_ds], ax
    mov ax, es
    mov [si + context_es], ax
    mov ax, 0
    mov [si + context_fs], ax
    mov [si + context_gs], ax
    mov ax, 0
    mov [si + context_sleep], ax

    ret


dec_sleep_if_needed:
    push ax
    push es
    mov ax, c_seg
    mov es, ax
    mov ax, 0x0000
    mov ax, [es:c_off]
    cmp ax, 0
    je .skip
    dec ax
    mov [es:c_off], ax
    mov bx, ax



    
    




.skip:
    pop es
    pop ax


    ; デバッグ出力
    ;mov al, '['
    ;call putc
    ;mov ax, bx
    ;call disp_word_hex
    ;mov ax, es
    ;call disp_word_hex
    ;mov al, ':'
    ;call putc
    ;mov ax, [es:c_off]
    ;call disp_word_hex
    ;mov al, ']'
    ;call putc
    ; デバッグ出力



    ret


select_next_task:
    cli
    mov word bx, [ctx_current]
    cmp bx, ctx_k_task
    je .to_d_task
    cmp bx, ctx_d_task
    je .to_k_task
    cmp bx, ctx_p_task
    je .to_k_task       ; ← ★追加！p_taskからはkに戻す
    ; 不明なタスクだった場合はctx_child1に戻す
    mov cx, ctx_k_task
    jmp .update

.to_k_task:
    mov cx, ctx_k_task
    jmp .update

.to_d_task:
    mov cx, ctx_d_task

.update:
    mov [ctx_next], cx
    ;mov si, bx              ; si ← context構造体のアドレス（load_task_context用）


    ret



load_k_task:
    mov ax, k_task_seg
    mov es, ax
    mov bx, 0x0000
    mov ch, 0x00
    mov cl, k_task_sector
    call read_sectors
    ret

load_d_task:
    mov ax, d_task_seg
    mov es, ax
    mov bx, 0x0000
    mov ch, 0x00
    mov cl, d_task_sector
    call read_sectors
    ret

load_p_task:
    mov ax, p_task_seg
    mov es, ax
    mov bx, 0x0000
    mov ch, 0x00
    mov cl, p_task_sector
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

init_pit:
    mov al, 0x36          ; mode 3, square wave
    out 0x43, al
    mov al, 0x9B          ; low byte (approx. 100Hz)
    out 0x40, al
    mov al, 0x2E          ; high byte
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

    ; IRQ0を有効化（他はマスク）
    mov al, 0xFE       ; 1111 1110: IRQ0のみ許可
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

install_irq0_handler:
    ; IRQ0 (INT 0x20) → offset 0x0000:0800 に配置されると仮定
    mov ax, 0x0000
    mov ds, ax
    mov word [irq0_vector * 4], irq0_handler     ; offset
    mov word [irq0_vector * 4 + 2], parent_seg   ; segment
    ret

irq0_handler:
    mov dx, sp
    mov [saved_sp_raw], dx   ; 割り込み時点の SP
    mov [saved_sp], dx
    
    mov ax, ss
    mov [saved_ss], ax
    ;mov dx, sp          ; dx = SP直後（IPが積まれている）

    mov bx, sp
    mov ax, [ss:bx + 0]   ; FLAGS
    mov [temp_flags], ax
    mov ax, [ss:bx + 2]   ; CS
    mov [temp_cs], ax
    mov ax, [ss:bx + 4]       ; IP
    mov [temp_ip], ax

    mov al, '['
    call putc
    mov ax, [temp_cs]
    call disp_word_hex
    mov al, ';'
    call putc
    mov ax, [temp_ip]
    call disp_word_hex
    mov al, ':'
    call putc
    mov ax, [temp_flags]
    call disp_word_hex
    mov al, ']'
    call putc


    pop ax
    mov [temp_flags], ax
    pop ax
    mov [temp_cs], ax
    pop ax
    mov [temp_ip], ax

    mov ax, [temp_flags]
    or ax, 0x200
    mov [temp_flags], ax
    
    mov ax, 0x0000
    mov word [temp_ip], ax
    mov ax, 0x0200
    mov word [temp_flags], ax
    

    mov al, '('
    call putc
    mov ax, [temp_cs]
    call disp_word_hex
    mov al, ';'
    call putc
    mov ax, [temp_ip]
    call disp_word_hex
    mov al, ':'
    call putc
    mov ax, [temp_flags]
    call disp_word_hex
    mov al, ')'
    call putc
    
    push word [temp_ip]
    push word [temp_cs]
    push word [temp_flags]


    iret



    push ax
    push bx
    push cx
    push dx

    push si
    push di
    push bp

    push ds
    push es
    push fs
    push gs
    ;mov ax, ss
    ;mov dx, sp
    ;mov bx, 0x0000
    ;mov ds, bx

    cli

    mov al, '!'
    call putc


.normal_set:
    mov si, [ctx_current]
    
    mov bx, [saved_sp_raw]   ; ← SP（オフセット）
    ;mov ax, [saved_ss]   ; ← SS（セグメント）
    ;mov es, ax

    ; SS
    mov ax, ss
    mov [si + context_ss], ax

    ; SP（レジスタpushぶん戻して保存）
    mov ax, [saved_sp_raw]
    add ax, 12 * 2             ; push 12個 × 2バイト
    mov [si + context_sp], ax

    mov dx, [ss:bx + 0]   ; FLAGS
    mov [si + context_flags], dx
    mov dx, [ss:bx + 2]   ; CS
    mov [si + context_cs], dx
    mov dx, [ss:bx + 4]       ; IP
    mov [si + context_ip], dx
    
    
    mov ax, [ss:bx + 2]        ; CS
    mov [si + context_cs], ax
    mov ax, [ss:bx + 4]        ; IP
    mov [si + context_ip], ax
    

   ; 汎用レジスタ
    mov ax, [ss:bx + 4 + 2*1]  ; AX（IPの上に積んだAXから）
    mov [si + context_ax], ax
    mov ax, [ss:bx + 4 + 2*2]  ; BX
    mov [si + context_bx], ax
    mov ax, [ss:bx + 4 + 2*3]  ; CX
    mov [si + context_cx], ax
    mov ax, [ss:bx + 4 + 2*4]  ; DX
    mov [si + context_dx], ax
    mov ax, [ss:bx + 4 + 2*5]
    mov [si + context_si], ax
    mov ax, [ss:bx + 4 + 2*6]
    mov [si + context_di], ax
    mov ax, [ss:bx + 4 + 2*7]
    mov [si + context_bp], ax
    mov ax, [ss:bx + 4 + 2*8]
    mov [si + context_ds], ax
    mov ax, [ss:bx + 4 + 2*9]
    mov [si + context_es], ax
    mov ax, [ss:bx + 4 + 2*10]
    mov [si + context_fs], ax
    mov ax, [ss:bx + 4 + 2*11]
    mov [si + context_gs], ax





    ;mov si, [ctx_current]
    
    ;mov ax, [saved_ss]
    ;mov es, ax
    ;mov bx, [saved_sp]
    ;mov ax, [es:bx + 0] 
    ;call disp_word_hex       ; IP
    ;mov [si + context_ip], ax
    ;mov ax, [es:bx + 2]        ; CS
    ;call disp_word_hex       ; IP
    ;mov [si + context_cs], ax
    ;mov ax, [es:bx + 4]        ; FLAGS
    ;mov [si + context_flags], ax
.skip_ip:


    mov al, '['
    call putc
    mov ax, [saved_ss]
    mov es, ax
    call disp_word_hex
    mov al, ':'
    call putc
    mov ax, [si + context_cs]
    call disp_word_hex
    mov al, ':'
    call putc
    mov ax, [si + context_ip]
    call disp_word_hex
    mov al, ':'
    call putc
    mov ax, [si + context_flags]
    call disp_word_hex
    mov al, ']'
    call putc


    ; --- スリープカウントをデクリメント ---
    ;mov si, ctx_k_task
    ;call dec_sleep_if_needed
    ;mov si, ctx_d_task
    ;call dec_sleep_if_needed
    ;mov si, ctx_p_task
    ;call dec_sleep_if_needed
    
    
    call select_next_task

    ;mov si, [ctx_current]

    
        ; コンテキスト保存
    ;mov ax, ss
    ;mov [si + context_ss], ax   ; SSを保存
    ;mov [si + context_sp], dx   ; SPを保存


.save_common:
    ; ctx_next → ctx_current
    mov si, [ctx_next]
    mov [ctx_current], si
    mov di, si   ; diにctx_nextを避難し、以降di固定で使う


    ; contextからレジスタ復元（注意：逆順popに合わせて順に並べてる）
    mov ax, [di + context_gs]
    mov gs, ax
    mov ax, [di + context_fs]
    mov fs, ax
    mov ax, [di + context_es]
    mov es, ax
    mov ax, [di + context_ds]
    mov ds, ax
    mov ax, [di + context_bp]
    mov bp, ax
    mov ax, [di + context_di]
    mov di, ax
    mov ax, [di + context_si]
    mov si, ax
    mov ax, [di + context_dx]
    mov dx, ax
    mov ax, [di + context_cx]
    mov cx, ax
    mov ax, [di + context_bx]
    mov bx, ax
    mov ax, [di + context_ax]
    mov ax, ax  ; redundant but safe

    ; SS, SP
    mov ax, [di + context_ss]
    mov ss, ax
    mov ax, [di + context_sp]
    mov sp, ax


    ;mov [si + context_gs], ax
    ;pop ax
    ;mov [si + context_fs], ax
    ;pop ax
    ;mov [si + context_es], ax
    ;pop ax
    ;mov [si + context_ds], ax
    ;pop ax
    ;mov [si + context_bp], ax
    ;pop ax
    ;mov [si + context_di], ax
    ;pop ax
    ;mov [si + context_si], ax
    ;pop ax
    ;mov [si + context_dx], ax
    ;pop ax
    ;mov [si + context_cx], ax
    ;pop ax
    ;mov [si + context_bx], ax
    ;pop ax
    ;mov [si + context_ax], ax

    cmp byte [already_ex], 0x00
    jne normal_ex

    mov byte [already_ex], 0x01
    
    mov al, '!'
    call putc

normal_ex:

.restore_common:

    mov si, [ctx_next]
    ;mov [ctx_current], si


    ; デバッグ表示
    ;mov si, ctx_d_task
    ;;mov ds, ax
    ;mov ax, [si + context_cs]
    ;call disp_word_hex
    ;mov ax, [si + context_ip]
    ;call disp_word_hex
    ;mov ax, [si + context_flags]
    ;call disp_word_hex

    ;mov ax, [ctx_next]
    ;call disp_word_hex

    ;mov ax, si
    ;call disp_word_hex

    mov ax, 0x9000
    mov ds, ax


    mov di, si

    mov ax, [di + context_ip]
    mov [temp_ip], ax
    call disp_word_hex

    mov ax, [di + context_cs]
    mov [temp_cs], ax
    call disp_word_hex

    mov ax, [di + context_flags]
    or ax, 0x200
    mov [temp_flags], ax
    call disp_word_hex



    mov al, '('
    call putc
    mov ax, [temp_si]
    call disp_word_hex
    mov al, ':'
    call putc
    mov ax, [temp_cs]
    call disp_word_hex
    mov al, ':'
    call putc
    mov ax, [temp_ip]
    call disp_word_hex
    mov al, ':'
    call putc
    mov ax, [temp_flags]
    call disp_word_hex
    mov al, ')'
    call putc



    mov ax, [di + context_ss]
    mov ss, ax
    mov ax, [di + context_sp]
    mov sp, ax
    mov ax, di

    mov ax, [di + context_ax]
    mov bx, [di + context_bx]
    mov cx, [di + context_cx]
    mov dx, [di + context_dx]
    mov bp, [di + context_bp]
    mov ax, [di + context_fs]
    mov fs, ax
    mov ax, [di + context_gs]
    mov gs, ax
    ;mov si, [di + context_si]
    ;mov di, [di + context_di]
    mov ax, [di + context_ds]
    ;mov ds, ax
    mov ax, [di + context_es]
    ;mov es, ax

    mov [temp_si], si
    mov [temp_di], di
    mov ax, [di + context_ds]
    mov [temp_ds], ax
    mov ax, [di + context_es]
    mov [temp_ds], ax



    inc word [current_counter]

    mov al, 0x20
    out 0x20, al  ; EOI送信


._skip_stop:

    inc word [tick_h]


    ;times 14 pop ax


    mov ax, [current_counter]
    ;call disp_word_hex
    cmp ax, 0x5
    jl .skip_check
;    cli
;    hlt


.skip_check:


    ;mov al, '$'
    ;call putc

    ;mov ax, 0x9000
    ;mov ds, ax
    
    mov ax, [ctx_next]
    call disp_word_hex

    mov al, '<'
    call putc
    mov ax, [temp_si]
    call disp_word_hex
    mov al, ':'
    call putc
    mov ax, [temp_cs]
    call disp_word_hex
    mov al, ':'
    call putc
    mov ax, [temp_ip]
    call disp_word_hex
    mov al, ':'
    call putc
    mov ax, [temp_flags]
    call disp_word_hex
    mov al, '>'
    call putc

    ;mov ax, [saved_ss]
    ;mov ss, ax
    ;mov sp, [saved_sp]
    
    push word [di + context_flags]
    push word [di + context_cs]
    push word [di + context_ip]
    ;push word [temp_flags]
    ;push word [temp_cs]
    ;push word [temp_ip]
    
    mov si, [temp_si]
    mov di, [temp_di]
    mov ax, [temp_es]
    mov es, ax
    mov ax, [temp_ds]
    mov ds, ax
    
    ;call get_key
    
    iret

.skip:
    pop es
    pop ax
.loop:
    sti
    hlt
    jmp .loop



%include "routine.asm"

times 4096-($-$$) -2 db 0
dw 0x5E5E
