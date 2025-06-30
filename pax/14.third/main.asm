
jmp setup

section .data

parent_seg     equ 0x9000
k_task_seg     equ 0x1000
d_task_seg     equ 0x2000
p_task1_seg    equ 0x3000
p_task2_seg    equ 0x0400
p_task3_seg    equ 0x5000

k_task_sector  equ 10       ; 子1はセクタ10から読み込む
d_task_sector  equ 14      ; 子2はセクタ14から読み込む
p_task1_sector  equ 18      ; 子3はセクタ18から読み込む
p_task2_sector  equ 22      ; 子3はセクタ22から読み込む
p_task3_sector  equ 26      ; 子3はセクタ26から読み込む

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


ctx_k_task equ 0x8400
ctx_d_task equ 0x8500

ctx_k_task_sp equ 0x7000
ctx_d_task_sp equ 0x7300
ctx_p_task1_sp equ 0x7600
ctx_p_task2_sp equ 0x7900
ctx_p_task3_sp equ 0x7b00

already_switched db 0x0000

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



section .text

setup:
    cli
    call init_env
    call init_c_off
    


    call load_k_task
    call load_d_task
    call load_p_task1
    call load_p_task2
    call load_p_task3
    
    call init_pit
    call init_pic
    
    call init_ctx_k_task
    call init_ctx_d_task
    call init_ctx_p_task1
    call init_ctx_p_task2
    call init_ctx_p_task3

    call install_irq0_handler
    
    
    sti
    
    ;mov ax, c_data_seg
    ;mov ds, ax
    ;call get_c_msg_off
    ;call disp_str
    

    ;jmp irq0_handler
    
    push 0x0200
    push 0x3000
    push 0x0000
    jmp k_task_seg:0x0000
    

.hang:
    hlt
    jmp .hang

init_env:
    
    ; ビデオモードの設定
    mov ah, 0x0
    mov al, 0x3    ; 16色テキスト、80x25
    int 0x10
    
    mov ax, parent_seg
    mov ds, ax
    
    mov ax, ctx_k_task
    mov [ctx_current], ax
    
    mov ax, ctx_d_task
    mov [ctx_next], ax
   
    mov ax, 0x0000
    mov [call_counter], ax
    

    mov ax, tick_addr
    mov [tick_ptr], ax

    ret



init_c_off:
    
    
    mov ax, parent_seg
    mov ds, ax
    
    mov ax, c_data_seg
    mov es, ax
    mov bx, c_data_off
    mov ax, _s_success
    mov word [es:bx], ax
    add bx, 2
    mov ax, _s_common_buf
    mov word [es:bx], ax
    
    ;mov ax, [es:bx]
    ;call disp_word_hex
    
    ;mov ax, _s_success
    ;call disp_word_hex




    mov ax, 0x0000
    mov [call_counter], ax
    

    mov ax, tick_addr
    mov [tick_ptr], ax

    ret



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
    mov [si + context_sp], ax

    mov ax, ds
    mov [si + context_ds], ax
    mov ax, es
    mov [si + context_es], ax
    mov ax, 0
    mov [si + context_fs], ax
    mov [si + context_gs], ax

    ret

init_ctx_p_task1:
    mov si, ctx_p_task1
    mov ax, 0x0000
    mov [si + context_ip], ax
    mov ax, p_task1_seg
    mov [si + context_cs], ax
    mov ax, 0x0200     ; 適当な flags（IF=1にしてもよい）
    mov [si + context_flags], ax    
    mov ax, 0x0003     ; 
    mov [si + context_id], ax    
    
    ; ctx_child2 初期化
    mov ax, ss
    mov [si + context_ss], ax
    mov ax, ctx_p_task1_sp
    mov [si + context_sp], ax

    mov ax, ds
    mov [si + context_ds], ax
    mov ax, es
    mov [si + context_es], ax
    mov ax, 0
    mov [si + context_fs], ax
    mov [si + context_gs], ax

    ret

init_ctx_p_task2:
    mov si, ctx_p_task2
    mov ax, 0x0000
    mov [si + context_ip], ax
    mov ax, p_task2_seg
    mov [si + context_cs], ax
    mov ax, 0x0200     ; 適当な flags（IF=1にしてもよい）
    mov [si + context_flags], ax    
    mov ax, 0x0003     ; 
    mov [si + context_id], ax    
    
    ; ctx_child2 初期化
    mov ax, ss
    mov [si + context_ss], ax
    mov ax, ctx_p_task2_sp
    mov [si + context_sp], ax

    mov ax, ds
    mov [si + context_ds], ax
    mov ax, es
    mov [si + context_es], ax
    mov ax, 0
    mov [si + context_fs], ax
    mov [si + context_gs], ax

    ret
init_ctx_p_task3:
    mov si, ctx_p_task3
    mov ax, 0x0000
    mov [si + context_ip], ax
    mov ax, p_task3_seg
    mov [si + context_cs], ax
    mov ax, 0x0200     ; 適当な flags（IF=1にしてもよい）
    mov [si + context_flags], ax    
    mov ax, 0x0003     ; 
    mov [si + context_id], ax    
    
    ; ctx_child2 初期化
    mov ax, ss
    mov [si + context_ss], ax
    mov ax, ctx_p_task3_sp
    mov [si + context_sp], ax

    mov ax, ds
    mov [si + context_ds], ax
    mov ax, es
    mov [si + context_es], ax
    mov ax, 0
    mov [si + context_fs], ax
    mov [si + context_gs], ax

    ret

; k p1 p2 p3 k p1のパターン
;select_next_task:
;    cli
;    mov bx, [ctx_current]
;    cmp bx, ctx_k_task
;    je .to_p_task

;    ; p_taskから戻ってきた場合
;    mov cx, ctx_k_task
;    jmp .update

;.to_p_task:
;    call decide_next_p_task
;    mov cx, [ctx_next]   ; decide_next_p_taskで設定された値を使う

;.update:
;    mov [ctx_next], cx
;    ret



; k d p1 p2 p3 k Ð p1のパターン
select_next_task:
    cli
    mov bx, [ctx_current]
    cmp bx, ctx_k_task
    je .to_d_task        ; k_taskの次はd_taskへ
    cmp bx, ctx_d_task
    je .to_p_task        ; d_taskの次にp_taskへ
    ; p_taskだったらk_taskに戻す
    mov cx, ctx_k_task
    jmp .update

.to_p_task:
    call decide_next_p_task
    mov cx, [ctx_next]
    jmp .update

.to_d_task:
    mov cx, ctx_d_task
.update:
    mov [ctx_next], cx
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

load_p_task1:
    mov ax, p_task1_seg
    mov es, ax
    mov bx, 0x0000
    mov ch, 0x00
    mov cl, p_task1_sector
    call read_sectors
    ret

load_p_task2:
    mov ax, p_task2_seg
    mov es, ax
    mov bx, 0x0000
    mov ch, 0x00
    mov cl, p_task2_sector
    call read_sectors
    ret

load_p_task3:
    mov ax, p_task3_seg
    mov es, ax
    mov bx, 0x0000
    mov ch, 0x00
    mov cl, p_task3_sector
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
    push ax
    push ds
    mov ax, parent_seg
    mov ds, ax
    pop ax

    ; コンテキスト情報の確保（ss、spは特別）
    mov ax, sp
    mov [temp_sp], ax
    mov ax, ss
    mov [temp_ss], ax
    
    ; プロセス情報の退避（ip、cs、flags）
    mov bx, sp
    mov ax, [ss:bx + 0]   ; FLAGS
    mov [temp_flags], ax
    mov ax, [ss:bx + 4]   ; CS
    mov [temp_cs], ax
    mov ax, [ss:bx + 2]       ; IP
    mov [temp_ip], ax

    ; コンテキスト情報の確保
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

    ; カウンタ情報の更新
    inc word [current_counter]
    call get_tick
    inc ax
    cmp ax, 65500
    jb .skip_clear
    mov ax, 0
.skip_clear:
    call set_tick
    
    ;mov al, '!'
    ;call putc
    

    ; デバッグ出力
    ;mov al, '['
    ;call putc
    ;mov ax, [ctx_current]
    ;call disp_word_hex
    ;mov al, ':'
    ;call putc
    ;mov ax, [temp_cs]
    ;call disp_word_hex
    ;mov al, ':'
    ;call putc
    ;mov ax, [temp_ip]
    ;call disp_word_hex
    ;mov al, ':'
    ;call putc
    ;mov ax, [temp_flags]
    ;call disp_word_hex
    ;mov al, ']'
    ;call putc
    ; デバッグ出力

    ; デバッグ出力
    ;mov al, '/'
    ;call putc
    ;;mov ax, [current_counter]
    ;call get_tick
    ;call disp_word_hex
    ;mov al, '/'
    ;call putc
    ;mov ax, sp
    ;call disp_word_hex
    ;mov al, '/'
    ;call putc
    
    ; デバッグ出力

    ; コンテキスト情報のセーブ
    mov si, [ctx_current]
    mov ax, [temp_ip]
    mov [si + context_ip], ax
    mov ax, [temp_cs]
    mov [si + context_cs], ax
    mov ax, [temp_flags]
    mov [si + context_flags], ax
    mov ax, sp
    mov [si + context_sp], ax

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

    mov ax, [temp_sp]
    mov [si + context_sp], ax
    mov ax, [temp_ss]
    mov [si + context_ss], ax


    ; 次に実行するタスク決定する
    call select_next_task

    ; タスク情報のスイッチ
    mov ax, [ctx_current]
    mov bx, [ctx_next]
    mov [ctx_current], bx
    mov [ctx_next], ax


    ; 次実行タスクのコンテキスト情報の復元
    mov si, [ctx_current]
    mov ax, [si + context_ip]
    mov [temp_ip], ax
    mov ax, [si + context_cs]
    mov [temp_cs], ax
    mov ax, [si + context_flags]
    mov [temp_flags], ax
    mov ax, [si + context_sp]
    mov [temp_sp], ax
    mov sp, ax

    mov ax, [si + context_ax]
    mov [temp_ax], ax
    mov ax, [si + context_bx]
    mov [temp_bx], ax
    mov ax, [si + context_cx]
    mov cx, ax
    mov ax, [si + context_dx]
    mov dx, ax

    mov ax, [si + context_di]
    mov di, ax
    mov ax, [si + context_bp]
    mov bp, ax

    mov ax, [si + context_fs]
    mov fs, ax
    mov ax, [si + context_gs]
    mov gs, ax
    mov ax, [si + context_es]
    mov es, ax

    mov ax, [temp_ss]
    mov ss, ax
    mov ax, [temp_sp]
    mov sp, ax

    mov ax, [si + context_ds]
    mov ds, ax

    ; デバッグ出力
    ;mov al, '('
    ;call putc
    ;mov ax, [ctx_current]
    ;call disp_word_hex
    ;mov al, ':'
    ;call putc
    ;mov ax, [temp_cs]
    ;call disp_word_hex
    ;mov al, ':'
    ;call putc
    ;mov ax, [temp_ip]
    ;call disp_word_hex
    ;mov al, ':'
    ;call putc
    ;mov ax, [temp_flags]
    ;call disp_word_hex
    ;mov al, ')'
    ;call putc
    ; デバッグ出力

    ;call disp_nl

    mov al, 0x20
    out 0x20, al  ; EOI送信

    ; スタックの書き換え
    mov bx, sp
    mov ax, [temp_flags]
    mov [ss:bx + 0], ax
    mov ax, [temp_cs]
    mov [ss:bx + 4], ax
    mov ax, [temp_ip]
    mov [ss:bx + 2], ax

    ; さし障りのあった情報の設定
    mov ax, [si + context_si]
    mov si, ax
    mov ax, [temp_bx]
    mov bx, ax
    mov ax, [temp_ax]

    pop ds
    
    ; 次タスクへ移譲
    iret



.entry_ptr:
.entry_seg dw 0
.entry_off dw 0


%include "routine.asm"

times 4096-($-$$) -2 db 0
dw 0x5E5E
