
jmp setup

child1_seg     equ 0x3000
child2_seg     equ 0x3400
child_sector1  equ 6       ; 子1はセクタ6から読み込む
child_sector2  equ 10      ; 子2はセクタ10から読み込む

irq0_vector    equ 0x20

current_counter dw 0

setup:
    cli
    
    call load_child1
    call load_child2
    call init_pit
    call init_pic
    call install_irq0_handler
    
    
    
    sti



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
    mov word [irq0_vector * 4 + 2], 0x9000        ; segment
    ret

irq0_handler:
    push ax
    push ds
    mov ax, 0x0000
    mov ds, ax

    inc word [current_counter]
    mov ax, [current_counter]
    and ax, 0x03
    cmp ax, 0x03
    jne .run_child2
.run_child1:
    call child1_seg:0x0000
    ;mov al, 'A'
    ;call putc
    jmp .eoi
.run_child2:
    ;mov al, 'B'
    ;call putc
    call child2_seg:0x0000

    ; (注: 通常ここにEOI送出やiretが必要だが、子側がretfで戻る想定)
.irq0_ret:

.eoi:
    ; EOI送出
    mov al, 0x20
    out 0x20, al


    pop ds
    pop ax
    iret


%include "routine.asm"

times 2048-($-$$) -2 db 0
dw 0x5E5E
