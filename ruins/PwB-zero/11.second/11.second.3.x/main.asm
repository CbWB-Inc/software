
jmp setup

parent_seg     equ 0x9000
child1_seg     equ 0x3000
child2_seg     equ 0x3400
child_sector1  equ 6       ; 子1はセクタ6から読み込む
child_sector2  equ 10      ; 子2はセクタ10から読み込む

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
context_size   equ 32

current_counter dw 0

ctx_child1 equ 0x8000
ctx_child2 equ 0x8040

ctx_child1_sp equ 0x7C00
ctx_child2_sp equ 0x7400

already_switched db 0x00

already_ex dw 0x00

temp_ip dw 0
temp_cs dw 0

call_counter dw 0x0000


setup:
    cli
    
    call load_child1
    call load_child2
    call init_pit
    call init_pic
    
    
    mov ax, 0x0000
    mov [ctx_child1 + context_ip], ax
    mov ax, child1_seg
    mov [ctx_child1 + context_cs], ax
    mov ax, 0x0200     ; 適当な flags（IF=1にしてもよい）
    mov [ctx_child1 + context_flags], ax    
    
    ; ctx_child1 初期化（child2と同様）
    mov ax, ss
    mov [ctx_child1 + context_ss], ax
    mov ax, ctx_child1_sp
    mov [ctx_child1 + context_sp], ax

    mov ax, ds
    mov [ctx_child1 + context_ds], ax
    mov ax, es
    mov [ctx_child1 + context_es], ax
    mov ax, 0
    mov [ctx_child1 + context_fs], ax
    mov [ctx_child1 + context_gs], ax


    mov ax, 0x0000
    mov [ctx_child2 + context_ip], ax
    mov ax, child2_seg
    mov [ctx_child2 + context_cs], ax
    mov ax, 0x0200
    mov [ctx_child2 + context_flags], ax

    mov ax, ss
    mov [ctx_child2 + context_ss], ax
    mov ax, ctx_child2_sp
    mov [ctx_child2 + context_sp], ax

    mov ax, ds
    mov [ctx_child2 + context_ds], ax
    mov ax, es
    mov [ctx_child2 + context_es], ax
    mov ax, 0
    mov [ctx_child2 + context_fs], ax
    mov [ctx_child2 + context_gs], ax




    call install_irq0_handler
    
    
    mov ax, 0x0000
    mov [call_counter], ax
    
    sti

    ;jmp irq0_handler
    jmp child1_seg:0x0000
    

.hang:
    hlt
    jmp .hang

load_child1:
    mov ax, child1_seg
    mov es, ax
    mov bx, 0x0000
    mov ch, 0x00
    mov cl, child_sector1
    call read_sectors
    ret

load_child2:
    mov ax, child2_seg
    mov es, ax
    mov bx, 0x0000
    mov ch, 0x00
    mov cl, child_sector2
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
    cli
    mov dx, sp
    ;pusha               ; 汎用レジスタを保存
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
    mov ax, ss
    mov dx, sp
    mov bx, 0x0000
    mov ds, bx


    ;cmp byte [already_ex], 0x00
    ;jne .normal_set
    mov ax, child1_seg
    mov [ctx_child1 + context_cs], ax
    mov ax, child2_seg
    mov [ctx_child2 + context_cs], ax

.normal_set:


    mov ax, [current_counter]
    add al, 0x30
    mov ah, 0x0e
    int 0x10
    
   ; 保存先を交互にトグル
    mov ax, [current_counter]
    and ax, 1
    cmp ax, 0
    je .set_child1
    jmp .set_child2
    
.set_child1:
    mov si, ctx_child1
    jmp .do_save
.set_child2:
    mov si, ctx_child2
    
.do_save:    
    ; コンテキスト保存
    mov ax, ss
    mov [si + context_ss], ax   ; SSを保存
    mov [si + context_sp], dx   ; SPを保存

    mov al, '*'
    call putc

;    ; 保存先を交互にトグル
;    mov ax, [current_counter]
;    and ax, 1
;    cmp ax, 0
;    je .save_child1
;    jmp .save_child2
;.save_child1:
;    mov si, ctx_child1
;    jmp .save_common
;.save_child2:
;    mov si, ctx_child2

.save_common:
    pop ax
    mov [si + context_gs], ax
    pop ax
    mov [si + context_fs], ax
    pop ax
    mov [si + context_es], ax
    pop ax
    mov [si + context_ds], ax
    pop ax
    mov [si + context_bp], ax
    pop ax
    mov [si + context_di], ax
    pop ax
    mov [si + context_si], ax
    pop ax
    mov [si + context_dx], ax
    pop ax
    mov [si + context_cx], ax
    pop ax
    mov [si + context_bx], ax
    pop ax
    mov [si + context_ax], ax

    ; スタックから子プロセス（正確には割り込み元）のip, cs, flagsを取得
    ; 割り込み元の flags, cs, ip を sp から peek
    mov bp, dx
    mov ax, [bp]
    or ax, 0x0200
    mov [si + context_flags], ax
    mov ax, [bp + 4]
    mov [si + context_cs], ax
    mov ax, [bp + 2]
    mov [si + context_ip], ax
    
    cmp byte [already_ex], 0x00
    jne normal_ex

    mov byte [already_ex], 0x01
    ;mov word [current_counter], 1

normal_ex:

   ; current_counter トグル
    mov ax, [current_counter]
    xor ax, 1
    mov [current_counter], ax
;    cmp ax, 0

    ; 実行先判断
    cmp ax, 0
    je .run_child2
    jmp .run_child1
.run_child2:
    mov si, ctx_child2
    jmp .restore_common
.run_child1:
    mov si, ctx_child1

.restore_common:
    ;cli
    ;mov ax, [si + context_ss]
    ;mov ss, ax
    ;mov sp, [si + context_sp]
    ;sti

    ;mov ax, [si + context_ax]
    ;push ax
    ;mov bx, [si + context_bx]
    ;mov cx, [si + context_cx]
    ;mov dx, [si + context_dx]
    ;mov si, [si + context_si]
    ;mov di, [si + context_di]
    ;mov bp, [si + context_bp]
    ;mov ax, [si + context_ds]
    ;mov ds, ax
    ;mov ax, [si + context_es]
    ;mov es, ax
    ;mov ax, [si + context_fs]
    ;mov fs, ax
    ;mov ax, [si + context_gs]
    ;mov gs, ax



    ; コンテキスト復元
    cli
    mov ax, [si + context_ss]
    mov ss, ax
    mov sp, [si + context_sp]
    sti
    
    mov ax, [si + context_ax]
    push ax
    mov ax, [si + context_bx]
    push ax
    mov ax, [si + context_cx]
    push ax
    mov ax, [si + context_dx]
    push ax
    mov ax, [si + context_si]
    push ax
    mov ax, [si + context_di]
    push ax
    mov ax, [si + context_bp]
    push ax
    mov ax, [si + context_ds]
    push ax
    mov ds, ax
    mov ax, [si + context_es]
    push ax
    mov es, ax
    mov ax, [si + context_fs]
    push ax
    mov fs, ax
    mov ax, [si + context_gs]
    push ax
    mov gs, ax

    ;inc word [current_counter]



    mov al, 0x20
    out 0x20, al  ; EOI送信


    mov ax, [si + context_flags]
    call disp_word_hex
    ;call disp_nl
    mov ax, [si + context_cs]
    call disp_word_hex
    ;call disp_nl
    mov ax, [si + context_ip]
    call disp_word_hex
    ;call disp_nl
    mov ax, [si + context_sp]
    call disp_word_hex

    mov word ax, [call_counter]
    call disp_word_hex
    
    ;mov ax, [ctx_child1 + context_sp]
    ;call disp_word_hex
    ;mov ax, [ctx_child2 + context_sp]
    ;call disp_word_hex

    ;mov ax, ctx_child1
    ;call disp_word_hex
    ;mov ax, ctx_child2
    ;call disp_word_hex
    
    call disp_nl
    
    
    
    inc word [call_counter]
    mov word ax, [call_counter]
    cmp ax, 1
    jg ._skip_stop

    ;cli
    ;hlt

._skip_stop:

    push word [si + context_flags]
    push word [si + context_cs]
    push word [si + context_ip]
;jmp $
    
    iret






    


%include "routine.asm"

times 2048-($-$$) -2 db 0
dw 0x5E5E
