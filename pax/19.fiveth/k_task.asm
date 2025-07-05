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
    
    mov ah, 7
    mov al, 10
    mov bx, ._s_msg
    call disp_strd

    call get_tick
    mov bx, ax
    mov ah, 7
    mov al, 13
    call disp_word_hexd
    
    cli
    mov bx, 0x0000
    mov ax, 0x0000
    call get_key_data
    ;cmp bl, '1'
    ;jne .skip
    ;mov ax, bx
    ;call test_scancode

.skip:
    
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
    call disp_d_task_condition
    
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

test_scancode2:
    push ax
    push bx

    mov al, '1'
    mov ah, 0x00
    mov al, 0x10
    mov bh, 0x00
    mov bl, 0x10
    call scancode_decode
    mov ah, 1
    mov al, 0
    call disp_word_hexd
    
   ; SC_ASC ah, al
   ; mov ah, 1
    ;mov al, 5
    ;call disp_word_hexd

    pop bx
    pop ax

    ret

send_message:
    ; key 2～5を押下するとそれぞれd_task、p_task1、p_task2、p_task3に向けてデータをキューイングする

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

    
    ;mov ah, 7
    ;mov al, 0
    ;mov bx, cx
    ;call disp_word_hexd
    
    ;mov ah, 7
    ;mov al, 5
    ;mov bx, dx
    ;call disp_word_hexd

    jmp ._exit

._full:
    ;mov ah, 8
    ;mov al, 0
    ;mov bx, ._s_no_msg
    ;call disp_strd
    
._exit:
    ret

._s_no_msg db '---- ----', 0x00


disp_p_task1_condition:
    push ax
    push bx
    push cx
    
    call set_own_seg
    
    
    ; p_task1の表示
    mov ah, 7
    mov al, 23
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
    mov ah, 7
    mov al, 27
    call putcd
    mov ah, 77
    mov al, 28
    mov bh, 0x07
    mov bl, ':'
    call putcd

    mov ah, 7
    mov al, 29
    mov bx, dx
    call disp_word_hexd
    mov al, 33
    mov bh, 0x07
    mov bl, ']'
    call putcd

    ;mov ah, 8
    ;mov al, 35
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
    mov ah, 7
    mov al, 35
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
    mov ah, 7
    mov al, 39
    call putcd
    mov ah, 7
    mov al, 40
    mov bh, 0x07
    mov bl, ':'
    call putcd

    mov ah, 7
    mov al, 41
    mov bx, dx
    call disp_word_hexd
    mov al, 45
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
    mov ah, 7
    mov al, 47
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
    mov ah, 7
    mov al, 51
    call putcd
    mov ah, 7
    mov al, 52
    mov bh, 0x07
    mov bl, ':'
    call putcd

    mov ah, 7
    mov al, 53
    mov bx, dx
    call disp_word_hexd
    mov al, 57
    mov bh, 0x07
    mov bl, ']'
    call putcd

    pop cx
    pop bx
    pop ax
    ret

._prev_p3_heartbeat dw 0

._s_msg_p3 db '[p3:', 0x00

; TODO:Locationの設定
disp_d_task_condition:
    push ax
    push bx
    push cx
    
    call set_own_seg
    
    ; d_taskの表示
    mov ah, 7
    mov al, 59
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
    mov ah, 7
    mov al, 63
    call putcd
    mov ah, 7
    mov al, 64
    mov bh, 0x07
    mov bl, ':'
    call putcd

    mov ah, 7
    mov al, 65
    mov bx, dx
    call disp_word_hexd
    mov al, 69
    mov bh, 0x07
    mov bl, ']'
    call putcd

    pop cx
    pop bx
    pop ax
    ret

._prev_p3_heartbeat dw 0

._s_msg_p3 db '[d :', 0x00


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
    mov ah, 7
    mov al, 17
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
scancode_decodeX:
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
scancode_decode:
    push ax
    push ds
    push es
    
    mov ah, 0

    push bx
    mov bx, cs
    mov ds, bx
    mov es, bx
    pop bx

    mov ah, 0

    mov word bx, [.prev_bx]
    mov ah, al
    and ah, 0x80
    cmp ah, 0x00
    je ._skip
    mov ah, bh
    and ah, 0x01
    cmp ah, 0x00
    je ._skip
    and bh, 0xfe
    mov ah, 0x00
._skip:

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

    ;--------------------------------
;>  ; Scroll Lock
    ;--------------------------------
    cmp al, 0x46        ; Scroll Lock Mark
    jne .sl_skip1       ; 違うなら飛ぶ
    or bh, 0x10         ; Bit 5 を立てる
    xor bh, 0x08        ; ビット4を反転させる
    mov ch, bh
    and ch, 0x01        ; Bit 1 を調べる
    cmp ch, 0x01        ; 立っている（何かがすでにMark）
    je .done
    mov bl, 0x00        ; Scroll Lock only なのでAsciiをクリア
    or bh, 0x01         ; Markビットを立てる
    jmp .done
.sl_skip1:

    cmp al, 0xc6        ; Scroll Lock Break
    jne .sl_skip2       ; 違うなら飛ぶ
    and bh, 0xef        ; Bit 5 を寝かす
    mov cx, bx
    and cx, 0xce00      ; Bit 1 を調べる
    cmp cx, 0x0000      ; 立っていない（何かがすでにKeyUp）
    jne  .done
    mov bx, 0x0000      ; Scroll Lock only なのでAsciiをクリア
    jmp .done
.sl_skip2:

    ;--------------------------------
;>  ; Num Lock
    ;--------------------------------
    cmp al, 0x45        ; Num Lock Mark
    jne .nl_skip1       ; 違うなら飛ぶ
    or bh, 0x10         ; Bit 5 を立てる
    xor bh, 0x04        ; ビット3を反転させる
    mov ch, bh
    and ch, 0x01        ; Bit 1 を調べる
    cmp ch, 0x01        ; 立っている（何かがすでにMark）
    je .done
    mov bl, 0x00        ; Num Lock only なのでAsciiをクリア
    or bh, 0x01         ; Markビットを立てる
    jmp .done
.nl_skip1:

    cmp al, 0xc5        ; Num Lock Break
    jne .nl_skip2       ; 違うなら飛ぶ
    and bh, 0xef        ; Bit 5 を寝かす
    mov cx, bx
    and cx, 0xce00      ; Bit 1 を調べる
    cmp cx, 0x0000      ; 立っていない（何かがすでにKeyUp）
    jne  .done
    mov bx, 0x0000      ; Scroll Lock only なのでAsciiをクリア
    jmp .done
.nl_skip2:

    ;--------------------------------
;>  ; Caps Lock
    ;--------------------------------
    mov ch, bh
    and ch, 0x80
    cmp ch, 0x00
    je .cap_skip1
    cmp al, 0x3a
    jne .cap_skip1
    xor bh, 0x02        ; ビット2を反転させる
.cap_skip1:




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
.done:
    mov word [.prev_bx], bx

    pop es
    pop ds
    pop ax

    ret

.prev_bx:
.prev_bl db 0
.prev_bh db 0


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

    dw 0x001a, '@'+ 256
    dw 0x009a, '@'
    dw 0x801a, '`'+ 256
    dw 0x809a, '`'

    dw 0x001b, '['+ 256
    dw 0x009b, '['
    dw 0x801b, '{'+ 256
    dw 0x809b, '{'

    dw 0x0027, ';'+ 256
    dw 0x00a7, ';'
    dw 0x8027, '+'+ 256
    dw 0x80a7, '+'

    dw 0x0028, ':'+ 256
    dw 0x00a8, ':'
    dw 0x8028, '*'+ 256
    dw 0x80a8, '*'

    dw 0x002b, ']'+ 256
    dw 0x00ab, ']'
    dw 0x802b, '}'+ 256
    dw 0x80ab, '}'

    dw 0x0033, ','+ 256
    dw 0x00b3, ','
    dw 0x8033, '<'+ 256
    dw 0x80b3, '<'

    dw 0x0034, '.'+ 256
    dw 0x00b4, '.'
    dw 0x8034, '>'+ 256
    dw 0x80b4, '>'

    dw 0x0035, '/'+ 256
    dw 0x00b5, '/'
    dw 0x8035, '?'+ 256
    dw 0x80b5, '?'

    dw 0x0073, '\\'+ 256
    dw 0x00f3, '\\'
    dw 0x8073, '_'+ 256
    dw 0x80f3, '_'

    ; ----------- スペース・制御 -----------
    dw 0x000E, 0x08+ 256            ; BS
    dw 0x008E, 0x08
    dw 0x800E, 0x08+ 256
    dw 0x808E, 0x08

    dw 0x000F, 0x09+ 256            ; TAB
    dw 0x008F, 0x09
    dw 0x800F, 0x09+ 256
    dw 0x808F, 0x09

    dw 0x001C, 0x0D+ 256            ; CR
    dw 0x009C, 0x0D
    dw 0x801C, 0x0D+ 256
    dw 0x809C, 0x0D

    dw 0x0053, 0x7F+ 256            ; Del
    dw 0x00D3, 0x7F
    dw 0x8053, 0x7F+ 256
    dw 0x80D3, 0x7F

    dw 0x0001, 0x1B+ 256            ; Esc
    dw 0x0081, 0x1B
    dw 0x8001, 0x1B+ 256
    dw 0x8081, 0x1B

    dw 0x0039, 0x20+ 256            ; SP
    dw 0x00b9, 0x20
    dw 0x8039, 0x20+ 256
    dw 0x80b9, 0x20

    dw 0x0048, 0x11+ 256            ; ↑
    dw 0x00c8, 0x11
    dw 0x8048, 0x11+ 256
    dw 0x80c8, 0x11

    dw 0x00d0, 0x12+ 256            ; ↓
    dw 0x0050, 0x12
    dw 0x80d0, 0x12+ 256
    dw 0x8050, 0x12

    dw 0x00cb, 0x13+ 256            ; ←
    dw 0x004b, 0x13
    dw 0x80cb, 0x13+ 256
    dw 0x804b, 0x13

    dw 0x00cd, 0x14+ 256            ; →
    dw 0x004d, 0x14
    dw 0x80cd, 0x14+ 256
    dw 0x804d, 0x14

    dw 0x0029, 0x0f+ 256            ; 漢字
    dw 0x0029, 0x0f
    dw 0x8029, 0x0f+ 256
    dw 0x8029, 0x0f

    ; ----------- アルファベット -----------
    dw 0x0010, 'q'+256
    dw 0x0090, 'q'
    dw 0x8010, 'Q'+256
    dw 0x8090, 'Q'

    dw 0x0011, 'w'+256
    dw 0x0091, 'w'
    dw 0x8011, 'W'+256
    dw 0x8091, 'W'

    dw 0x0012, 'e'+256
    dw 0x0092, 'e'
    dw 0x8012, 'E'+256
    dw 0x8092, 'E'

    dw 0x0013, 'r'+256
    dw 0x0093, 'r'
    dw 0x8013, 'R'+256
    dw 0x8093, 'R'

    dw 0x0014, 't'+256
    dw 0x0094, 't'
    dw 0x8014, 'T'+256
    dw 0x8094, 'T'

    dw 0x0015, 'y'+256
    dw 0x0095, 'y'
    dw 0x8015, 'Y'+256
    dw 0x8095, 'Y'

    dw 0x0016, 'u'+256
    dw 0x0096, 'u'
    dw 0x8016, 'U'+256
    dw 0x8096, 'U'

    dw 0x0017, 'i'+256
    dw 0x0097, 'i'
    dw 0x8017, 'I'+256
    dw 0x8097, 'I'

    dw 0x0018, 'o'+256
    dw 0x0098, 'o'
    dw 0x8018, 'O'+256
    dw 0x8098, 'O'

    dw 0x0019, 'p'+256
    dw 0x0099, 'p'
    dw 0x8019, 'P'+256
    dw 0x8099, 'P'

    dw 0x001E, 'a'+256
    dw 0x009E, 'a'
    dw 0x801E, 'A'+256
    dw 0x809E, 'A'

    dw 0x001F, 's'+256
    dw 0x009F, 's'
    dw 0x801F, 'S'+256
    dw 0x809F, 'S'

    dw 0x0020, 'd'+256
    dw 0x00A0, 'd'
    dw 0x8020, 'D'+256
    dw 0x80A0, 'D'

    dw 0x0021, 'f'+256
    dw 0x00A1, 'f'
    dw 0x8021, 'F'+256
    dw 0x80A1, 'F'

    dw 0x0022, 'g'+256
    dw 0x00A2, 'g'
    dw 0x8022, 'G'+256
    dw 0x80A2, 'G'

    dw 0x0023, 'h'+256
    dw 0x00A3, 'h'
    dw 0x8023, 'H'+256
    dw 0x80A3, 'H'

    dw 0x0024, 'j'+256
    dw 0x00A4, 'j'
    dw 0x8024, 'J'+256
    dw 0x80A4, 'J'

    dw 0x0025, 'k'+256
    dw 0x00A5, 'k'
    dw 0x8025, 'K'+256
    dw 0x80A5, 'K'

    dw 0x0026, 'l'+256
    dw 0x00A6, 'l'
    dw 0x8026, 'L'+256
    dw 0x80A6, 'L'

    dw 0x002C, 'z'+256
    dw 0x00AC, 'z'
    dw 0x802C, 'Z'+256
    dw 0x80AC, 'Z'

    dw 0x002D, 'x'+256
    dw 0x00AD, 'x'
    dw 0x802D, 'X'+256
    dw 0x80AD, 'X'

    dw 0x002E, 'c'+256
    dw 0x00AE, 'c'
    dw 0x802E, 'C'+256
    dw 0x80AE, 'C'

    dw 0x002F, 'v'+256
    dw 0x00AF, 'v'
    dw 0x802F, 'V'+256
    dw 0x80AF, 'V'

    dw 0x0030, 'b'+256
    dw 0x00B0, 'b'
    dw 0x8030, 'B'+256
    dw 0x80B0, 'B'

    dw 0x0031, 'n'+256
    dw 0x00B1, 'n'
    dw 0x8031, 'N'+256
    dw 0x80B1, 'N'

    dw 0x0032, 'm'+256
    dw 0x00B2, 'm'
    dw 0x8032, 'M'+256
    dw 0x80B2, 'M'

    ; ----------- 終端 -----------
    dw 0xFFFF, 0xFFFF


