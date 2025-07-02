;org 0x0000
bits 16

section .text

;********************************
; 開始
;********************************


global _start

_start:


;********************************
; 各種設定、初期化など
;********************************
setup:
    mov ax, cs
    mov ds, ax
    mov es, ax
    xor ax, ax
    
    mov ax, parent_seg
    mov ss, ax
    mov sp, 0xfffe

    cli
    call init_env
    call init_shared_log
    call init_msgq
    
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
    call install_irq1_handler

    sti
    
    call set_own_seg

    mov ax, cs
    mov ds, ax
    
    push 0x0200             ; flags
    push k_task_seg         ; segment
    push 0x0000             ; offset
    ;jmp k_task_seg:0x0000  ; 
    jmp k_task_seg:0x0000  ; 
    

.hang:
    hlt
    jmp .hang

._s_msg db 'executed!' , 0x00
._s_msg2 db '##### end #####' , 0x00
._s_msg3 db '!' , 0x00


init_env:
    call set_own_seg
    
    mov ax, ctx_k_task
    mov [ctx_current], ax
    
    mov ax, ctx_d_task
    mov [ctx_next], ax
   
    mov ax, 0x0000
    mov [call_counter], ax
    
    mov ax, tick_addr
    mov [tick_ptr], ax

    mov ax, 0x0000
    call set_tick
    
    mov byte [g_key_condition] , 0x00
    mov word [g_cursor], 0x0000
    
    mov ax, 10
    call _wait
    call get_tick
    call set_seed
    
    ret


init_shared_log:
    push es
    push ds
    
    ; shared_bufの初期化
    mov ax, shared_buf_seg
    mov es, ax
    mov ds, ax
    
    
    mov ax, shared_head_ofs
    mov [es:bx], ax
    
    mov ax, shared_buf_len
    mov bx, shared_tail_ofs
    mov [es:bx], ax
    
    ; key_bufの初期化
    mov ax, key_buf_seg
    mov es, ax
    mov ds, ax
    
    mov ax, key_buf_head_ofs
    mov [es:bx], ax
    
    mov ax, key_buf_len
    mov bx, key_buf_tail_ofs
    mov [es:bx], ax

    pop ds
    pop es
    ret

init_msgq:
    push es
    push ds
    
    ; msgqの初期化
    mov ax, msgq_seg
    mov es, ax
    mov ds, ax
    
    
    ;mov bx, msgq_head_ofs
    ;mov ax, 0x0004
    mov word [es:msgq_head_ofs], 0x000c
    
    ;mov ax, msgq_len * msgq_entry_size
    ;mov ax, msgq_len
    ;mov bx, msgq_tail_ofs
    mov word [es:msgq_tail_ofs], 0x0008
    
    mov ax, 0x0000
    mov bx, msgq_data_ofs
    mov [es:bx+2], ax
    
    mov ax, 0x0000
    mov bx, msgq_data_ofs
    mov [es:bx+4], ax
    
    mov ax, 0x0000
    mov bx, msgq_data_ofs
    mov [es:bx+6], ax
    
    pop ds
    pop es
    ret


;********************************
; タスク初期化
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


decide_next_p_task:
    ; queue_indexをもとにctx_nextを設定
    mov si, [queue_index]
    mov ax, si
    shl si, 1                        ; si *= 2 (wordサイズオフセット)
    mov bx, [p_task_queue + si]
    mov [ctx_next], bx              ; 次の実行タスクをセット

    ; queue_index++
    inc ax
    mov cx, [queue_size]
    xor dx, dx
    div cx
    mov [queue_index], dx           ; dx = ax % queue_size

    ret



;********************************
; タスクロード
;********************************
load_k_task:
    mov ax, k_task_seg
    mov es, ax
    mov bx, 0x0000
    mov ch, 0x00
    mov cl, k_task_sector
    call read_k_sectors
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
    mov al, 9            ; 固定で9セクタ読み込み
    int 0x13
    pop ax
    pop dx
    ret

read_k_sectors:
    push dx
    push ax
    mov dl, 0x80
    mov ah, 0x02
    mov al, 17            ; 固定で17セクタ読み込み
    int 0x13
    pop ax
    pop dx
    ret

;********************************
; 割り込み関連設定
;********************************
init_pit:
    mov al, 0x36           ; mode 3, square wave
    out 0x43, al
    ;mov al, 0x9B          ; low byte (approx. 100Hz)
    mov al, 0xA7           ; low byte (approx. 400Hz)
    ;mov al, 0xA9          ; low byte (approx. 1000Hz)
    ;mov al, 0xff
    out 0x40, al
;    mov al, 0x2E          ; high byte(approx. 100Hz)
    mov al, 0x0B           ; high byte(approx. 400Hz)
    ;mov al, 0x04          ; high byte(approx. 100H0z)
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

; IRQ0 と IRQ1 を許可（1111 1100 = 0xFC）
    mov al, 0xFC
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
; irq0  関連設定
;********************************
install_irq0_handler:
    ; IRQ0 (INT 0x20) → offset 0x0000:0800 に配置されると仮定
    mov ax, 0x0000
    mov ds, ax
    mov word [irq0_vector * 4], irq0_handler     ; offset
    mov word [irq0_vector * 4 + 2], parent_seg   ; segment
    ret

; irq0  ハンドラ本体
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

    ; 動作確認用表示処理
    mov ah, 19
    mov al, 30
    mov bx, ._s_msg
    call disp_strd
    
    ; カウンタ情報の更新
    inc word [current_counter]
    call get_tick
    inc ax
    cmp ax, 65500
    jb .skip_clear
    mov ax, 0
.skip_clear:
    call set_tick

    ; 動作確認用表示処理
    mov bx, ax
    mov ah, 19
    mov al, 33
    call disp_word_hexd
    
    ;mov al, ':'
    ;call putc
    ;mov ax, sp
    ;call disp_hex
    
    ;mov ax, bx
    ;call set_cursor_pos

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

._s_msg db 'h0:', 0x00


;********************************
; irq1  関連設定
;********************************
install_irq1_handler:
    mov ax, 0x0000
    mov ds, ax
    mov word [irq1_vector * 4], irq1_handler     ; offset
    mov word [irq1_vector * 4 + 2], parent_seg   ; segment
    ret

; irq1  ハンドラ本体
irq1_handler:
    cli
    ;sti
    push ax
    push bx
    push cx
    ;push dx
    push ds
    push es
    
    mov ax, cs
    mov ds, ax
    mov es, ax
    
    ; 動作確認用表示
    mov ah, 21
    mov al, 30
    mov bx, ._s_msg
    call disp_strd

    
    mov ax, 0x0000
    in al, 0x60           ; スキャンコードを読む

    mov bx, ax
    
    mov ah, 21
    mov al, 33
    call disp_word_hexd

    cmp bl, 0xe0
    je .skip

    ; ログバッファに書く
    mov ax, bx
    call write_log

.skip:

    ; 動作確認用表示
    ;push ax
    ;push bx
    ;push es
    ;push ds

    ;mov cx, bx
;   ; mov ax, key_buf_seg
    ;mov ax, shared_buf_seg
    ;mov es, ax
    ;mov ds, ax
    ;mov bx, 0x0000
   
    ;mov al, ' '
    ;call putc
    ;mov word ax, [es:bx + 0]
    ;call disp_hex
    ;mov al, ' '
    ;call putc
    ;mov ax, [es:bx + 2]
    ;call disp_hex
    ;mov al, ' '
    ;call putc
    ;mov ax, [es:bx + 4]
    ;call disp_hex
    ;mov al, ' '
    ;call putc
    ;mov ax, [es:bx + 6]
    ;call disp_hex
    ;mov al, ' '
    ;call putc
    ;mov ax, [es:bx + 8]
    ;call disp_hex

    
    ;pop ds
    ;pop es
    ;pop bx
    ;pop ax
    
    
    mov al, 0x20
    out 0x20, al
    
    pop es
    pop ds
    ;pop dx
    pop cx
    pop bx
    pop ax
    

    iret

._s_msg db 'h1:', 0x00
._b_key_condition db 0x00


;********************************
; 共通ルーチン
;********************************
write_log:
    push bx
    push cx
    push dx
    push ds
    push es
    
    ; 共有バッファセグメントをセット
    mov dx, shared_buf_seg
    mov ds, dx
    mov es, dx
    mov di, 0x0000

    
    ; 現在のheadの値を取得
    mov word bx, [es:shared_head_ofs]
    mov word [._next_head_val], bx
    mov word [._current_head_val], bx
    
    ; 次のheadの値を仮計算
    inc word [._next_head_val]
    cmp word [._next_head_val], shared_buf_len     ; shared_buf_lenの実際の値
    jb .no_wrap
    mov word [._next_head_val], 0                  ; バッファ末尾に達したら0に戻す
.no_wrap:
    
    ; バッファが満杯かチェック
    mov bx, [es:shared_tail_ofs]
    mov [._current_tail_val], bx
    mov cx, [._current_head_val]
    inc cx
    cmp bx, cx
    je .full                    ; 次の位置がtailと同じなら満杯
    
    ; 現在のhead位置にデータを書き込み
    mov word bx, [._current_head_val]
    add bx, shared_data_ofs
    mov word [._data_pos], bx
    mov byte [es:bx], al

    ; head位置を更新
    mov word bx, [._next_head_val]
    mov word [es:shared_head_ofs], bx
    
    ;mov word bx, [._current_tail_val]
    ;mov word [es:shared_tail_ofs], bx
    jmp .not_full
    
.full:
    xor dx, dx
.not_full:
    pop es
    pop ds
    pop dx
    pop cx
    pop bx
    ret

._next_head_val dw 0
._current_head_val dw 0
._current_tail_val dw 0
._data_pos dw 0

read_log:
    push bx
    push cx
    push ds
    push es
    
    mov ax, 0x0000
    mov bx, shared_buf_seg
    mov ds, bx
    mov es, bx
    mov bx, 0x0000
    
    mov cx, [es:bx + shared_head_ofs]
    mov dx, [es:bx + shared_tail_ofs]
    
    inc dx
    cmp dx, shared_buf_len + 1
    ;cmp dx, 256 + 1
    jb .no_wrap
    mov dx, 0
.no_wrap:
    
    cmp cx, dx
    je .empty
    mov [es:bx + shared_tail_ofs], dx
    mov ax, [es:bx + shared_tail_ofs]
    
    add bx, dx
    add bx, shared_data_ofs
    mov byte al, [es:bx]
    mov byte [es:bx], 0x00
    jmp .not_empty
.empty:
    sub cx, dx
.not_empty:
    pop es
    pop ds
    pop cx
    pop bx

    ret


section .data

;********************************
; 領域設定
;********************************
section .data

parent_seg     equ 0x8000
k_task_seg     equ 0x9000
d_task_seg     equ 0x2000
p_task1_seg    equ 0x3000
p_task2_seg    equ 0x4000
p_task3_seg    equ 0x5000

ctx_k_task_sp equ 0x7000

k_task_sector  equ 12       ; 子1はセクタ19から読み込む
d_task_sector  equ 29      ; 子2はセクタ14から読み込む
p_task1_sector  equ 38      ; 子3はセクタ18から読み込む
p_task2_sector  equ 47      ; 子3はセクタ22から読み込む
p_task3_sector  equ 56      ; 子3はセクタ26から読み込む


irq0_vector    equ 0x20
irq1_vector    equ 0x21

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

call_counter dw 0x0000

ctx_k_task equ 0x9000
ctx_d_task equ 0x8500
ctx_p_task1 equ 0x8600
ctx_p_task2 equ 0x8700
ctx_p_task3 equ 0x8800

ctx_k_task_sp equ 0x7000
ctx_d_task_sp equ 0x7300
ctx_p_task1_sp equ 0x7600
ctx_p_task2_sp equ 0x7900
ctx_p_task3_sp equ 0x7b00

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

;ctx_current dw 0x0000
;ctx_next  dw 0x0000
;ctx_temp    dw 0x0000

;tick_addr equ 0xfff0
;tick_seg equ 0x8000

p_task_queue:
    dw ctx_p_task1, ctx_p_task2, ctx_p_task3  ; キュー内容
queue_size:
    dw 3
queue_index:
    dw 0


%include "routine2.asm"

%include "routine_imp.inc"

