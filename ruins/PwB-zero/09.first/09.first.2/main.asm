;>===========================
;>  実験コード
;>===========================

;>===========================
;> main
;>===========================

main:
    org 0x0000
    
    jmp $+3
    pop si
    mov ax, cs
    mov es, ax
    mov ds, ax
    mov ax, 0x9000
    mov ss, ax
    mov ax, 0xfffe
    mov sp, ax

    ; ビデオモードの設定
    mov ah, 0x0
    mov al, 0x3    ; 16色テキスト、80x25
    int 0x10

    ; 念のため初期化
    cld

    jmp main2

old_irq0_ptr: 
old_ir10_off: dw 0
old_irq0_seg: dw 0


;==============================================================
; mainの末端
;==============================================================
    times 0x0200-($-$$)-2 db 0
    

;********************************
; セクションシグネチャ
;********************************

db 0x55
db 0xAA

;>===========================
;> サブルーチンの実体
;>===========================

%include "routine.asm"

cursor_pos: dw 160      ; 表示位置（80*2で2行目開始）


;==============================================================
; サブルーチンの末端
;==============================================================
    times 0x2600 -($-$$)-2 db 0
    


;********************************
; セクションシグネチャ
;********************************

db 0x55
db 0xAA

;********************************
; main2
;********************************
main2:

    ;mov ah, 0x0e
    ;mov al, '?'
    ;int 0x10

    ;call exp_routine_test
    ;call cls
    ;call far [cls_ptr]
    
    ;call exp_routine_test
    ;call far [exit_ptr]
    ;call far [_hlt_ptr]

._loop:
;    hlt
    
    mov ax, _s_one_line_buf
    mov bx, es
    ;call far [one_line_editor_ptr]
    ;call one_line_editor

    call far [line_input_ptr]

    call command

    jmp ._loop

    jmp _hlt

exp_read_exec1:
    
    mov ax, 0x300
    mov bl, 0x19
    call read_exec
    
    ret

exp_read_exec2:

    mov ax, 0x380
    mov bl, 0x19
    call read_exec
    
    ret

exp_read_exec3:

    mov ax, 0x340
    mov bl, 0x19
    call read_exec
    
    ret

exp_read_exec4:

    mov ax, 0x300
    mov bl, 0x1d
    call read_exec
    
    ret

exp_read_exec5:

    mov ax, 0x340
    mov bl, 0x1d
    call read_exec
    
    ret
;********************************
; read_exec
;       実行する
; param : ax : 読み込むアドレス
; return: 
;********************************
read_exec:

    push ax
    push bx
    push cx
    push dx
    push es

    mov [_w_ax], ax
    mov [_b_bl], bl
    ;
    ; disk read
    ;     read to es:bx
    ;
    mov es, ax
    mov bx, 0x0000

    mov ah, 0x02 ; Read Sectors From Drive
    mov dl, 0x80 ; Drive
    mov al, 0x02 ; Sectors To Read Count ;
    mov ch, 0x00 ; Cylinder
    mov cl, [_b_bl] ; Sector(starts from 1, not 0) ; set 2. becouse not need MBR
    mov dh, 0x00 ; Head

    int 0x13     ; Execute disk read

    pop es
    pop dx
    pop cx
    pop bx
    pop ax



    jc  .disk_error
    ;jmp 0x07c0:0x3200
    
    mov ax, [_w_ax]
    mov es, ax
    mov bx, 0x0000
    push word es     ; セグメント
    push word bx     ; オフセット
    retf             ; far return → jmp es:bx と同じ意味
    ;mov word [.jmp_addr], bx   ; offset
    ;mov word [.jmp_addr+2], es  ; segment
    ;jmp far [.jmp_addr]


.jmp_addr:
    dw  0
    dw  0

.disk_error:
    mov bx, ax
    mov ah, 0x0e
    mov al, 'E'
    int 0x10          ; Eを画面に表示
    
    mov ax, bx
    call disp_word_hex     ; 自作関数などで表示

    call _hlt


    
    ret


._test_reg: dw 0x07c0

;********************************
; command
;       実行する
; param : ax : 入力された文字列を格納するバッファのアドレス
;              オーバーフロー注意
;              暫定ルーチン。テスト用かな。
; return: 
;********************************
command:

    ;
    ;   入力値をバッファに退避
    ;
    push ax
    push di
    push si
    
    mov si, ax
    mov di, _s_cmp_buf
    
    mov ds, bx
    mov es, bx

    ; バッファの初期化
    push ax
    mov cx, 128
    mov al, 0
    rep stosb
    pop ax

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
    pop ax

    ; 小文字に変換
    mov ax, _s_cmp_buf
    mov bx, es
    call far [lcase_ptr]

    ; テーブルから探す
    mov byte [_b_il], -1

._loop:
    inc byte [_b_il]
    mov ax, _s_cmp_buf
    mov cx, [_b_il]
    shl cx, 3
    mov bx, _c_command
    add bx, cx

    cmp byte [bx], 0x00
    je ._exit
    mov cx, es
    call far [str_cmp_ptr]
    cmp dx, 0x00
    jne  ._loop


    ; テーブルになければ抜ける
    mov bl, [_b_il]
    cmp bl, 0x08
    jg ._exit


    mov bx, _c_cmd_tbl
    mov al, [_b_il]
    mov byte [_b_il], 0
    mov ah, 0x00
    shl ax, 1
    add bx, ax
    cmp ax, 2
    jg ._near_call

    cmp ax, 2
    je ._call_exit
    call far [cls_ptr]
    jmp ._exit2

._call_exit:
    call far [exit_ptr]
    jmp ._exit2

._near_call:
    call word [bx]
    jmp ._exit2


._exit:

    mov bx, _s_one_line_buf
    cmp bh, 0x00
    je ._exit2
    mov ax, bx
    mov bx, es
    call far [disp_str_ptr]
    call far [disp_nl_ptr]

._exit2:

    ret
    

_c_command:
_c_cls:  db 'cls', 0x00, 0x00, 0x00, 0x00, 0x00
_c_exit: db 'exit', 0x00, 0x00, 0x00, 0x00
_c_exec1:db '3000', 0x00, 0x00, 0x00, 0x00
_c_help: db 'help', 0x00, 0x00, 0x00, 0x00
_c_exec2:db '3800', 0x00, 0x00, 0x00, 0x00
_c_exec3:db '3400', 0x00, 0x00, 0x00, 0x00
_c_exec4:db '3002', 0x00, 0x00, 0x00, 0x00
_c_exec5:db '3402', 0x00, 0x00, 0x00, 0x00
_c_exec6:db 'exec', 0x00, 0x00, 0x00, 0x00
_c_end : db         0x00, 0x00, 

_c_cmd_tbl:
    dw cls
    dw exit
    dw exp_read_exec1
    dw _cmd_help
    dw exp_read_exec2
    dw exp_read_exec3
    dw exp_read_exec4
    dw exp_read_exec5
    dw exp_exec
    dw 0x0000

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
._c_3000: db '  3000', 0x0d, 0x0a
._c_3400: db '  3400', 0x0d, 0x0a
._c_3800: db '  3800', 0x0d, 0x0a
._c_S000: db '  3002', 0x0d, 0x0a
._c_S400: db '  3402', 0x0d, 0x0a
._c_exec: db '  exec', 0x0d, 0x0a
._c_help: db '  help', 0x0d, 0x0a
._c_exit: db '  exit', 0x0d, 0x0a
._c_nl2:  db           0x0d, 0x0a, 0x00


no_ope:
    push si
    ret


    call _hlt
    ret



;==============================================================
; 割り込み処理本体
;==============================================================
; --- IRQ0 タイマ割り込みハンドラ ---

irq0_handler:

jmp .alt_proc

    cli
    push ax
    push bx
    push ds
    push es

    mov ax, cs
    push ax
    mov ax, .after_func
    push ax

    ; 現在のタスク情報を保存
    cmp byte [current_task], 0
    je .save_task3

.save_task4:
    mov ax, ss
    mov [task4_ss], ax
    mov sp, sp
    mov [task4_sp], sp
    jmp .load_task3

.save_task3:
    mov ax, ss
    mov [task3_ss], ax
    mov sp, sp
    mov [task3_sp], sp

.load_task4:
    mov ax, [task4_ss]
    mov ss, ax
    mov sp, [task4_sp]
    mov byte [current_task], 1
    ;jmp far [task4_entry]
    jmp 0x480:0x0000
    jmp .after_func

.load_task3:
    mov ax, [task3_ss]
    mov ss, ax
    mov sp, [task3_sp]
    mov byte [current_task], 0
    ;jmp far [task3_entry]
    jmp 0x400:0x0000

    ret

.old_proc:
    cli
    push ax
    push bx
    push es
    push ds

    mov ax, 0x480
    mov es, ax
    mov bx, 0x0000

    mov ax, cs
    push ax
    mov ax, .after_func
    push ax

    jmp 0x480:0x0000
    ;call far [es:bx] 


.alt_proc:
    cli
    push ax
    push bx
    push es
    push ds

    mov ax, cs
    push ax
    mov ax, .after_func
    push ax

    cmp byte [current_task], 0
    je .task4

.task3:
    mov byte [current_task], 0
    jmp 0x400:0x0000

.task4:
    mov byte [current_task], 1
    jmp 0x480:0x0000


.after_func:

    ; チェーン：元のIRQ0ハンドラ呼び出し
    pushf
    call far [old_irq0_ptr]

    ; EOI（End Of Interrupt）をマスタPICへ送信
    mov al, 0x20
    out 0x20, al           ; ← 重要：EOI（これがないと2回目来ない）

    pop ds
    pop es
    pop bx
    pop ax
    iret

;===========================
; タスクコンテキスト
;===========================
task3_ss    dw 0x500
task3_sp    dw 0xFFFE

task4_ss    dw 0x600
task4_sp    dw 0xFFFE

current_task db 0

task3_entry:
    dw 0x0000
    dw 0x400   ; func3 @ segment 0x400

task4_entry:
    dw 0x0000
    dw 0x480   ; func4 @ segment 0x420

func3_seg: dw 0
func3_off: dw 0

;==============================================================
; 任意の処理。基本的にデバッグ用
;==============================================================
exp_exec:

    push ax
    push bx
    push cx

;    call get_cursor_pos
    mov cx, ax
    mov ah, 22
    mov al, 70
;    call set_cursor_pos

    mov ah, 0x0e
    mov al, 'H'
    int 0x10
    mov al, 'e'
    int 0x10
    mov al, 'l'
    int 0x10
    mov al, 'l'
    int 0x10
    mov al, 'o'
    int 0x10
    mov al, 0x0a
    int 0x10
    mov al, 0x0d
    int 0x10



    ;mov ax, 0x300
    ;mov es, ax
    ;mov bx, 0x0000
    ;mov ax, [es:bx]
    ;;mov ax, [0x300:0x0000]
    ;call disp_word_hex
    ;call disp_nl

    ;mov word [.jmp_addr], bx   ; offset
    ;mov word [.jmp_addr+2], es  ; segment
    ;jmp far [.jmp_addr]

    mov ah, 23
    mov al, 70
;    call set_cursor_pos

;    mov ax, es
;    call disp_word_hex
;    call disp_nl

    mov ax, ._s_msg2
    mov bx, es
    call far [disp_str_ptr]


    mov ax, cx
;    call set_cursor_pos

    pop cx
    pop bx
    pop ax

    ret

.jmp_addr:
    dw  0
    dw  0

._s_msg2 db 'execute', 0x00

;==============================================================
; mainの末端
;==============================================================
_padding2:
    times 0x2E00-($-$$)-2 db 0
    

;********************************
; セクションシグネチャ
;********************************

db 0x55
db 0xAA

