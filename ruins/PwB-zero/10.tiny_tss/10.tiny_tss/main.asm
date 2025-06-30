org 0x0000
bits 16

jmp start

temp_jmp:
    temp_jmp_off:   dw 0x0000     ; offset
    temp_jmp_seg:   dw 0x0000     ; segment

; -------------------------------
; 疑似TSS構造体
; -------------------------------
current_task:       dw 0

task1_context:
task1_id:           dw 1
task1_ip:           dw 0
task1_cs:           dw 0
task1_ss:           dw 0
task1_sp:           dw 0
task1_ds:           dw 0
task1_ax:      dw 0
task1_bx:      dw 0
task1_cx:      dw 0
task1_dx:      dw 0
task1_si:      dw 0
task1_di:      dw 0
task1_bp:      dw 0
task1_flags:   dw 0

task2_context:
task2_id:           dw 2
task2_ip:           dw 0
task2_cs:           dw 0
task2_ss:           dw 0
task2_sp:           dw 0
task2_ds:           dw 0
task2_ax:      dw 0
task2_bx:      dw 0
task2_cx:      dw 0
task2_dx:      dw 0
task2_si:      dw 0
task2_di:      dw 0
task2_bp:      dw 0
task2_flags:   dw 0

task3_context:
task3_id:           dw 3
task3_ip:           dw 0
task3_cs:           dw 0
task3_ss:           dw 0
task3_sp:           dw 0
task3_ds:           dw 0
task3_ax:      dw 0
task3_bx:      dw 0
task3_cx:      dw 0
task3_dx:      dw 0
task3_si:      dw 0
task3_di:      dw 0
task3_bp:      dw 0
task3_flags:   dw 0

main_ds: dw 0

task_switch_jump:
    dw 0
    dw 0

;main_ds: dw 0x1000

; -------------------------------
; セクション終端
; -------------------------------
;times 2048 - ($ - $$) -2 db 0
;dw 0xAA55

; -------------------------------
; メイン処理開始
; -------------------------------
start:
    
    sti
    hlt
    
    jmp $+3
    pop si
    mov ax, cs
    mov ds, ax
    mov es, ax

    
    mov word [task1_cs], 0x2000
    mov word [task2_cs], 0x2400
    mov word [task3_cs], 0x2800

    call init_jump

    ; routine を 0x9000:0000 に読み込む
    mov ax, 0x9000
    mov es, ax
    xor bx, bx
    mov ah, 0x02       ; int 13h: read
    mov al, 4          ; 読み込みセクタ数
    mov ch, 0          ; cylinder
    mov cl, 2          ; sector = 4 (1-based)
    mov dh, 0          ; head
    mov dl, 0x80       ; HDD
    int 0x13
    jc .load_error1     ; キャリーが立ったら失敗


    ; task1 を 0x2000:0000 に読み込む
    mov ax, 0x2000
    mov es, ax
    xor bx, bx
    mov ah, 0x02       ; int 13h: read
    mov al, 1          ; 読み込みセクタ数
    mov ch, 0          ; cylinder
    mov cl, 10          ; sector = 4 (1-based)
    mov dh, 0          ; head
    mov dl, 0x80       ; HDD
    int 0x13
    jc .load_error1     ; キャリーが立ったら失敗



    ; task2 を 0x2100:0000 に読み込む
    mov ax, 0x2400
    mov es, ax
    xor bx, bx
    mov ah, 0x02       ; int 13h: read
    mov al, 1          ; 読み込みセクタ数
    mov ch, 0          ; cylinder
    mov cl, 11          ; sector = 5
    mov dh, 0          ; head
    int 0x13
    jc .load_error2

    ; task3 を 0x2200:0000 に読み込む
    mov ax, 0x2800
    mov es, ax
    xor bx, bx
    mov ah, 0x02       ; int 13h: read
    mov al, 1          ; 読み込みセクタ数
    mov ch, 0          ; cylinder
    mov cl, 12          ; sector = 6
    int 0x13
    jc .load_error3
    mov dh, 0          ; head

    jmp .load_normal

.load_error1:
.load_error2:
    mov ah, 0x0e
    mov al, '!'
    int 0x10
.load_error3:
    mov ah, 0x0e
    mov al, '!'
    int 0x10

    call print_hex_word

    mov si, .msg_fail
.print:
    lodsb
    or al, al
    jz $
    mov ah, 0x0e
    int 0x10
    jmp .print

.msg_fail:
    db "LOAD ERR", 0

.load_normal:
    ; task3 のスタックに戻り先を積む（iret対策）
    mov ax, 0x2800
    mov ss, ax
    mov sp, 0x7c00

    mov ax, 0x0200
    push ax            ; FLAGS
    mov ax, 0x2800
    push ax            ; CS
    mov ax, 0x0000
    push ax            ; IP

mov word [task3_sp], sp
    
    ; タスク1と2の初期化
    ;mov word [task1_ip], 0x0002   ;task1
    mov word [task1_ip], 0x0000
    mov word [task1_cs], 0x2000
    mov word [task1_ss], 0x3000
    mov word [task1_sp], 0x7c00
    mov word [task1_ds], 0x2000
    mov word [task1_flags], 0x0200

    ;mov word [task2_ip], 0x100b   ;task2
    mov word [task2_ip], 0x0000
    mov word [task2_cs], 0x2400
    mov word [task2_ss], 0x3400
    mov word [task2_sp], 0x7c00
    mov word [task2_ds], 0x2400
    mov word [task2_flags], 0x0200

    ;mov word [task3_ip], 0x1014   ;task3
    mov word [task3_ip], 0x0000
    mov word [task3_cs], 0x2800
    mov word [task3_ss], 0x3800
    mov word [task3_sp], 0x7c00
    mov word [task3_ds], 0x2800
    mov word [task3_flags], 0x0200

    mov ax, ds
    mov [main_ds] , ax

    ;mov word [current_task], task1_context
    mov ax, task3_context
    mov [current_task], ax

    sti

    ; PIT 初期化（100Hz）
    mov al, 0x36
    out 0x43, al
    mov ax, 1193
    out 0x40, al
    mov al, ah
    out 0x40, al

    ; 割り込みベクタの設定
    push es
    xor ax, ax
    mov es, ax
    mov ax, cs
    mov word [es:0x20], irq0_handler
    mov [es:0x22], ax
    pop es

    ; PIC 初期化（マスタ・スレーブ）
    mov al, 0x11
    out 0x20, al
    mov al, 0x08
    out 0x21, al
    mov al, 0x04
    out 0x21, al
    mov al, 0x01
    out 0x21, al

    mov al, 0x11
    out 0xA0, al
    mov al, 0x70
    out 0xA1, al
    mov al, 0x02
    out 0xA1, al
    mov al, 0x01
    out 0xA1, al


    ; 無効化
    ;in  al, 0x21
    ;or  al, 0x01
    ;out 0x21, al

    ; 有効化
    in  al, 0x21
    and al, 0xFE
    out 0x21, al


    sti

    ; 割り込み有効化後、初回だけ after_func を呼ぶ
    
    ;mov si, [current_task]
    ;jmp after_func
    ;call after_func
    ;call irq0_handler
    
main_loop:
    sti
    hlt
    ;jmp main_loop

    mov ax, _s_one_line_buf
    mov bx, ds
    call far [line_input_ptr]
    mov [_w_ax], ax

    call command

    jmp main_loop


command:

    ;call set_own_ds

    mov [_w_ax], ax

    ;
    ;   入力値をバッファに退避
    ;
    ; バッファの初期化
    push ax
    mov cx, 128
    mov di, _s_cmp_buf
    mov al, 0
    rep stosb
    pop ax

    push di
    push si
    mov si, ax
    mov di, _s_cmp_buf

._cpy_loop:
    lodsb
    or al, al
    jz ._cpy_skip
    mov [di], al
    inc di
    jmp ._cpy_loop

._cpy_skip:
    pop si
    pop di

    ;
    ; 小文字に変換
    ;
    mov ax, _s_cmp_buf
    mov bx, ds
    
    call far [lcase_ptr]

    mov dx, -1

._loop:
    inc dx
    mov ax, _s_cmp_buf
    mov cx, dx
    shl cx, 3
    mov bx, _c_command
    add bx, cx

    cmp byte [bx], 0x00
    je ._exit

    push dx
    mov cx, ds
    call far [str_cmp_ptr]
    mov cx, dx
    pop dx
    cmp cx, 0x00
    jne  ._loop

    cmp dx, 0x00    ; cls
    jne ._next
    call far [cls_ptr]
    jmp ._exit2

._next:
    cmp dx, 0x01    ; exit
    jne ._next2
    call far [exit_ptr]
    jmp ._exit2

._next2:
    cmp dx, 0x02    ; help
    jne ._next3
    call _cmd_help
    jmp ._exit2

._next3:
    cmp dx, 0x03    ; exec
    jne ._next4
    call _cmd_exec
    jmp ._exit2

._next4:

._exit:
    mov bx, ds
    call far [disp_str_ptr]
    mov ah, 0x0e
    mov al, 0x0d
    int 0x10
    mov al, 0x0a
    int 0x10

._exit2:


    ret
    
_w_ax: dw 0


_s_one_line_buf: times 128 db 0
_s_cmp_buf: times 128 db 0
_b_x: db 0x00
_b_y: db 0x00
_b_len: db 0x00
_b_pos: db 0x00
_b_cnt: db 0x00

_c_command:
_c_cls:  db 'cls',  0x00, 0x00, 0x00, 0x00, 0x00
_c_exit: db 'exit', 0x00, 0x00, 0x00, 0x00
_c_help: db 'help', 0x00, 0x00, 0x00, 0x00
_c_exec1:db 'exec', 0x00, 0x00, 0x00, 0x00
_c_end : db         0x00, 0x00, 

;********************************
; _cmd_help
;       実行する
; param : ax : ヘルプ表示
;              暫定ルーチン。動作確認用とかかしら。
; return: 
;********************************
_cmd_help:

    push ax
    push si
    

    mov ah, 0x0e
    mov si, ._c_msg
    
._loop:
    lodsb
    or al, al
    jz ._exit
    int 0x10
    jmp ._loop
    
    
._exit:
    pop si
    pop ax

    ret

._c_msg:
._c_nl:   db           0x0d, 0x0a
._c_cls:  db '  cls',  0x0d, 0x0a
._c_help: db '  help', 0x0d, 0x0a
._c_exit: db '  exit', 0x0d, 0x0a
._c_exec: db '  exec', 0x0d, 0x0a
._c_nl2:  db           0x0d, 0x0a, 0x00


no_ope:
    push si
    ret


    call far [_hlt_ptr]
    ret

;********************************
; _cmd_help
;       実行する
; param : ax : ヘルプ表示
;              暫定ルーチン。動作確認用とかかしら。
; return: 
;********************************
_cmd_exec:
;    mov ax, ._s_msg
;    mov bx, [main_ds]
;    call far [disp_str_ptr]
    
    push ax
    push ds
    
    mov ax, 0x8000
    mov ds, ax
    mov ah, 0x00
    mov al, 0x00
    call far [set_cursor_pos_ptr]
    
    pop ds
    pop ax

    ret

._s_msg: db 'Execute', 0x0d, 0x0a, 0x00

; -------------------------------
; IRQ0 ハンドラ → タスク切り替え
; -------------------------------
irq0_handler:
    pusha
    push ds

    push es
    push fs
    push gs
    
    
    mov ax, [main_ds]
    mov es, ax
    mov ds, ax
    
    ; EOI
    mov al, 0x20
    out 0x20, al


    ; context 保存
    push ax
    push bx
    mov si, [current_task]
    mov bx, si
    mov [si+20], bx
    ;; DS の保存
    mov ax, ds
    mov [si+10], ax
    pop ax
    pop bx
    


    ; レジスタ保存（task?_context に）
    ; SP/SS はスタック切り替え後に保存されるのでここでは不要
    mov [si+12], ax   ; AX
    mov [si+14], bx
    mov [si+16], cx
    mov [si+18], dx
    mov [si+20], si
    mov [si+22], di
    mov [si+24], bp

    pushf
    pop ax
    mov [si+26], ax


    ; タスク切り替え
    mov ax, [current_task]
    cmp ax, task1_context
    je .switch_to_task2
    cmp ax, task2_context
    je .switch_to_task3
    cmp ax, task3_context
    je .switch_to_task1

.switch_to_task1:
    mov si, task1_context
    jmp .done_switch
.switch_to_task2:
    mov si, task2_context
    jmp .done_switch
.switch_to_task3:
    mov si,task3_context
    jmp .done_switch
.done_switch:
    mov [current_task], si

    mov si, [current_task]

    jmp after_func

after_func:
    cli
    
    mov ax, [main_ds]
    mov es, ax
    mov ds, ax

    ; タスクの CS, IP を一時変数に保存
    mov ax, [si+2]        ; IP
    mov bx, [si+4]        ; CS
    
     ; スタック切り替え
;    push bx
    mov dx, [si+8]          ; sp
    mov bx, [si+4]
    mov ss, bx
    mov sp, dx
;    pop bx

    ; 汎用レジスタを復元
    mov ax, [si+12]
    mov bx, [si+14]
    mov cx, [si+16]
    mov dx, [si+18]
    mov di, [si+22]
    mov bp, [si+24]

    mov si, [current_task]
    
    mov ax, [si+26]
    push ax             ; FLAGS
    
    mov ax, [si+4]
    mov [next_cs], ax
    push ax             ; CS

    mov ax, [si+2]
    mov [next_ip], ax
    push ax             ; IP
    

    ;jmp far [next_task]


    iret     
    
    
    ;retf
 
next_task:
    next_ip: dw 0
    next_cs: dw 0

; -------------------------------
; 初期化サブルーチン
; -------------------------------
init_jump:
    mov word [task_switch_jump], irq0_handler
    mov word [task_switch_jump + 2], cs
    ret


; -------------------------------
; 画面に1文字表示
; -------------------------------
putc:
    mov ah, 0x0e
    int 0x10
    ret

; -------------------------------
; AXの内容（16bit）を16進で表示（4桁）
; -------------------------------
print_hex_word:
    pusha
    mov bx, ax

    ; 桁1
    mov ax, bx
    shr ax, 12
    and al, 0x0F
    call hex_digit

    ; 桁2
    mov ax, bx
    shr ax, 8
    and al, 0x0F
    call hex_digit

    ; 桁3
    mov ax, bx
    shr ax, 4
    and al, 0x0F
    call hex_digit

    ; 桁4
    mov ax, bx
    and al, 0x0F
    call hex_digit

    popa
    ret

hex_digit:
    cmp al, 10
    jl .digit
    add al, 'A' - 10
    jmp .emit
.digit:
    add al, '0'
.emit:
    call putc
    ret

;********************************
; set_own_ds
;       実行時のcsにdsを合わせる。
; param : 
; return: 
;********************************
set_own_ds:

    jmp $+3
    pop si
    mov ax, cs
    mov ds, ax
    mov es, ax

    ret

; -------------------------------
; declareクション
; -------------------------------

%include "def.asm"


; -------------------------------
; セクション終端
; -------------------------------
times 2048 - ($ - $$) -2 db 0
dw 0xAA55
