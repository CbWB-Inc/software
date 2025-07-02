;org 0x0000
bits 16

%include "routine_imp.inc"


;----------------------------------
; スタート
;----------------------------------
global _start

_start:


setup:
    call set_own_seg

    mov ax, tick_addr
    mov [tick_ptr], ax

start:
    sti
    call task_body
    sti
    hlt
    jmp start

;----------------------------------
; 処理本体（単純な表示など）
;----------------------------------
task_body:
    
    call set_own_seg
    
    mov ah, 17
    mov al, 30
    mov bx, ._s_msg
    call disp_strd

    call get_tick
    mov bx, ax
    mov ah, 17
    mov al, 33
    call disp_word_hexd
    
    cli
    mov bx, 0x0000
    mov ax, 0x0000
    call get_key_data
    ; こそっとbxにキーコードが返ってきてるので、それで遊ぶ
    mov ax, bx
    and ah, 0x01
    cmp ah, 0x00
    je .send_skip
    call send_message

.send_skip:

    sti

    ; 動作確認＆デモ処理
    call disp_p_task1_condition
    call disp_p_task2_condition
    call disp_p_task3_condition
    
    ; 動作確認用表示
    ;push ax
    ;push bx
    ;push es
    ;push ds
    ;mov ax, key_buf_seg
    ;;mov ax, shared_buf_seg
    ;mov es, ax
    ;mov ds, ax
    ;mov bx, 0x00
    ;mov al, ' '
    ;call putc
    ;mov ax, [es:bx + 0]
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

    ret

._s_msg: db 'k :', 0x00
._dt_save db 0
;----------------------------------
; 共通ルーチンなど（必要に応じて）
;----------------------------------

%include "routine2.asm"

send_message:

    mov bx, ax
    cmp bl, '2'
    je ._id2
    cmp bl, '3'
    je ._id3
    cmp bl, '4'
    je ._id4
    cmp bl, '5'
    je ._id5
    mov ax, 0x0000
    mov bx, 0x0000
    jmp ._exit

._id2:
    call get_tick
    mov bx, ax
    mov al, 0x02
    jmp ._send

._id3:
    call get_tick
    mov bx, ax
    mov al, 0x03
    jmp ._send

._id4:
    call get_tick
    mov bx, ax
    mov al, 0x04
    jmp ._send

._id5:
    call get_tick
    mov bx, ax
    mov al, 0x05
    jmp ._send

._send:
    mov ah, 0x01
    mov cx, ax
    mov dx, bx
    call send_msg
    jz ._full

    
    ;mov ah, 17
    ;mov al, 20
    ;mov bx, cx
    ;call disp_word_hexd
    
    ;mov ah, 17
    ;mov al, 25
    ;mov bx, dx
    ;call disp_word_hexd

    jmp ._exit

._full:
    mov ah, 17
    mov al, 20
    mov bx, ._s_no_msg
    call disp_strd
    
._exit:
    ret

._s_no_msg db '---- ----', 0x00


disp_p_task1_condition:
    push ax
    push bx
    push cx
    
    call set_own_seg
    
    
    ; p_task1の表示
    mov ah, 17
    mov al, 43
    mov bx, ._s_msg_p1
    call disp_strd
    
    mov ax, 0x0002
    call _wait
    mov ax, ctx_p_task1_id
    call get_ctx_heartbeat
    mov dx, ax

    mov word bx, [._prev_p1_heartbeat]
    call dead_or_alive
    mov word [._prev_p1_heartbeat], ax
    mov bh, 0x07
    mov bl, cl
    mov ah, 17
    mov al, 47
    call putcd
    mov ah, 17
    mov al, 48
    mov bh, 0x07
    mov bl, ':'
    call putcd

    mov ah, 17
    mov al, 49
    mov bx, dx
    call disp_word_hexd
    mov al, 53
    mov bh, 0x07
    mov bl, ']'
    call putcd

    ;mov ah, 18
    ;mov al, 55
    ;mov bx, ._s_msg_p1
    ;call disp_strd

    
    pop cx
    pop bx
    pop ax
    ret

._prev_p1_heartbeat dw 0

._s_msg_p1 db '[p1:', 0x00




disp_p_task2_condition:
    push ax
    push bx
    push cx
    push dx
    
    call set_own_seg
    
    ; p_task2の表示
    mov ah, 17
    mov al, 55
    mov bx, ._s_msg_p2
    call disp_strd
    
    mov ax, 0x0002
    call _wait
    call disp_strd
    mov ax, ctx_p_task2_id
    call get_ctx_heartbeat
    mov dx, ax

    mov word bx, [._prev_p2_heartbeat]
    call dead_or_alive
    mov word [._prev_p2_heartbeat], ax
    mov bh, 0x07
    mov bl, cl
    mov ah, 17
    mov al, 59
    call putcd
    mov ah, 17
    mov al, 60
    mov bh, 0x07
    mov bl, ':'
    call putcd

    mov ah, 17
    mov al, 61
    mov bx, dx
    call disp_word_hexd
    mov al, 65
    mov bh, 0x07
    mov bl, ']'
    call putcd

    pop dx
    pop cx
    pop bx
    pop ax
    ret

._prev_p2_heartbeat dw 0

._s_msg_p2 db '[p2:', 0x00


disp_p_task3_condition:
    push ax
    push bx
    push cx
    
    call set_own_seg
    
    ; p_task1の表示
    mov ah, 17
    mov al, 67
    mov bx, ._s_msg_p3
    call disp_strd
    
    mov ax, 0x0002
    call _wait
    mov ax, ctx_p_task3_id
    call get_ctx_heartbeat
    mov dx, ax

    mov word bx, [._prev_p3_heartbeat]
    call dead_or_alive
    mov word [._prev_p3_heartbeat], ax
    mov bh, 0x07
    mov bl, cl
    mov ah, 17
    mov al, 71
    call putcd
    mov ah, 17
    mov al, 72
    mov bh, 0x07
    mov bl, ':'
    call putcd

    mov ah, 17
    mov al, 73
    mov bx, dx
    call disp_word_hexd
    mov al, 77
    mov bh, 0x07
    mov bl, ']'
    call putcd

    pop cx
    pop bx
    pop ax
    ret

._prev_p3_heartbeat dw 0

._s_msg_p3 db '[p3:', 0x00


write_key_buf:
    push bx
    push cx
    push dx
    push ds
    push es
    
    ; 共有バッファセグメントをセット
    mov dx, key_buf_seg
    mov ds, dx
    mov es, dx
    mov di, 0x0000
    mov bx, 0x0000

    
    ; 現在のheadの値を取得
    mov word bx, [es:key_buf_head_ofs]
    mov word [._next_head_val], bx
    mov word [._current_head_val], bx
    
    ; 次のheadの値を仮計算
    inc word [._next_head_val]
    cmp word [._next_head_val], shared_buf_len     ; shared_buf_lenの実際の値
    jb .no_wrap
    mov word [._next_head_val], 0                  ; バッファ末尾に達したら0に戻す
.no_wrap:
    
    ; バッファが満杯かチェック
    mov bx, [es:key_buf_tail_ofs]
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
    mov word [es:key_buf_head_ofs], bx
    
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



get_key_data:

.scan_loop:
    call read_log
    jz .exit
    call scancode_decode
    mov dx, bx

    ; 確認用表示
    push ax
    push bx
    mov ah, 17
    mov al, 37
    mov bh, 7
    mov bl, ':'
    call putcd
    inc al
    mov bx, dx
    call disp_word_hexd
    pop bx
    pop ax

    ; Break/Makeのフラグ確認。Breakは捨てる
    and dh, 0x01
    cmp dh, 0x01
    jne .next_data

    ; ステータスコードのみのMakeは捨てる
    cmp bl, 0x00
    je .next_data
    
    mov al, bh
    call write_key_buf
    mov al, bl
    call write_key_buf

.next_data:
.continue:
    
    jmp .scan_loop


.exit:
    mov ax, 0x002
    call _wait

    ret

._b_key_condition db 0


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


;>********************************
;> スキャンコードのデコード
;>********************************
; al = スキャンコード → bl = ASCII
;                        bh key condition
scancode_decode:
    push ax
    push ds
    push es
    
    mov ah, 0
    
    mov word bx, [.prev_bx]

    ;********************************
    ; スキャンコード    Key Condition
    ;********************************
    ;--------------------------------
;>  ; left shift
    ;--------------------------------
    cmp al, 0x2a        ; left shift Mark
    jne .ls_skip1       ; 違うなら飛ぶ
    or bh, 0x80         ; Bit 8 を立てる
    mov ch, bh
    and ch, 0x01        ; Bit 1 を調べる
    cmp ch, 0x01        ; 立っている（何かがすでにMark）
    je .done
    mov bl, 0x00        ; ctrl only なのでAsciiをクリア
    or bh, 0x01         ; Markビットを立てる
    jmp .done
.ls_skip1:

    cmp al, 0xaa        ; left shift Break
    jne .ls_skip2     ; 違うなら飛ぶ
    and bh, 0x7f        ; Bit 8 を寝かす
    mov cx, bx
    and cx, 0x6e00      ; Bit 1 を調べる
    cmp cx, 0x0000      ; 立っていない（何かがすでにKeyUp）
    jne  .done
    mov bx, 0x0000      ; ctrl only なのでAsciiをクリア
    jmp .done
.ls_skip2:


    ;--------------------------------
;>  ; right shift
    ;--------------------------------
    cmp al, 0x36        ; right shift Mark
    jne .rs_skip1       ; 違うなら飛ぶ
    or bh, 0x80         ; Bit 8 を立てる
    mov ch, bh
    and ch, 0x01        ; Bit 1 を調べる
    cmp ch, 0x01        ; 立っている（何かがすでにMark）
    je .done
    mov bl, 0x00        ; ctrl only なのでAsciiをクリア
    or bh, 0x01         ; Markビットを立てる
    jmp .done
.rs_skip1:

    cmp al, 0xb6        ; right shift Break
    jne .rs_skip2     ; 違うなら飛ぶ
    and bh, 0x7f        ; Bit 8 を寝かす
    mov cx, bx
    and cx, 0x6e00      ; Bit 1 を調べる
    cmp cx, 0x0000      ; 立っていない（何かがすでにKeyUp）
    jne  .done
    mov bx, 0x0000      ; ctrl only なのでAsciiをクリア
    jmp .done
.rs_skip2:

    ;--------------------------------
;>  ; ctrl
    ;--------------------------------
    cmp al, 0x1d        ; ctrl Mark
    jne .ctrl_skip1     ; 違うなら飛ぶ
    or bh, 0x40         ; Bit 7 を立てる
    mov ch, bh
    and ch, 0x01        ; Bit 1 を調べる
    cmp ch, 0x01        ; 立っている（何かがすでにMark）
    je .done
    mov bl, 0x00        ; ctrl only なのでAsciiをクリア
    or bh, 0x01         ; Markビットを立てる
    jmp .done
.ctrl_skip1:

    cmp al, 0x9d        ; ctrl Break
    jne .ctrl_skip2     ; 違うなら飛ぶ
    and bh, 0xbf        ; Bit 7 を寝かす
    mov cx, bx
    and cx, 0xae00      ; Bit 1 を調べる
    cmp cx, 0x0000      ; 立っていない（何かがすでにBreak）
    jne  .done
    mov bx, 0x0000      ; ctrl only なのでAsciiをクリア
    jmp .done
.ctrl_skip2:

    ;--------------------------------
;>  ; alt
    ;--------------------------------
    cmp al, 0x38        ; ctrl Mark
    jne .alt_skip1      ; 違うなら飛ぶ
    or bh, 0x20         ; Bit 6 を立てる
    mov ch, bh
    and ch, 0x01        ; Bit 1 を調べる
    cmp ch, 0x01        ; 立っている（何かがすでにMark）
    je .done
    mov bl, 0x00        ; ctrl only なのでAsciiをクリア
    or bh, 0x01         ; Markビットを立てる
    jmp .done
.alt_skip1:

    cmp al, 0xb8        ; ctrl Break
    jne .alt_skip2      ; 違うなら飛ぶ
    and bh, 0xdf        ; Bit 6 を寝かす
    mov cx, bx
    and cx, 0xce00      ; Bit 1 を調べる
    cmp cx, 0x0000      ; 立っていない（何かがすでにKeyUp）
    jne  .done
    mov bx, 0x0000      ; ctrl only なのでAsciiをクリア
    jmp .done
.alt_skip2:

    ;********************************
    ; スキャンコード    数字
    ;********************************
    mov ah, bh
    and ah, 0x80
    
    ;--------------------------------
;>  ; 1
    ;--------------------------------
    cmp ax, 0x0082      ; 1 break
    jne .nn1b_skip
    mov bl, '1'
    mov ah, bh
    and ah, 0xe0
    cmp ah, 0x00
    jne .done
    and bh, 0xfe
    jmp .done
.nn1b_skip:

    cmp ax, 0x0002      ; 1 make
    jne .nn1m_skip
    mov bl, '1'
    or bh, 0x01
    jmp .done
.nn1m_skip:

    ;--------------------------------
;>  ; !
    ;--------------------------------
    cmp ax, 0x8082      ; ! break
    jne .sn1b_skip
    mov bl, '!'
    jmp .done          ; なぜかハングするのでコメントアウト
.sn1b_skip:

    cmp ax, 0x8002      ; ! make
    jne .sn1m_skip
    mov bl, '!'
    or bh, 0x01
    jmp .done
.sn1m_skip:



    ;--------------------------------
;>  ; 2
    ;--------------------------------
    cmp ax, 0x0083      ; 1 break
    jne .nn2b_skip
    mov bl, '2'
    mov ah, bh
    and ah, 0xe0
    cmp ah, 0x00
    jne .done
    and bh, 0xfe
    jmp .done
.nn2b_skip:

    cmp ax, 0x0003      ; 1 make
    jne .nn2m_skip
    mov bl, '2'
    or bh, 0x01
    jmp .done
.nn2m_skip:

    ;--------------------------------
;>  ; "
    ;--------------------------------
    cmp ax, 0x8083      ; 1 break
    jne .sn2b_skip
    mov bl, '"'
    jmp .done
.sn2b_skip:

    cmp ax, 0x8003      ; 1 make
    jne .sn2m_skip
    mov bl, '"'
    or bh, 0x01
    jmp .done
.sn2m_skip:

    ;--------------------------------
;>  ; 3
    ;--------------------------------
    cmp ax, 0x0084      ; 1 break
    jne .nn3b_skip
    mov bl, '3'
    mov ah, bh
    and ah, 0xe0
    cmp ah, 0x00
    jne .done
    and bh, 0xfe
    jmp .done
.nn3b_skip:

    cmp ax, 0x0004      ; 1 make
    jne .nn3m_skip
    mov bl, '3'
    or bh, 0x01
    jmp .done
.nn3m_skip:

    ;--------------------------------
;>  ; #
    ;--------------------------------
    cmp ax, 0x8084      ; 1 break
    jne .sn3b_skip
    mov bl, '#'
    jmp .done
.sn3b_skip:

    cmp ax, 0x8004      ; 1 make
    jne .sn3m_skip
    mov bl, '#'
    or bh, 0x01
    jmp .done
.sn3m_skip:

    ;--------------------------------
;>  ; 4
    ;--------------------------------
    cmp ax, 0x0085      ; 1 break
    jne .nn4b_skip
    mov bl, '4'
    mov ah, bh
    and ah, 0xe0
    cmp ah, 0x00
    jne .done
    and bh, 0xfe
    jmp .done
.nn4b_skip:

    cmp ax, 0x0005      ; 1 make
    jne .nn4m_skip
    mov bl, '4'
    or bh, 0x01
    jmp .done
.nn4m_skip:

    ;--------------------------------
;>  ; $
    ;--------------------------------
    cmp ax, 0x8085      ; 1 break
    jne .sn4b_skip
    mov bl, '$'
    jmp .done
.sn4b_skip:

    cmp ax, 0x8005      ; 1 make
    jne .sn4m_skip
    mov bl, '$'
    or bh, 0x01
    jmp .done
.sn4m_skip:

    ;--------------------------------
;>  ; 5
    ;--------------------------------
    cmp ax, 0x0086      ; 1 break
    jne .nn5b_skip
    mov bl, '5'
    mov ah, bh
    and ah, 0xe0
    cmp ah, 0x00
    jne .done
    and bh, 0xfe
    jmp .done
.nn5b_skip:

    cmp ax, 0x0006      ; 1 make
    jne .nn5m_skip
    mov bl, '5'
    or bh, 0x01
    jmp .done
.nn5m_skip:

    ;--------------------------------
;>  ; %
    ;--------------------------------
    cmp ax, 0x8086      ; 1 break
    jne .sn5b_skip
    mov bl, '%'
    jmp .done
.sn5b_skip:

    cmp ax, 0x8006      ; 1 make
    jne .sn5m_skip
    mov bl, '%'
    or bh, 0x01
    jmp .done
.sn5m_skip:

    ;--------------------------------
;>  ; 6
    ;--------------------------------
    cmp ax, 0x0087      ; 1 break
    jne .nn6b_skip
    mov bl, '6'
    mov ah, bh
    and ah, 0xe0
    cmp ah, 0x00
    jne .done
    and bh, 0xfe
    jmp .done
.nn6b_skip:

    cmp ax, 0x0007      ; 1 make
    jne .nn6m_skip
    mov bl, '6'
    or bh, 0x01
    jmp .done
.nn6m_skip:

    ;--------------------------------
;>  ; &
    ;--------------------------------
    cmp ax, 0x8087      ; 1 break
    jne .sn6b_skip
    mov bl, '&'
    jmp .done
.sn6b_skip:

    cmp ax, 0x8007      ; 1 make
    jne .sn6m_skip
    mov bl, '&'
    or bh, 0x01
    jmp .done
.sn6m_skip:

    ;--------------------------------
;>  ; 7
    ;--------------------------------
    cmp ax, 0x0088      ; 1 break
    jne .nn7b_skip
    mov bl, '7'
    mov ah, bh
    and ah, 0xe0
    cmp ah, 0x00
    jne .done
    and bh, 0xfe
    jmp .done
.nn7b_skip:

    cmp ax, 0x0008      ; 1 make
    jne .nn7m_skip
    mov bl, '7'
    or bh, 0x01
    jmp .done
.nn7m_skip:

    ;--------------------------------
;>  ; '
    ;--------------------------------
    cmp ax, 0x8088      ; 1 break
    jne .sn7b_skip
    mov bl, 0x5c
    jmp .done
.sn7b_skip:

    cmp ax, 0x8008      ; 1 make
    jne .sn7m_skip
    mov bl, 0x5c
    or bh, 0x01
    jmp .done
.sn7m_skip:

    ;--------------------------------
;>  ; 8
    ;--------------------------------
    cmp ax, 0x0089      ; 1 break
    jne .nn8b_skip
    mov bl, '8'
    mov ah, bh
    and ah, 0xe0
    cmp ah, 0x00
    jne .done
    and bh, 0xfe
    jmp .done
.nn8b_skip:

    cmp ax, 0x0009      ; 1 make
    jne .nn8m_skip
    mov bl, '8'
    or bh, 0x01
    jmp .done
.nn8m_skip:

    ;--------------------------------
;>  ; (
    ;--------------------------------
    cmp ax, 0x8089      ; 1 break
    jne .sn8b_skip
    mov bl, '('
    jmp .done
.sn8b_skip:

    cmp ax, 0x8009      ; 1 make
    jne .sn8m_skip
    mov bl, '('
    or bh, 0x01
    jmp .done
.sn8m_skip:

    ;--------------------------------
;>  ; 9
    ;--------------------------------
    cmp ax, 0x008a      ; 1 break
    jne .nn9b_skip
    mov bl, '9'
    mov ah, bh
    and ah, 0xe0
    cmp ah, 0x00
    jne .done
    and bh, 0xfe
    jmp .done
.nn9b_skip:

    cmp ax, 0x000a      ; 1 make
    jne .nn9m_skip
    mov bl, '9'
    or bh, 0x01
    jmp .done
.nn9m_skip:

    ;--------------------------------
;>  ; )
    ;--------------------------------
    cmp ax, 0x808a      ; 1 break
    jne .sn9b_skip
    mov bl, ')'
    jmp .done
.sn9b_skip:

    cmp ax, 0x800a      ; 1 make
    jne .sn9m_skip
    mov bl, ')'
    or bh, 0x01
    jmp .done
.sn9m_skip:

    ;--------------------------------
;>  ; 0
    ;--------------------------------
    cmp ax, 0x008b      ; 1 break
    jne .nn0b_skip
    mov bl, '0'
    mov ah, bh
    and ah, 0xe0
    cmp ah, 0x00
    jne .done
    and bh, 0xfe
    jmp .done
.nn0b_skip:

    cmp ax, 0x000b      ; 1 make
    jne .nn0m_skip
    mov bl, '0'
    or bh, 0x01
    jmp .done
.nn0m_skip:

    ;--------------------------------
;>  ; 0
    ;--------------------------------
    cmp ax, 0x808b      ; 1 break
    jne .sn0b_skip
    mov bl, '0'
    jmp .done
.sn0b_skip:

    cmp ax, 0x800b      ; 1 make
    jne .sn0m_skip
    mov bl, '0'
    or bh, 0x01
    jmp .done
.sn0m_skip:

    ;--------------------------------
;>  ; -
    ;--------------------------------
    cmp ax, 0x008c      ; 1 break
    jne .nhib_skip
    mov bl, '-'
    mov ah, bh
    and ah, 0xe0
    cmp ah, 0x00
    jne .done
    and bh, 0xfe
    jmp .done
.nhib_skip:

    cmp ax, 0x000c      ; 1 make
    jne .nhim_skip
    mov bl, '-'
    or bh, 0x01
    jmp .done
.nhim_skip:

    ;--------------------------------
;>  ; =
    ;--------------------------------
    cmp ax, 0x808c      ; 1 break
    jne .shib_skip
    mov bl, '='
    jmp .done
.shib_skip:

    cmp ax, 0x800c      ; 1 make
    jne .shim_skip
    mov bl, '='
    or bh, 0x01
    jmp .done
.shim_skip:

    ;--------------------------------
;>  ; ^
    ;--------------------------------
    cmp ax, 0x008d      ; 1 break
    jne .ntib_skip
    mov bl, '^'
    mov ah, bh
    and ah, 0xe0
    cmp ah, 0x00
    jne .done
    and bh, 0xfe
    jmp .done
.ntib_skip:

    cmp ax, 0x000d      ; 1 make
    jne .ntim_skip
    mov bl, '^'
    or bh, 0x01
    jmp .done
.ntim_skip:

    ;--------------------------------
;>  ; ~
    ;--------------------------------
    cmp ax, 0x808d      ; 1 break
    jne .stib_skip
    mov bl, '~'
    jmp .done
    jmp .done
.stib_skip:

    cmp ax, 0x800d      ; 1 make
    jne .stim_skip
    mov bl, '~'
    or bh, 0x01
    jmp .done
.stim_skip:

    ;--------------------------------
;>  ; \
    ;--------------------------------
    cmp ax, 0x007d      ; 1 break
    jne .npib_skip
    mov bl, 0x5c
    mov ah, bh
    and ah, 0xe0
    cmp ah, 0x00
    jne .done
    and bh, 0xfe
    jmp .done
.npib_skip:

    cmp ax, 0x00fd      ; 1 make
    jne .npim_skip
    mov bl, 0x5c
    or bh, 0x01
    jmp .done
.npim_skip:

    ;--------------------------------
;>  ; |
    ;--------------------------------
    cmp ax, 0x807d      ; 1 break
    jne .spib_skip
    mov bl, 0x7c
    jmp .done
.spib_skip:

    cmp ax, 0x80fd      ; 1 make
    jne .spim_skip
    mov bl, 0x7c
    or bh, 0x01
    jmp .done
.spim_skip:

    ;--------------------------------
;>  ; bs
    ;--------------------------------
    cmp ax, 0x008e      ; 1 break
    jne .nbsb_skip
    mov bl, 0x08
    mov ah, bh
    and ah, 0xe0
    cmp ah, 0x00
    jne .done
    and bh, 0xfe
    jmp .done
.nbsb_skip:

    cmp ax, 0x000e      ; 1 make
    jne .nbsm_skip
    mov bl, 0x08
    or bh, 0x01
    jmp .done
.nbsm_skip:

    ;--------------------------------
;>  ; bs
    ;--------------------------------
    cmp ax, 0x808e      ; 1 break
    jne .sbsb_skip
    mov bl, 0x08
    jmp .done
.sbsb_skip:

    cmp ax, 0x800e      ; 1 make
    jne .sbsm_skip
    mov bl, 0x08
    or bh, 0x01
    jmp .done
.sbsm_skip:

    ;--------------------------------
;>  ; 漢字
    ;--------------------------------
    cmp ax, 0x0029      ; 1 break
    jne .nkjb_skip
    mov bl, 0x0f
    mov ah, bh
    and ah, 0xe0
    cmp ah, 0x00
    jne .done
    and bh, 0xfe
    jmp .done
.nkjb_skip:

    cmp ax, 0x0029      ; 1 make
    jne .nkjm_skip
    mov bl, 0x0f
    or bh, 0x01
    jmp .done
.nkjm_skip:

    cmp ax, 0x8029      ; 1 make    漢字キーはbreakは取れない
    jne .skjb_skip
    mov bl, 0x0f        ; 対応コードがないのでsiにマップ
    jmp .done
.skjb_skip:

    cmp ax, 0x8029      ; 1 make
    jne .skjm_skip
    mov bl, 0x0f
    or bh, 0x01
    jmp .done
.skjm_skip:

    ;--------------------------------
;>  ; tab
    ;--------------------------------
    cmp ax, 0x008F      ; 1 break
    jne .ntbb_skip
    mov bl, 0x09
    mov ah, bh
    and ah, 0xe0
    cmp ah, 0x00
    jne .done
    and bh, 0xfe
    jmp .done
.ntbb_skip:

    cmp ax, 0x000f      ; 1 make
    jne .ntbm_skip
    mov bl, 0x09
    or bh, 0x01
    jmp .done
.ntbm_skip:

    ;--------------------------------
;>  ; tab
    ;--------------------------------
    cmp ax, 0x808f      ; 1 break
    jne .stbb_skip
    mov bl, 0x09
    jmp .done
.stbb_skip:

    cmp ax, 0x800f      ; 1 make
    jne .stbm_skip
    mov bl, 0x09
    or bh, 0x01
    jmp .done
.stbm_skip:

    ;--------------------------------
;>  ; q
    ;--------------------------------
    cmp ax, 0x0090      ; 1 break
    jne .nqb_skip
    mov bl, 'q'
    mov ah, bh
    and ah, 0xe0
    cmp ah, 0x00
    jne .done
    and bh, 0xfe
    jmp .done
.nqb_skip:

    cmp ax, 0x0010      ; 1 make
    jne .nqm_skip
    mov bl, 'q'
    or bh, 0x01
    jmp .done
.nqm_skip:

    ;--------------------------------
;>  ; Q
    ;--------------------------------
    cmp ax, 0x8090      ; 1 break
    jne .sqb_skip
    mov bl, 'Q'
    jmp .done
.sqb_skip:

    cmp ax, 0x8010      ; 1 make
    jne .sqm_skip
    mov bl, 'Q'
    or bh, 0x01
    jmp .done
.sqm_skip:

    ;--------------------------------
;>  ; w
    ;--------------------------------
    cmp ax, 0x0091      ; 1 break
    jne .nwb_skip
    mov bl, 'w'
    mov ah, bh
    and ah, 0xe0
    cmp ah, 0x00
    jne .done
    and bh, 0xfe
    jmp .done
.nwb_skip:

    cmp ax, 0x0011      ; 1 make
    jne .nwm_skip
    mov bl, 'w'
    or bh, 0x01
    jmp .done
.nwm_skip:

    ;--------------------------------
;>  ; W
    ;--------------------------------
    cmp ax, 0x8091      ; 1 break
    jne .swb_skip
    mov bl, 'W'
    jmp .done
.swb_skip:

    cmp ax, 0x8011      ; 1 make
    jne .swm_skip
    mov bl, 'W'
    or bh, 0x01
    jmp .done
.swm_skip:

    ;--------------------------------
;>  ; e
    ;--------------------------------
    cmp ax, 0x0092      ; 1 break
    jne .neb_skip
    mov bl, 'e'
    mov ah, bh
    and ah, 0xe0
    cmp ah, 0x00
    jne .done
    and bh, 0xfe
    jmp .done
.neb_skip:

    cmp ax, 0x0012      ; 1 make
    jne .nem_skip
    mov bl, 'e'
    or bh, 0x01
    jmp .done
.nem_skip:

    ;--------------------------------
;>  ; E
    ;--------------------------------
    cmp ax, 0x8092      ; 1 break
    jne .seb_skip
    mov bl, 'E'
    jmp .done
.seb_skip:

    cmp ax, 0x8012      ; 1 make
    jne .sem_skip
    mov bl, 'E'
    or bh, 0x01
    jmp .done
.sem_skip:

    ;--------------------------------
;>  ; r
    ;--------------------------------
    cmp ax, 0x0093      ; 1 break
    jne .nrb_skip
    mov bl, 'r'
    mov ah, bh
    and ah, 0xe0
    cmp ah, 0x00
    jne .done
    and bh, 0xfe
    jmp .done
.nrb_skip:

    cmp ax, 0x0013      ; 1 make
    jne .nrm_skip
    mov bl, 'r'
    or bh, 0x01
    jmp .done
.nrm_skip:

    ;--------------------------------
;>  ; R
    ;--------------------------------
    cmp ax, 0x8093      ; 1 break
    jne .srb_skip
    mov bl, 'R'
    jmp .done
.srb_skip:

    cmp ax, 0x8013      ; 1 make
    jne .srm_skip
    mov bl, 'R'
    or bh, 0x01
    jmp .done
.srm_skip:

    ;--------------------------------
;>  ; t
    ;--------------------------------
    cmp ax, 0x0094      ; 1 break
    jne .ntb_skip
    mov bl, 't'
    mov ah, bh
    and ah, 0xe0
    cmp ah, 0x00
    jne .done
    and bh, 0xfe
    jmp .done
.ntb_skip:

    cmp ax, 0x0014      ; 1 make
    jne .ntm_skip
    mov bl, 't'
    or bh, 0x01
    jmp .done
.ntm_skip:

    ;--------------------------------
;>  ; T
    ;--------------------------------
    cmp ax, 0x8094      ; 1 break
    jne .stb_skip
    mov bl, 'T'
    jmp .done
.stb_skip:

    cmp ax, 0x8014      ; 1 make
    jne .stm_skip
    mov bl, 'T'
    or bh, 0x01
    jmp .done
.stm_skip:

    ;--------------------------------
;>  ; y
    ;--------------------------------
    cmp ax, 0x0095      ; 1 break
    jne .nyb_skip
    mov bl, 'y'
    mov ah, bh
    and ah, 0xe0
    cmp ah, 0x00
    jne .done
    and bh, 0xfe
    jmp .done
.nyb_skip:

    cmp ax, 0x0015      ; 1 make
    jne .nym_skip
    mov bl, 'y'
    or bh, 0x01
    jmp .done
.nym_skip:

    ;--------------------------------
;>  ; Y
    ;--------------------------------
    cmp ax, 0x8095      ; 1 break
    jne .syb_skip
    mov bl, 'Y'
    jmp .done
.syb_skip:

    cmp ax, 0x8015      ; 1 make
    jne .sym_skip
    mov bl, 'Y'
    or bh, 0x01
    jmp .done
.sym_skip:

    ;--------------------------------
;>  ; u
    ;--------------------------------
    cmp ax, 0x0096      ; 1 break
    jne .nub_skip
    mov bl, 'u'
    mov ah, bh
    and ah, 0xe0
    cmp ah, 0x00
    jne .done
    and bh, 0xfe
    jmp .done
.nub_skip:

    cmp ax, 0x0016      ; 1 make
    jne .num_skip
    mov bl, 'u'
    or bh, 0x01
    jmp .done
.num_skip:

    ;--------------------------------
;>  ; U
    ;--------------------------------
    cmp ax, 0x8096      ; 1 break
    jne .sub_skip
    mov bl, 'U'
    jmp .done
.sub_skip:

    cmp ax, 0x8016      ; 1 make
    jne .sum_skip
    mov bl, 'U'
    or bh, 0x01
    jmp .done
.sum_skip:

    ;--------------------------------
;>  ; i
    ;--------------------------------
    cmp ax, 0x0097      ; 1 break
    jne .nib_skip
    mov bl, 'i'
    mov ah, bh
    and ah, 0xe0
    cmp ah, 0x00
    jne .done
    and bh, 0xfe
    jmp .done
.nib_skip:

    cmp ax, 0x0017      ; 1 make
    jne .nim_skip
    mov bl, 'i'
    or bh, 0x01
    jmp .done
.nim_skip:

    ;--------------------------------
;>  ; I
    ;--------------------------------
    cmp ax, 0x8097      ; 1 break
    jne .sib_skip
    mov bl, 'I'
    jmp .done
.sib_skip:

    cmp ax, 0x8017      ; 1 make
    jne .sim_skip
    mov bl, 'I'
    or bh, 0x01
    jmp .done
.sim_skip:

    ;--------------------------------
;>  ; o
    ;--------------------------------
    cmp ax, 0x0098      ; 1 break
    jne .nob_skip
    mov bl, 'o'
    mov ah, bh
    and ah, 0xe0
    cmp ah, 0x00
    jne .done
    and bh, 0xfe
    jmp .done
.nob_skip:

    cmp ax, 0x0018      ; 1 make
    jne .nom_skip
    mov bl, 'o'
    or bh, 0x01
    jmp .done
.nom_skip:

    ;--------------------------------
;>  ; O
    ;--------------------------------
    cmp ax, 0x8098      ; 1 break
    jne .sob_skip
    mov bl, 'O'
    jmp .done
.sob_skip:

    cmp ax, 0x8018      ; 1 make
    jne .som_skip
    mov bl, 'O'
    or bh, 0x01
    jmp .done
.som_skip:

    ;--------------------------------
;>  ; p
    ;--------------------------------
    cmp ax, 0x0099      ; 1 break
    jne .npb_skip
    mov bl, 'p'
    mov ah, bh
    and ah, 0xe0
    cmp ah, 0x00
    jne .done
    and bh, 0xfe
    jmp .done
.npb_skip:

    cmp ax, 0x0019      ; 1 make
    jne .npm_skip
    mov bl, 'p'
    or bh, 0x01
    jmp .done
.npm_skip:

    ;--------------------------------
;>  ; P
    ;--------------------------------
    cmp ax, 0x8099      ; 1 break
    jne .spb_skip
    mov bl, 'P'
    jmp .done
.spb_skip:

    cmp ax, 0x8019      ; 1 make
    jne .spm_skip
    mov bl, 'P'
    or bh, 0x01
    jmp .done
.spm_skip:

    ;--------------------------------
;>  ; @
    ;--------------------------------
    cmp ax, 0x009a      ; 1 break
    jne .natb_skip
    mov bl, '@'
    mov ah, bh
    and ah, 0xe0
    cmp ah, 0x00
    jne .done
    and bh, 0xfe
    jmp .done
.natb_skip:

    cmp ax, 0x001a      ; 1 make
    jne .natm_skip
    mov bl, '@'
    or bh, 0x01
    jmp .done
.natm_skip:

    ;--------------------------------
;>  ; `
    ;--------------------------------
    cmp ax, 0x809a      ; 1 break
    jne .satb_skip
    mov bl, '`'
    jmp .done
.satb_skip:

    cmp ax, 0x801a      ; 1 make
    jne .satm_skip
    mov bl, '`'
    or bh, 0x01
    jmp .done
.satm_skip:

    ;--------------------------------
;>  ; [
    ;--------------------------------
    cmp ax, 0x009b      ; 1 break
    jne .nlbb_skip
    mov bl, '['
    mov ah, bh
    and ah, 0xe0
    cmp ah, 0x00
    jne .done
    and bh, 0xfe
    jmp .done
.nlbb_skip:

    cmp ax, 0x001b      ; 1 make
    jne .nlbm_skip
    mov bl, '['
    or bh, 0x01
    jmp .done
.nlbm_skip:

    ;--------------------------------
;>  ; {
    ;--------------------------------
    cmp ax, 0x809b      ; 1 break
    jne .slbb_skip
    mov bl, '{'
    jmp .done
.slbb_skip:

    cmp ax, 0x801b      ; 1 make
    jne .slbm_skip
    mov bl, '{'
    or bh, 0x01
    jmp .done
.slbm_skip:

    ;--------------------------------
;>  ; cr
    ;--------------------------------
    cmp ax, 0x009c      ; 1 break
    jne .ncrb_skip
    mov bl, 0x0d
    mov ah, bh
    and ah, 0xe0
    cmp ah, 0x00
    jne .done
    and bh, 0xfe
    jmp .done
.ncrb_skip:

    cmp ax, 0x001c      ; 1 make
    jne .ncrm_skip
    mov bl, 0x0d
    or bh, 0x01
    jmp .done
.ncrm_skip:

    ;--------------------------------
;>  ; cr
    ;--------------------------------
    cmp ax, 0x809c      ; 1 break
    jne .scrb_skip
    mov bl, 0x0d
    jmp .done
.scrb_skip:

    cmp ax, 0x801c      ; 1 make
    jne .scrm_skip
    mov bl, 0x0d
    or bh, 0x01
    jmp .done
.scrm_skip:

    ;--------------------------------
;>  ; caps lock
    ;--------------------------------
;    cmp ax, 0x009c      ; 1 break
;    jne .ncpb_skip
;    mov bl, 0x00
;    and bh, 0xfe
;    jmp .done
.ncpb_skip:

;    cmp ax, 0x001c      ; 1 make
;    jne .ncpm_skip
;    mov bl, 0x00
;    or bh, 0x01
;    jmp .done
.ncpm_skip:

    ;--------------------------------
;>  ; caps lock
    ;--------------------------------
    cmp ax, 0x80Ba      ; 1 break
    jne .scpb_skip
    mov bl, 0x0e
    and bh, 0xfe
.scpb_skip:

    cmp ax, 0x803a      ; 1 make
    jne .scpm_skip
    mov bl, 0x0e
    or bh, 0x01
    jmp .done
.scpm_skip:

    ;--------------------------------
;>  ; a
    ;--------------------------------
    cmp ax, 0x009e      ; 1 break
    jne .nab_skip
    mov bl, 'a'
    mov ah, bh
    and ah, 0xe0
    cmp ah, 0x00
    jne .done
    and bh, 0xfe
    jmp .done
.nab_skip:

    cmp ax, 0x001e      ; 1 make
    jne .nam_skip
    mov bl, 'a'
    or bh, 0x01
    jmp .done
.nam_skip:

    ;--------------------------------
;>  ; A
    ;--------------------------------
    cmp ax, 0x809e      ; 1 break
    jne .sab_skip
    mov bl, 'A'
    jmp .done
.sab_skip:

    cmp ax, 0x801e      ; 1 make
    jne .sam_skip
    mov bl, 'A'
    or bh, 0x01
    jmp .done
.sam_skip:

    ;--------------------------------
;>  ; s
    ;--------------------------------
    cmp ax, 0x009f      ; 1 break
    jne .nsb_skip
    mov bl, 's'
    mov ah, bh
    and ah, 0xe0
    cmp ah, 0x00
    jne .done
    and bh, 0xfe
    jmp .done
.nsb_skip:

    cmp ax, 0x001f      ; 1 make
    jne .nsm_skip
    mov bl, 's'
    or bh, 0x01
    jmp .done
.nsm_skip:

    ;--------------------------------
;>  ; S
    ;--------------------------------
    cmp ax, 0x809f      ; 1 break
    jne .ssb_skip
    mov bl, 'S'
    jmp .done
.ssb_skip:

    cmp ax, 0x801f      ; 1 make
    jne .ssm_skip
    mov bl, 'S'
    or bh, 0x01
    jmp .done
.ssm_skip:

    ;--------------------------------
;>  ; d
    ;--------------------------------
    cmp ax, 0x0020      ; 1 break
    jne .ndb_skip
    mov bl, 'd'
    mov ah, bh
    and ah, 0xe0
    cmp ah, 0x00
    jne .done
    and bh, 0xfe
    jmp .done
.ndb_skip:

    cmp ax, 0x00a0      ; 1 make
    jne .ndm_skip
    mov bl, 'd'
    or bh, 0x01
    jmp .done
.ndm_skip:

    ;--------------------------------
;>  ; D
    ;--------------------------------
    cmp ax, 0x8020      ; 1 break
    jne .sdb_skip
    mov bl, 'D'
    jmp .done
.sdb_skip:

    cmp ax, 0x80a0      ; 1 make
    jne .sdm_skip
    mov bl, 'D'
    or bh, 0x01
    jmp .done
.sdm_skip:

    ;--------------------------------
;>  ; f
    ;--------------------------------
    cmp ax, 0x0021      ; 1 break
    jne .nfb_skip
    mov bl, 'f'
    mov ah, bh
    and ah, 0xe0
    cmp ah, 0x00
    jne .done
    and bh, 0xfe
    jmp .done
.nfb_skip:

    cmp ax, 0x00a1      ; 1 make
    jne .nfm_skip
    mov bl, 'f'
    or bh, 0x01
    jmp .done
.nfm_skip:

    ;--------------------------------
;>  ; F
    ;--------------------------------
    cmp ax, 0x8021      ; 1 break
    jne .sfb_skip
    mov bl, 'F'
    jmp .done
.sfb_skip:

    cmp ax, 0x80a1      ; 1 make
    jne .sfm_skip
    mov bl, 'F'
    or bh, 0x01
    jmp .done
.sfm_skip:

    ;--------------------------------
;>  ; g
    ;--------------------------------
    cmp ax, 0x0022      ; 1 break
    jne .ngb_skip
    mov bl, 'g'
    mov ah, bh
    and ah, 0xe0
    cmp ah, 0x00
    jne .done
    and bh, 0xfe
    jmp .done
.ngb_skip:

    cmp ax, 0x00a2      ; 1 make
    jne .ngm_skip
    mov bl, 'g'
    or bh, 0x01
    jmp .done
.ngm_skip:

    ;--------------------------------
;>  ; G
    ;--------------------------------
    cmp ax, 0x8022      ; 1 break
    jne .sgb_skip
    mov bl, 'G'
    jmp .done
.sgb_skip:

    cmp ax, 0x80a2      ; 1 make
    jne .sgm_skip
    mov bl, 'G'
    or bh, 0x01
    jmp .done
.sgm_skip:

    ;--------------------------------
;>  ; h
    ;--------------------------------
    cmp ax, 0x0023      ; 1 break
    jne .nhb_skip
    mov bl, 'h'
    mov ah, bh
    and ah, 0xe0
    cmp ah, 0x00
    jne .done
    and bh, 0xfe
    jmp .done
.nhb_skip:

    cmp ax, 0x00a3      ; 1 make
    jne .nhm_skip
    mov bl, 'h'
    or bh, 0x01
    jmp .done
.nhm_skip:

    ;--------------------------------
;>  ; H
    ;--------------------------------
    cmp ax, 0x8023      ; 1 break
    jne .shb_skip
    mov bl, 'H'
    jmp .done
.shb_skip:

    cmp ax, 0x80a3      ; 1 make
    jne .shm_skip
    mov bl, 'H'
    or bh, 0x01
    jmp .done
.shm_skip:

    ;--------------------------------
;>  ; j
    ;--------------------------------
    cmp ax, 0x0024      ; 1 break
    jne .njb_skip
    mov bl, 'j'
    mov ah, bh
    and ah, 0xe0
    cmp ah, 0x00
    jne .done
    and bh, 0xfe
    jmp .done
.njb_skip:

    cmp ax, 0x00a4      ; 1 make
    jne .njm_skip
    mov bl, 'j'
    or bh, 0x01
    jmp .done
.njm_skip:

    ;--------------------------------
;>  ; J
    ;--------------------------------
    cmp ax, 0x8024      ; 1 break
    jne .sjb_skip
    mov bl, 'J'
    jmp .done
.sjb_skip:

    cmp ax, 0x80a4      ; 1 make
    jne .sjm_skip
    mov bl, 'J'
    or bh, 0x01
    jmp .done
.sjm_skip:

    ;--------------------------------
;>  ; k
    ;--------------------------------
    cmp ax, 0x0025      ; 1 break
    jne .nkb_skip
    mov bl, 'k'
    mov ah, bh
    and ah, 0xe0
    cmp ah, 0x00
    jne .done
    and bh, 0xfe
    jmp .done
.nkb_skip:

    cmp ax, 0x00a5      ; 1 make
    jne .nkm_skip
    mov bl, 'k'
    or bh, 0x01
    jmp .done
.nkm_skip:

    ;--------------------------------
;>  ; K
    ;--------------------------------
    cmp ax, 0x8025      ; 1 break
    jne .skb_skip
    mov bl, 'K'
    jmp .done
.skb_skip:

    cmp ax, 0x80a5      ; 1 make
    jne .skm_skip
    mov bl, 'K'
    or bh, 0x01
    jmp .done
.skm_skip:

    ;--------------------------------
;>  ; l
    ;--------------------------------
    cmp ax, 0x0026      ; 1 break
    jne .nlb_skip
    mov bl, 'l'
    mov ah, bh
    and ah, 0xe0
    cmp ah, 0x00
    jne .done
    and bh, 0xfe
    jmp .done
.nlb_skip:

    cmp ax, 0x00a6      ; 1 make
    jne .nlm_skip
    mov bl, 'l'
    or bh, 0x01
    jmp .done
.nlm_skip:

    ;--------------------------------
;>  ; L
    ;--------------------------------
    cmp ax, 0x8026      ; 1 break
    jne .slb_skip
    mov bl, 'L'
    jmp .done
.slb_skip:

    cmp ax, 0x80a6      ; 1 make
    jne .slm_skip
    mov bl, 'L'
    or bh, 0x01
    jmp .done
.slm_skip:

    ;--------------------------------
;>  ; ;
    ;--------------------------------
    cmp ax, 0x0027     ; 1 break
    jne .nscb_skip
    mov bl, ';'
    mov ah, bh
    and ah, 0xe0
    cmp ah, 0x00
    jne .done
    and bh, 0xfe
    jmp .done
.nscb_skip:

    cmp ax, 0x00a7      ; 1 make
    jne .nscm_skip
    mov bl, ';'
    or bh, 0x01
    jmp .done
.nscm_skip:

    ;--------------------------------
;>  ; +
    ;--------------------------------
    cmp ax, 0x8027      ; 1 break
    jne .sscb_skip
    mov bl, '+'
    jmp .done
.sscb_skip:

    cmp ax, 0x80a7      ; 1 make
    jne .sscm_skip
    mov bl, '+'
    or bh, 0x01
    jmp .done
.sscm_skip:

    ;--------------------------------
;>  ; :
    ;--------------------------------
    cmp ax, 0x0028      ; 1 break
    jne .nclb_skip
    mov bl, ':'
    mov ah, bh
    and ah, 0xe0
    cmp ah, 0x00
    jne .done
    and bh, 0xfe
    jmp .done
.nclb_skip:

    cmp ax, 0x00a8      ; 1 make
    jne .nclm_skip
    mov bl, ':'
    or bh, 0x01
    jmp .done
.nclm_skip:

    ;--------------------------------
;>  ; *
    ;--------------------------------
    cmp ax, 0x8028      ; 1 break
    jne .sclb_skip
    mov bl, '*'
    jmp .done
.sclb_skip:

    cmp ax, 0x80a8      ; 1 make
    jne .sclm_skip
    mov bl, '*'
    or bh, 0x01
    jmp .done
.sclm_skip:

    ;--------------------------------
;>  ; ]
    ;--------------------------------
    cmp ax, 0x00ab      ; 1 break
    jne .nrbb_skip
    mov bl, ']'
    mov ah, bh
    and ah, 0xe0
    cmp ah, 0x00
    jne .done
    and bh, 0xfe
    jmp .done
.nrbb_skip:

    cmp ax, 0x002b      ; 1 make
    jne .nrbm_skip
    mov bl, ']'
    or bh, 0x01
    jmp .done
.nrbm_skip:

    ;--------------------------------
;>  ; }
    ;--------------------------------
    cmp ax, 0x80ab      ; 1 break
    jne .srbb_skip
    mov bl, '}'
    jmp .done
.srbb_skip:

    cmp ax, 0x802b      ; 1 make
    jne .srbm_skip
    mov bl, '}'
    or bh, 0x01
    jmp .done
.srbm_skip:

    ;--------------------------------
;>  ; z
    ;--------------------------------
    cmp ax, 0x002c      ; 1 break
    jne .nzb_skip
    mov bl, 'z'
    mov ah, bh
    and ah, 0xe0
    cmp ah, 0x00
    jne .done
    and bh, 0xfe
    jmp .done
.nzb_skip:

    cmp ax, 0x00ac      ; 1 make
    jne .nzm_skip
    mov bl, 'z'
    or bh, 0x01
    jmp .done
.nzm_skip:

    ;--------------------------------
;>  ; Z
    ;--------------------------------
    cmp ax, 0x802c      ; 1 break
    jne .szb_skip
    mov bl, 'Z'
    jmp .done
.szb_skip:

    cmp ax, 0x80ac      ; 1 make
    jne .szm_skip
    mov bl, 'Z'
    or bh, 0x01
    jmp .done
.szm_skip:

    ;--------------------------------
;>  ; x
    ;--------------------------------
    cmp ax, 0x002d      ; 1 break
    jne .nxb_skip
    mov bl, 'x'
    mov ah, bh
    and ah, 0xe0
    cmp ah, 0x00
    jne .done
    and bh, 0xfe
    jmp .done
.nxb_skip:

    cmp ax, 0x00ad      ; 1 make
    jne .nxm_skip
    mov bl, 'x'
    or bh, 0x01
    jmp .done
.nxm_skip:

    ;--------------------------------
;>  ; X
    ;--------------------------------
    cmp ax, 0x802d      ; 1 break
    jne .sxb_skip
    mov bl, 'X'
    jmp .done
.sxb_skip:

    cmp ax, 0x80ad      ; 1 make
    jne .sxm_skip
    mov bl, 'X'
    or bh, 0x01
    jmp .done
.sxm_skip:

    ;--------------------------------
;>  ; c
    ;--------------------------------
    cmp ax, 0x002e      ; 1 break
    jne .ncb_skip
    mov bl, 'c'
    mov ah, bh
    and ah, 0xe0
    cmp ah, 0x00
    jne .done
    and bh, 0xfe
    jmp .done
.ncb_skip:

    cmp ax, 0x00ae      ; 1 make
    jne .ncm_skip
    mov bl, 'c'
    or bh, 0x01
    jmp .done
.ncm_skip:

    ;--------------------------------
;>  ; C
    ;--------------------------------
    cmp ax, 0x802e      ; 1 break
    jne .scb_skip
    mov bl, 'C'
    jmp .done
.scb_skip:

    cmp ax, 0x80ae      ; 1 make
    jne .scm_skip
    mov bl, 'C'
    or bh, 0x01
    jmp .done
.scm_skip:

    ;--------------------------------
;>  ; v
    ;--------------------------------
    cmp ax, 0x002f      ; 1 break
    jne .nvb_skip
    mov bl, 'v'
    mov ah, bh
    and ah, 0xe0
    cmp ah, 0x00
    jne .done
    and bh, 0xfe
    jmp .done
.nvb_skip:

    cmp ax, 0x00af      ; 1 make
    jne .nvm_skip
    mov bl, 'v'
    or bh, 0x01
    jmp .done
.nvm_skip:

    ;--------------------------------
;>  ; V
    ;--------------------------------
    cmp ax, 0x802f      ; 1 break
    jne .svb_skip
    mov bl, 'V'
    jmp .done
.svb_skip:

    cmp ax, 0x80af      ; 1 make
    jne .svm_skip
    mov bl, 'V'
    or bh, 0x01
    jmp .done
.svm_skip:

    ;--------------------------------
;>  ; b
    ;--------------------------------
    cmp ax, 0x0030      ; 1 break
    jne .nbb_skip
    mov bl, 'b'
    mov ah, bh
    and ah, 0xe0
    cmp ah, 0x00
    jne .done
    and bh, 0xfe
    jmp .done
.nbb_skip:

    cmp ax, 0x00b0      ; 1 make
    jne .nbm_skip
    mov bl, 'b'
    or bh, 0x01
    jmp .done
.nbm_skip:

    ;--------------------------------
;>  ; B
    ;--------------------------------
    cmp ax, 0x8030      ; 1 break
    jne .sbb_skip
    mov bl, 'B'
    jmp .done
.sbb_skip:

    cmp ax, 0x80b0      ; 1 make
    jne .sbm_skip
    mov bl, 'B'
    or bh, 0x01
    jmp .done
.sbm_skip:

    ;--------------------------------
;>  ; n
    ;--------------------------------
    cmp ax, 0x0031      ; 1 break
    jne .nnb_skip
    mov bl, 'n'
    mov ah, bh
    and ah, 0xe0
    cmp ah, 0x00
    jne .done
    and bh, 0xfe
    jmp .done
.nnb_skip:

    cmp ax, 0x00b1      ; 1 make
    jne .nnm_skip
    mov bl, 'n'
    or bh, 0x01
    jmp .done
.nnm_skip:

    ;--------------------------------
;>  ; N
    ;--------------------------------
    cmp ax, 0x8031      ; 1 break
    jne .snb_skip
    mov bl, 'N'
    jmp .done
.snb_skip:

    cmp ax, 0x80b1      ; 1 make
    jne .snm_skip
    mov bl, 'N'
    or bh, 0x01
    jmp .done
.snm_skip:

    ;--------------------------------
;>  ; m
    ;--------------------------------
    cmp ax, 0x0032      ; 1 break
    jne .nmb_skip
    mov bl, 'm'
    mov ah, bh
    and ah, 0xe0
    cmp ah, 0x00
    jne .done
    and bh, 0xfe
    jmp .done
.nmb_skip:

    cmp ax, 0x00b2      ; 1 make
    jne .nmm_skip
    mov bl, 'm'
    or bh, 0x01
    jmp .done
.nmm_skip:

    ;--------------------------------
;>  ; M
    ;--------------------------------
    cmp ax, 0x8032      ; 1 break
    jne .smb_skip
    mov bl, 'M'
    jmp .done
.smb_skip:

    cmp ax, 0x80b2      ; 1 make
    jne .smm_skip
    mov bl, 'M'
    or bh, 0x01
    jmp .done
.smm_skip:

    ;--------------------------------
;>  ; ,
    ;--------------------------------
    cmp ax, 0x0033      ; 1 break
    jne .ncnb_skip
    mov bl, ','
    mov ah, bh
    and ah, 0xe0
    cmp ah, 0x00
    jne .done
    and bh, 0xfe
    jmp .done
.ncnb_skip:

    cmp ax, 0x00b3      ; 1 make
    jne .ncnm_skip
    mov bl, ','
    or bh, 0x01
    jmp .done
.ncnm_skip:

    ;--------------------------------
;>  ; <
    ;--------------------------------
    cmp ax, 0x8033      ; 1 break
    jne .scnb_skip
    mov bl, '<'
    jmp .done
.scnb_skip:

    cmp ax, 0x80b3      ; 1 make
    jne .scnm_skip
    mov bl, '<'
    or bh, 0x01
    jmp .done
.scnm_skip:

    ;--------------------------------
;>  ; .
    ;--------------------------------
    cmp ax, 0x0034      ; 1 break
    jne .ncmb_skip
    mov bl, '.'
    mov ah, bh
    and ah, 0xe0
    cmp ah, 0x00
    jne .done
    and bh, 0xfe
    jmp .done
.ncmb_skip:

    cmp ax, 0x00b4      ; 1 make
    jne .ncmm_skip
    mov bl, '.'
    or bh, 0x01
    jmp .done
.ncmm_skip:

    ;--------------------------------
;>  ; >
    ;--------------------------------
    cmp ax, 0x8034      ; 1 break
    jne .scmb_skip
    mov bl, '>'
    jmp .done
.scmb_skip:

    cmp ax, 0x80b4      ; 1 make
    jne .scmm_skip
    mov bl, '>'
    or bh, 0x01
    jmp .done
.scmm_skip:

    ;--------------------------------
;>  ; /
    ;--------------------------------
    cmp ax, 0x0035      ; 1 break
    jne .nslb_skip
    mov bl, '/'
    mov ah, bh
    and ah, 0xe0
    cmp ah, 0x00
    jne .done
    and bh, 0xfe
    jmp .done
.nslb_skip:

    cmp ax, 0x00b5      ; 1 make
    jne .nslm_skip
    mov bl, '/'
    or bh, 0x01
    jmp .done
.nslm_skip:

    ;--------------------------------
;>  ; ?
    ;--------------------------------
    cmp ax, 0x8035      ; 1 break
    jne .sslb_skip
    mov bl, '?'
    jmp .done
.sslb_skip:

    cmp ax, 0x80b5      ; 1 make
    jne .sslm_skip
    mov bl, '?'
    or bh, 0x01
    jmp .done
.sslm_skip:

    ;--------------------------------
;>  ; ↑
    ;--------------------------------
    cmp ax, 0x0048      ; 1 break
    jne .nkub_skip
    mov bl, 0x11
    mov ah, bh
    and ah, 0xe0
    cmp ah, 0x00
    jne .done
    and bh, 0xfe
    jmp .done
.nkub_skip:

    cmp ax, 0x00c8      ; 1 make
    jne .nkum_skip
    mov bl, 0x11
    or bh, 0x01
    jmp .done
.nkum_skip:

    ;--------------------------------
;>  ; ↑
    ;--------------------------------
    cmp ax, 0x8048      ; 1 break
    jne .skub_skip
    mov bl, 0x11
    jmp .done
.skub_skip:

    cmp ax, 0x80c8      ; 1 make
    jne .skum_skip
    mov bl, 0x11
    or bh, 0x01
    jmp .done
.skum_skip:

    ;--------------------------------
;>  ; ↓
    ;--------------------------------
    cmp ax, 0x00d0      ; 1 break
    jne .nkdb_skip
    mov bl, 0x12
    mov ah, bh
    and ah, 0xe0
    cmp ah, 0x00
    jne .done
    and bh, 0xfe
    jmp .done
.nkdb_skip:

    cmp ax, 0x0050      ; 1 make
    jne .nkdm_skip
    mov bl, 0x12
    or bh, 0x01
    jmp .done
.nkdm_skip:

    ;--------------------------------
;>  ; ↓
    ;--------------------------------
    cmp ax, 0x80d0      ; 1 break
    jne .skdb_skip
    mov bl, 0x12
    jmp .done
.skdb_skip:

    cmp ax, 0x8050      ; 1 make
    jne .skdm_skip
    mov bl, 0x12
    or bh, 0x01
    jmp .done
.skdm_skip:

    ;--------------------------------
;>  ; ←
    ;--------------------------------
    cmp ax, 0x00cb      ; 1 break
    jne .nklb_skip
    mov bl, 0x13
    mov ah, bh
    and ah, 0xe0
    cmp ah, 0x00
    jne .done
    and bh, 0xfe
    jmp .done
.nklb_skip:

    cmp ax, 0x004b      ; 1 make
    jne .nklm_skip
    mov bl, 0x13
    or bh, 0x01
    jmp .done
.nklm_skip:

    ;--------------------------------
;>  ; ←
    ;--------------------------------
    cmp ax, 0x80cb      ; 1 break
    jne .sklb_skip
    mov bl, 0x13
    jmp .done
.sklb_skip:

    cmp ax, 0x804b      ; 1 make
    jne .sklm_skip
    mov bl, 0x13
    or bh, 0x01
    jmp .done
.sklm_skip:

    ;--------------------------------
;>  ; →
    ;--------------------------------
    cmp ax, 0x00cd      ; 1 break
    jne .nkrb_skip
    mov bl, 0x14
    mov ah, bh
    and ah, 0xe0
    cmp ah, 0x00
    jne .done
    and bh, 0xfe
    jmp .done
.nkrb_skip:

    cmp ax, 0x004d      ; 1 make
    jne .nkrm_skip
    mov bl, 0x14
    or bh, 0x01
    jmp .done
.nkrm_skip:

    ;--------------------------------
;>  ; →
    ;--------------------------------
    cmp ax, 0x80cd      ; 1 break
    jne .skrb_skip
    mov bl, 0x14
    jmp .done
.skrb_skip:

    cmp ax, 0x804d      ; 1 make
    jne .skrm_skip
    mov bl, 0x14
    or bh, 0x01
    jmp .done
.skrm_skip:

    ;--------------------------------
;>  ; del
    ;--------------------------------
    cmp ax, 0x00d3      ; 1 break
    jne .ndlb_skip
    mov bl, 0x7f
    mov ah, bh
    and ah, 0xe0
    cmp ah, 0x00
    jne .done
    and bh, 0xfe
    jmp .done
.ndlb_skip:

    cmp ax, 0x0053      ; 1 make
    jne .ndlm_skip
    mov bl, 0x7f
    or bh, 0x01
    jmp .done
.ndlm_skip:

    ;--------------------------------
;>  ; del
    ;--------------------------------
    cmp ax, 0x80d3      ; 1 break
    jne .sdlb_skip
    mov bl, 0x7f
    and bh, 0xfe
    jmp .done
.sdlb_skip:

    cmp ax, 0x8053      ; 1 make
    jne .sdlm_skip
    mov bl, 0x7f
    jmp .done
.sdlm_skip:

    ;--------------------------------
;>  ; esc
    ;--------------------------------
    cmp ax, 0x0081      ; 1 break
    jne .nesb_skip
    mov bl, 0x1b
    mov ah, bh
    and ah, 0xe0
    cmp ah, 0x00
    jne .done
    and bh, 0xfe
    jmp .done
.nesb_skip:

    cmp ax, 0x0001      ; 1 make
    jne .nesm_skip
    mov bl, 0x1b
    or bh, 0x01
    jmp .done
.nesm_skip:

    ;--------------------------------
;>  ; esc
    ;--------------------------------
    cmp ax, 0x8081      ; 1 break
    jne .sesb_skip
    mov bl, 0x1b
    jmp .done
.sesb_skip:

    cmp ax, 0x8001      ; 1 make
    jne .sesm_skip
    mov bl, 0x1b
    or bh, 0x01
    jmp .done
.sesm_skip:
    jmp .done

.done:
    mov word [.prev_bx], bx
    
    pop es
    pop ds
    pop ax
    ret

.prev_bx:
.prev_bl db 0
.prev_bh db 0

;>********************************
;> スキャンコードのデコード
;>********************************
; al = スキャンコード → bl = ASCII
;                        bh key condition
scancode_decode2:
    push ax
    push ds
    push es
    
    mov ah, 0

    push bx
    mov bx, cs
    mov ds, bx
    mov es, bx
    pop bx
    

    ; キーコンディションを取得しておく
    ;********************************
    ; スキャンコード    Key Condition
    ;********************************
    ;--------------------------------
;>  ; left shift
    ;--------------------------------
    cmp al, 0x2a        ; left shift down
    jne .ls_skip1       ; 違うなら飛ぶ
    or bh, 0x80         ; Bit 8 を立てる
    mov ch, bh
    and ch, 0x01        ; Bit 1 を調べる
    cmp ch, 0x00        ; 立っていない（何かがすでにKeyUp）
    jne .ls_skip1
    mov bl, 0x00        ; left shift only なのでAsciiをクリア
.ls_skip1:

    cmp al, 0xaa        ; left shift up
    jne .ls_skip2       ; 違うなら飛ぶ
    and bh, 0x7f        ; Bit 8 を寝かす
    mov ch, bh
    and ch, 0x01        ; Bit 1 を調べる
    cmp ch, 0x00        ; 立っていない（何かがすでにKeyUp）
    jne  .ls_skip2
    mov bl, 0x00        ; left shift only なのでAsciiをクリア
.ls_skip2:

    ;--------------------------------
;>  ; right shift
    ;--------------------------------
    cmp al, 0x36        ; right shift down
    jne .rs_skip1       ; 違うなら飛ぶ
    or bh, 0x80         ; Bit 8 を立てる
    mov ch, bh
    and ch, 0x01        ; Bit 1 を調べる
    cmp ch, 0x00        ; 立っていない（何かがすでにKeyUp）
    jne .rs_skip1
    mov bl, 0x00        ; right shift only なのでAsciiをクリア
.rs_skip1:

    cmp al, 0xb6        ; right shift up
    jne .rs_skip2       ; 違うなら飛ぶ
    and bh, 0x7f        ; Bit 8 を寝かす
    mov ch, bh
    and ch, 0x01        ; Bit 1 を調べる
    cmp ch, 0x00        ; 立っていない（何かがすでにKeyUp）
    jne .rs_skip2
    mov bl, 0x00        ; left shift only なのでAsciiをクリア
.rs_skip2:

    ;--------------------------------
;>  ; ctrl
    ;--------------------------------
    cmp al, 0x1d        ; left shift down
    jne .ctrl_skip1    ; 違うなら飛ぶ
    or bh, 0x40         ; Bit 7 を立てる
    mov ch, bh
    and ch, 0x01        ; Bit 1 を調べる
    cmp ch, 0x00        ; 立っていない（何かがすでにKeyUp）
    jne .ctrl_skip1
    mov bl, 0x00        ; left shift only なのでAsciiをクリア
.ctrl_skip1:

    cmp al, 0x9d        ; left shift up
    jne .ctrl_skip2          ; 違うなら飛ぶ
    and bh, 0xbf        ; Bit 7 を寝かす
    mov ch, bh
    and ch, 0x01        ; Bit 1 を調べる
    cmp ch, 0x00        ; 立っていない（何かがすでにKeyUp）
    jne  .ctrl_skip2
    mov bl, 0x00        ; left shift only なのでAsciiをクリア
.ctrl_skip2:

    ;--------------------------------
;>  ; alt
    ;--------------------------------
    cmp al, 0x38        ; left shift down
    jne .alt_skip1      ; 違うなら飛ぶ
    or bh, 0x20         ; Bit 6 を立てる
    mov ch, bh
    and ch, 0x01        ; Bit 1 を調べる
    cmp ch, 0x00        ; 立っていない（何かがすでにKeyUp）
    jne .alt_skip1
    mov bl, 0x00        ; left shift only なのでAsciiをクリア
.alt_skip1:

    cmp al, 0xb8        ; left shift up
    jne .alt_skip2      ; 違うなら飛ぶ
    and bh, 0xdf        ; Bit 6 を寝かす
    mov ch, bh
    and ch, 0x01        ; Bit 1 を調べる
    cmp ch, 0x00        ; 立っていない（何かがすでにKeyUp）
    jne  .alt_skip2
    mov bl, 0x00        ; left shift only なのでAsciiをクリア
.alt_skip2:

    ; テーブルから該当データを探して返す
    mov ah, bh
    and ah, 0x80    ; shiftが押下されているかどうか見る
    mov si, scancode_table
.scan_loop:
    mov word cx, [si]

    cmp ax, cx
    jne .next
    mov word dx, [si + 2]
    or dh, bh
    mov bh, dh
    mov bl, dl


    jmp .exit
.next:
    cmp cx, 0xffff
    je .exit
    add si, 4
    jmp .scan_loop
.exit:


    pop es
    pop ds
    pop ax


    ret

; スキャンコード→ASCII変換テーブル（make/break・shift対応済）
; ax = スキャンコード（高位ビットがシフト）、bl = ASCII, bh = 状態フラグ（bit0 = make）

scancode_table:
    ; Format: dw scancode, ascii+flags
    ; flags: bit0 = make(1)/break(0)

    ; ----------- 数字行（1～0, Shift対応） -----------
    dw 0x0002, '1'+ 256
    dw 0x0082, '1'
    dw 0x8002, '!'+ 256
    dw 0x8082, '!'

    dw 0x0003, '2'+ 256
    dw 0x0083, '2'
    dw 0x8003, '"'+ 256
    dw 0x8083, '"'

    dw 0x0004, '3'+ 256
    dw 0x0084, '3'
    dw 0x8004, '#'+ 256
    dw 0x8084, '#'

    dw 0x0005, '4'+ 256
    dw 0x0085, '4'
    dw 0x8005, '$'+ 256
    dw 0x8085, '$'

    dw 0x0006, '5'+ 256
    dw 0x0086, '5'
    dw 0x8006, '%'+ 256
    dw 0x8086, '%'

    dw 0x0007, '6'+ 256
    dw 0x0087, '6'
    dw 0x8007, '&'+ 256
    dw 0x8087, '&'

    dw 0x0008, '7'+ 256
    dw 0x0088, '7'
    dw 0x8008, '\''+ 256
    dw 0x8088, '\''

    dw 0x0009, '8'+ 256
    dw 0x0089, '8'
    dw 0x8009, '('+ 256
    dw 0x8089, '('

    dw 0x000A, '9'+ 256
    dw 0x008A, '9'
    dw 0x800A, ')'+ 256
    dw 0x808A, ')'

    dw 0x000B, '0'+ 256
    dw 0x008B, '0'
    dw 0x800B, '0'+ 256
    dw 0x808B, '0'

    ; ----------- 記号・句読点 -----------
    dw 0x000C, '-'+ 256
    dw 0x008C, '-'
    dw 0x800C, '=' + 256
    dw 0x808C, '='

    dw 0x000D, '^'+ 256
    dw 0x008D, '^'
    dw 0x800D, '~'+ 256
    dw 0x808D, '~'

    dw 0x00FD, '\\'+ 256
    dw 0x007D, '\\'
    dw 0x80FD, '|'+ 256
    dw 0x807D, '|'

    ; ----------- スペース・制御 -----------
    dw 0x000E, 0x08+ 256
    dw 0x008E, 0x08
    dw 0x800E, 0x08+ 256
    dw 0x808E, 0x08

    dw 0x000F, 0x09+ 256
    dw 0x008F, 0x09
    dw 0x800F, 0x09+ 256
    dw 0x808F, 0x09

    dw 0x001C, 0x0D+ 256
    dw 0x009C, 0x0D
    dw 0x801C, 0x0D+ 256
    dw 0x809C, 0x0D

    dw 0x0053, 0x7F+ 256
    dw 0x00D3, 0x7F
    dw 0x8053, 0x7F+ 256
    dw 0x80D3, 0x7F

    dw 0x0001, 0x1B+ 256
    dw 0x0081, 0x1B
    dw 0x8001, 0x1B+ 256
    dw 0x8081, 0x1B

    ; ----------- アルファベット（a～z, A～Z） -----------
%macro SC_ASC 2
    dw (0x%1), '%2'+ 256
    dw (0x%1+0x80), '%2'
    dw (0x%1+0x8000), '%2'-32+ 256
    dw (0x%1+0x8080), '%2'-32
%endmacro

    SC_ASC 10, q
    SC_ASC 11, w
    SC_ASC 12, e
    SC_ASC 13, r
    SC_ASC 14, t
    SC_ASC 15, y
    SC_ASC 16, u
    SC_ASC 17, i
    SC_ASC 18, o
    SC_ASC 19, p
    SC_ASC 1E, a
    SC_ASC 1F, s
    SC_ASC 20, d
    SC_ASC 21, f
    SC_ASC 22, g
    SC_ASC 23, h
    SC_ASC 24, j
    SC_ASC 25, k
    SC_ASC 26, l
    SC_ASC 2C, z
    SC_ASC 2D, x
    SC_ASC 2E, c
    SC_ASC 2F, v
    SC_ASC 30, b
    SC_ASC 31, n
    SC_ASC 32, m

    ; ----------- 終端 -----------
    dw 0xFFFF, 0xFFFF


