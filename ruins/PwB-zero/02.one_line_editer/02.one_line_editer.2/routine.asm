;============================
;>  テストコード倉庫
;>===========================
;********************************
; サンプル：エコー
;********************************
exp_echo:

    mov ax, ._title1
    call disp_str
    mov ax, _s_crlf
    call disp_str
    call get_str_ascii
    call disp_nl
    call disp_nl
    mov ax, si
    call disp_str
    call disp_nl
    call disp_nl

    ret

._title1:
    db "*********************************", 0x0d, 0x0a
    db "* Echo" , 0x0d, 0x0a
    db "*********************************", 0x0d, 0x0a
    db "CTRL + Enter -> Power off", 0x0d, 0x0a
    db "Enter any key", 0x0d, 0x0a, 0x00


;********************************
; bin_nibble_hex確認
;********************************
exp_bin_nibble_hex:

    push cx
    push dx

    mov ax, ._s_before
    call disp_str

    mov bx, 10              ; カウンタ
    mov ax, ._s_buf   ; ソース：テストデータ
    call disp_mem

    mov si, ._s_test_data 
    mov di, ._s_buf 
    mov cl, 10

    mov ax, ._s_indata
    call disp_str

    mov bx, 10
    mov ax, ._s_test_data
    call disp_mem


._loop:

    cmp cl, 0
    je ._loop_end
    lodsb
    mov dl, al
    sar al, 4
    call bin_nibble_hex
    mov [di], al
    inc di

    mov al, dl
    and al, 15
    call bin_nibble_hex
    mov [di], al
    inc di
   
    dec cl
    jmp ._loop

._loop_end:

    mov ax, ._s_result
    call disp_str
    mov ax, ._s_test_result
    call disp_str
    call disp_nl
    ;mov bx, 20
    ;call disp_mem


    mov ax, ._s_buf
    mov bx, ._s_test_result
    mov cx, 20
    call cmp_mem
    cmp dl, 0x00
    je ._success
    mov ax, ._s_expect
    call disp_str
    mov ax, ._s_test_result
    call disp_str
    call disp_nl
    mov ax, ._s_fail
    call disp_str
    jmp ._exit

._success:
    mov ax, ._s_expect
    call disp_str
    mov ax, ._s_test_result
    call disp_str
    call disp_nl
    mov ax, ._s_success
    call disp_str
    
._exit:

    pop dx
    pop cx
    ret

; 10ケース
._s_test_data:   db 0x00, 0x09, 0x0a, 0x0f, 0x0A, 0x0F, 0xf0, 0xF9, 0xba, 0xBF, 0x00

._s_test_result: db 0x30, 0x30, 0x30, 0x39, 0x30, 0x41, 0x30, 0x46, 0x30, 0x41, 0x30, 0x46, 0x46, 0x30, 0x46, 0x39, 0x42, 0x41, 0x42, 0x46, 0x00

._s_buf: times 256 db 0x00
._s_test_formed: times 256 db 0x00

._s_fail:       db 'Fail', 0x0d, 0x0a, 0x00
._s_success:    db 'SUCCESS!!', 0x0d, 0x0a, 0x00

._s_result: db 'Exec result : ', 0x0d, 0x0a, 0x00
._s_formed: db 'fomed data  : ', 0x0d, 0x0a, 0x00
._s_expect: db 'Expect is   : ', 0x0d, 0x0a, 0x00
._s_before: db 'Befor exec  : ', 0x0d, 0x0a, 0x00
._s_indata: db 'in data     : ', 0x0d, 0x0a, 0x00

._s_temp: times 10 db 0x00

;********************************
; bin_byte_hex確認
;********************************
exp_bin_byte_hex:

    mov cx, 0x00            ; カウンタ
    mov si, ._s_test_data   ; ソース：テストデータ
    mov di, ._s_buf         ; destination：テストリザルト

    mov ax, ._s_before
    call disp_str
    mov ax, ._s_buf
    mov bx, 15
    call disp_mem

    mov cx, 10 
    mov si, ._s_buf

._before_loop:

    cmp bx, cx
    jge ._before_loop_end
    lodsb
    call disp_byte_hex

    int 0x10
    inc bx
    jmp ._before_loop

._before_loop_end:

    mov ax, ._s_indata
    call disp_str

    mov ax, ._s_test_data
    mov bx, 15
    call disp_mem

    mov si, ._s_test_data
    mov di, ._s_buf
    mov cx, 30

._loop:

    cmp cx, 0
    je ._loop_end
    lodsb                   ; テストデータ読み込み
    call bin_byte_hex
    
    mov byte [di], bh
    inc di
    mov byte [di], bl
    inc di
    dec cx

    jmp ._loop

._loop_end:

    mov cx, 0x0000

    mov ax, ._s_result
    call disp_str
    mov ax, ._s_buf
    call disp_str
    ;call disp_nl

    mov ax, ._s_buf
    mov bx, 30
    ;call disp_mem

    mov ax, ._s_buf
    mov bx, ._s_test_result
    mov dx, 30
    call cmp_mem
    cmp dl, 0
    call disp_nl
    je ._success 

    mov ax, ._s_expect
    call disp_str
    mov ax, ._s_test_result
    mov bx, 30

    call disp_str
    ;call disp_mem
    call disp_nl
    mov ax, ._s_fail
    call disp_str
    jmp ._exit

._success:

    mov ax, ._s_expect
    call disp_str
    mov ax, ._s_buf
    mov bx, 30

    call disp_str
    ;call disp_mem
    call disp_nl
    mov ax, ._s_success
    call disp_str
    
._exit:


    ret

; 15ケース
._s_test_data:   db 0x00,       0x09,       0x0a,       0x0f,       0x0A,       0x0F
                 db 0x00,       0x90,       0xa0,       0xf0,       0xA0,       0xF0
                 db 0xf0,       0xF9,       0xba,       0xBF, 0x00

._s_test_result: db 0x30, 0x30, 0x30, 0x39, 0x30, 0x41, 0x30, 0x46, 0x30, 0x41, 0x30, 0x46
                 db 0x30, 0x30, 0x39, 0x30, 0x41, 0x30, 0x46, 0x30, 0x41, 0x30, 0x46, 0x30
                 db 0x46, 0x30, 0x46, 0x39, 0x42, 0x41, 0x42, 0x46, 0x00

._s_buf: times 256 db 0x00
._s_test_formed: times 256 db 0x00

._s_fail:       db 'Fail', 0x0d, 0x0a, 0x00
._s_success:    db 'SUCCESS!!', 0x0d, 0x0a, 0x00

._s_result: db 'Exec result : ', 0x0d, 0x0a, 0x00
._s_formed: db 'fomed data  : ', 0x0d, 0x0a, 0x00
._s_expect: db 'Expect is   : ', 0x0d, 0x0a, 0x00
._s_before: db 'Befor exec  : ', 0x0d, 0x0a, 0x00
._s_indata: db 'in data     : ', 0x0d, 0x0a, 0x00

;********************************
; bin_strm_hex確認
;********************************
exp_bin_strm_hex:

    mov cx, 0x00            ; 変換数
    mov si, ._s_test_data1  ; ソース：テストデータ
    mov di, ._s_buf         ; destination：テストリザルト

    mov ax, ._s_before1
    call disp_str
    mov ax, ._s_buf
    mov bx, 8
    ;call disp_str
    call disp_mem
    call disp_nl

    ; テスト1
    mov ax, ._s_test_data1
    mov bx, ._s_buf
    mov cx, 4
    call bin_strm_hex
    
    mov ax, ._s_result1
    call disp_str
    mov ax, ._s_buf
    ;call disp_str
    mov bx, 8
    call disp_mem
    call disp_nl

    mov ax, ._s_buf
    mov bx, ._s_test_result1
    mov cx, 8
    call cmp_mem

    cmp dl, 0x00
    je ._success1

    mov ax, ._s_expect1
    call disp_str
    mov ax, ._s_test_result1
    mov bx, 8
    call disp_mem
    call disp_nl

    mov ax, ._s_fail
    call disp_str


._case2:
    call disp_nl

    ; テスト2
    mov ax, ._s_before2
    call disp_str
    mov ax, ._s_buf2
    mov bx, 10
    call disp_mem
    call disp_nl

    mov ax, ._s_indata2
    call disp_str
    mov ax, ._s_test_data2
    mov bx, 5
    call disp_mem
    call disp_nl

    mov ax, ._s_result2
    call disp_str
    mov ax, ._s_test_data2
    mov bx, ._s_buf2
    mov cx, 5
    call bin_strm_hex
    
    mov ax, ._s_buf2
    mov bx, 10
    call disp_mem
    ;call disp_str
    call disp_nl
    mov ax, ._s_buf2
    mov bx, ._s_test_result2
    mov cx, 1
    call cmp_mem
    cmp dl, 0x00
    je ._success2
    mov ax, ._s_expect2
    mov bx, 10
    ;call disp_mem
    call disp_str
    mov ax, ._s_test_result2
    mov bx, 10
    call disp_mem
    ;call disp_str
    call disp_nl
    mov ax, ._s_fail
    call disp_str
    jmp ._exit

._success1:
    mov ax, ._s_expect1
    call disp_str
    mov ax, ._s_buf
    mov bx, 8
    call disp_mem
    call disp_nl
    mov ax, ._s_success
    call disp_str
    jmp ._case2
    
._success2:
    mov ax, ._s_expect2
    call disp_str
    mov ax, ._s_test_result2
    mov bx, 10
    call disp_mem
    ;call disp_str
    ;call disp_nl
    call disp_nl
    mov ax, ._s_success
    call disp_str
    
._exit:

    ret

; 4ケース
._s_test_data1:   db 0xf0, 0xF9, 0xba, 0xBF, 0x00

._s_test_result1: db 0x46, 0x30, 0x46, 0x39, 0x42, 0x41, 0x42, 0x46, 0x00


; 5ケース
._s_test_data2:   db 0xf0, 0xF9, 0xba, 0x0A, 0x9F, 0x00

._s_test_result2: db 0x46, 0x30, 0x46, 0x39, 0x42, 0x41, 0x30, 0x41, 0x39, 0x46,  0x00
                 
._s_buf: times 256 db 0x00
._s_buf2: times 256 db 0x00


._s_fail:       db 'Fail', 0x0d, 0x0a, 0x00

._s_success:    db 'SUCCESS!!', 0x0d, 0x0a, 0x00


._s_result1: db 'Exec result 1 : ', 0x0d, 0x0a, 0x00
._s_result2: db 'Exec result 2 : ', 0x0d, 0x0a, 0x00
._s_expect1: db 'Expect is  1 : ', 0x0d, 0x0a, 0x00
._s_expect2: db 'Expect is  2 : ', 0x0d, 0x0a, 0x00
._s_before1: db 'Befor exec 1 : ', 0x0d, 0x0a, 0x00
._s_before2: db 'Befor exec 2 : ', 0x0d, 0x0a, 0x00
._s_indata1: db 'in data 1    : ', 0x0d, 0x0a, 0x00
._s_indata2: db 'in data 2    : ', 0x0d, 0x0a, 0x00

;********************************
;set_memの確認
;********************************
exp_set_mem:
 
    push ax
    push cx

    mov dx, cx

    mov ax, ._s_src
    call disp_str
    mov ax, ._s_buf_from
    mov bx, ._w_disp_size
    call disp_mem
    call disp_nl
    
    mov ax, ._s_dst_before
    call disp_str
    mov ax, ._s_buf_to
    mov bx, ._w_disp_size
    call disp_mem
    call disp_nl
    
    mov ax, ._s_buf_from
    mov bx, ._s_buf_to
    mov cx, ._w_area_size
    call set_mem
    call disp_str

    mov ax, ._s_dst_after
    call disp_str
    mov ax, ._s_buf_to
    mov bx, ._w_disp_size
    call disp_mem
    call disp_nl

    mov ax, ._s_buf_to
    mov bx, ._s_buf_from
    mov cx, dx
    call cmp_mem
    or dl, dl
    jne ._fail
    mov ax, ._s_success
    jmp ._exit

._fail:
    mov ax, ._s_fail


._exit:
    call disp_str
    call disp_nl
;mov ax, dx
;call disp_word_hex

    pop cx
    pop ax

    ret

._w_area_size equ 4
._w_disp_size equ ._w_area_size + 2

._s_buf_from: times 32 db 0x00
._s_buf_to: times 32 db 0xff 

._s_src: db 'source : ', 0x0d, 0x0a, 0x00
._s_dst_before: db 'destination befor : ', 0x0d, 0x0a, 0x00
._s_dst_after: db 'destination after : ', 0x0d, 0x0a, 0x00

._s_success: db 'SUCCESS!! (^^)b', 0x0d, 0x0a, 0x00
._s_fail: db 'fail (T_T)', 0x0d, 0x0a, 0x00

;********************************
; fill_memの確認
;********************************
exp_fill_mem:

    mov ax, ._s_before
    call disp_str
    mov ax, ._s_buf
    call disp_str
    call disp_nl
    call disp_nl
    mov bx, ._w_size
    call disp_mem
    call disp_nl

    mov ax, ._s_buf
    mov bx, 0x00
    mov cx, ._w_size
    call fill_mem

    mov ax, ._s_after
    call disp_str
    mov ax, ._s_buf
    call disp_str
    call disp_nl
    mov bx, ._w_size
    call disp_mem
    call disp_nl

    mov ax, ._s_expect
    call disp_str
    mov ax, ._s_buf_expect
    call disp_str
    call disp_nl
    mov bx, ._w_size
    call disp_mem
    call disp_nl

    mov ax, ._s_buf
    mov bx, ._s_buf_expect
    mov cx, ._w_size
    call cmp_mem
    or dl, dl
    jne ._fail

    mov ax, ._s_success
    jmp ._exit

._fail:
    mov ax, ._s_fail

._exit:
    call disp_str

ret


._w_size equ 32

._s_buf: db 'abcd', 0x00
   times ._w_size - 5 db 0xFF

._s_buf_expect: times ._w_size db 0x00

._s_before: db 'befor : ', 0x0d, 0x0a, 0x00
._s_after:  db 'after : ', 0x0d, 0x0a, 0x00
._s_expect  db 'expect : ', 0x0d, 0x0a, 0x00

._s_success: db 'SUCCESS!! (^^)b', 0x0d, 0x0a, 0x00
._s_fail: db 'fail (T_T)', 0x0d, 0x0a, 0x00

;********************************
; 
; 
;********************************
exp_disp_word_hex:

   mov ax, ._s_param_hdr
   call disp_str

   mov ax, ._s_param_data
   call disp_str

   mov ax, ._s_return_hdr
   call disp_str

   mov ax, ._w_data
   call disp_word_hex

    ret

._s_param_hdr:  db 'parameter is : ', 0x00
._s_return_hdr: db 'return    is : 0x', 0x00
._s_param_data: db '0x1234', 0x0d, 0x0a, 0x00

._w_data equ 0x1234


;********************************
;get_memの確認
;********************************
exp_get_mem:

    push ax
    push cx

    mov dx, cx

    mov ax, ._s_src
    call disp_str
    mov ax, ._s_buf_from
    mov bx, ._w_disp_size
    call disp_mem
    call disp_nl

    mov ax, ._s_dst_before
    call disp_str
    mov ax, ._s_buf_to
    mov bx, ._w_disp_size
    call disp_mem
    call disp_nl

    mov ax, ._s_buf_from
    mov bx, ._s_buf_to
    mov cx, ._w_area_size
    call get_mem
    call disp_str

    mov ax, ._s_dst_after
    call disp_str
    mov ax, ._s_buf_to
    mov bx, ._w_disp_size
    call disp_mem
    call disp_nl

    mov ax, ._s_buf_to
    mov bx, ._s_buf_from
    mov cx, dx
    call cmp_mem
    or dl, dl
    jne ._fail
    mov ax, ._s_success
    jmp ._exit

._fail:
    mov ax, ._s_fail


._exit:
    call disp_str
    call disp_nl


    pop cx
    pop ax

    ret

._w_area_size equ 32
._w_disp_size equ ._w_area_size + 2

._s_buf_from: times 32 db 0x00
._s_buf_to: times 32 db 0xff

._s_src: db 'source : ', 0x0d, 0x0a, 0x00
._s_dst_before: db 'destination befor : ', 0x0d, 0x0a, 0x00
._s_dst_after: db 'destination after : ', 0x0d, 0x0a, 0x00

._s_success: db 'SUCCESS!! (^^)b', 0x0d, 0x0a, 0x00
._s_fail: db 'fail (T_T)', 0x0d, 0x0a, 0x00


;********************************
; copy_memの確認
;********************************
exp_copy_mem:

    push ax
    push cx

    mov dx, cx

    mov ax, ._s_src
    call disp_str
    mov ax, ._s_buf_from
    mov bx, ._w_disp_size
    call disp_mem
    call disp_nl

    mov ax, ._s_dst_before
    call disp_str
    mov ax, ._s_buf_to
    mov bx, ._w_disp_size
    call disp_mem
    call disp_nl

    mov ax, ._s_buf_from
    mov bx, ._s_buf_to
    mov cx, ._w_area_size
    call copy_mem
    call disp_str

    mov ax, ._s_dst_after
    call disp_str
    mov ax, ._s_buf_to
    mov bx, ._w_disp_size
    call disp_mem
    call disp_nl

    mov ax, ._s_buf_to
    mov bx, ._s_buf_from
    mov cx, dx
    call cmp_mem
    or dl, dl
    jne ._fail
    mov ax, ._s_success
    jmp ._exit

._fail:
    mov ax, ._s_fail


._exit:
    call disp_str
    call disp_nl


    pop cx
    pop ax

    ret

._w_area_size equ 32
._w_disp_size equ ._w_area_size + 2

._s_buf_from: times 32 db 0x00
._s_buf_to: times 32 db 0xff

._s_src: db 'source : ', 0x0d, 0x0a, 0x00
._s_dst_before: db 'destination befor : ', 0x0d, 0x0a, 0x00
._s_dst_after: db 'destination after : ', 0x0d, 0x0a, 0x00

._s_success: db 'SUCCESS!! (^^)b', 0x0d, 0x0a, 0x00
._s_fail: db 'fail (T_T)', 0x0d, 0x0a, 0x00

;********************************
; copy_memの確認
;********************************
exp_bin_byte_ascii:

    mov si, ._s_test_data
    mov di, ._s_buf
    mov cx, ._w_cnt

    mov ax, ._s_hdr_in
    call disp_str
    mov ax, ._s_test_data
    mov bx, 8 
    call disp_mem

    mov ax, ._s_hdr_exp
    call disp_str
    mov ax, ._s_expect
    mov bx, 8
    call disp_mem

    mov cx, 6

._loop:
    or cx, cx
    je ._loop_end

    mov al, [si]
    call bin_byte_ascii
    mov [di], al
    inc si
    inc di
    dec cx
    jmp ._loop 

    mov ax, ._s_buf
    mov bx, ._s_expect
    mov cx, 8
    call cmp_mem
    or al, al
    jne ._fail
    mov ax, ._s_success
    jmp ._exit

._loop_end:
    mov cx, ._s_success
    jmp ._exit

._fail:
    mov cx, ._s_fail
    jmp ._exit


._exit:
    mov ax, ._s_hdr_ret
    call disp_str
    mov ax, ._s_buf
    mov bx, 8
    call disp_mem

    mov ax, cx
    call disp_str

    ret

._s_test_data: db 0x00, 0x1f, 0x20, 0x7e, 0x7f, 0xff
._s_buf: times 128 db 0x00
._s_expect: db 0x2e, 0x2e, 0x20, 0x7e, 0x2e, 0x2e
._w_cnt: db 0x06
._s_success: db 'SUCCESS!! (^^)b', 0x0d, 0x0a, 0x00
._s_fail: db 'fail (T_T)', 0x0d, 0x0a, 0x00

._s_hdr_in:  db 'indata : ', 0x00
._s_hdr_ret: db 'return : ', 0x00
._s_hdr_exp: db 'expect : ', 0x00


;********************************
; 確認用
;********************************
exp_bin_strm_ascii:

    mov ax, ._s_hdr_in
    call disp_str
    mov ax, ._s_test_data
    mov bx, ._w_cnt
    call disp_mem
    call disp_nl

    mov ax, ._s_hdr_exp
    call disp_str
    mov ax, ._s_expect
    mov bx, ._w_cnt
    call disp_mem
    call disp_nl

    mov ax, ._s_test_data
    mov bx, ._s_buf
    mov cx, ._w_cnt
    call bin_strm_ascii

    mov ax, ._s_expect
    mov cx, ._w_cnt
    call cmp_mem
    or dl, 0x00
    jne ._fail
    mov cx, ._s_success
    jmp ._exit

._fail:
    mov cx, ._s_fail

._exit:
    mov ax, ._s_hdr_ret
    call disp_str
    mov ax, ._s_buf
    mov bx, ._w_cnt
    call disp_mem
    call disp_nl

    mov ax, cx
    call disp_str

    ret

._s_test_data: db 0x00, 0x1f, 0x20, 0x7e, 0x7f, 0xff
._s_buf: times 128 db 0x00
._s_expect: db 0x2e, 0x2e, 0x20, 0x7e, 0x2e, 0x2e

._w_cnt: db 0x06
._s_success: db 'SUCCESS!! (^^)b', 0x0d, 0x0a, 0x00
._s_fail: db 'fail (T_T)', 0x0d, 0x0a, 0x00

._s_hdr_in:  db 'indata : ', 0x00
._s_hdr_ret: db 'return : ', 0x00
._s_hdr_exp: db 'expect : ', 0x00

;********************************
; 確認用
;********************************
exp_bin_word_hex:

    mov ax, ._s_hdr_in
    call disp_str
    mov bx, ._s_test_data
    mov al, bh
    call disp_byte_hex
    mov al, bl
    call disp_byte_hex

    mov ax, ._s_hdr_exp
    call disp_str
    mov ax, ._s_expect
    call disp_str
    call disp_nl

    mov ax, ._s_test_data
    mov bx, ._s_buf
;    call bin_word_hex
    call bin_strm_hex
    mov ax, ._s_expect
    call cmp_mem
    or dl, 0x00
    jne ._fail
    mov cx, ._s_success
    jmp ._exit

._fail:
    mov cx, ._s_fail

._exit:
    mov ax, ._s_hdr_ret
    call disp_str
    mov ax, ._s_buf
    call disp_str
    call disp_nl

    mov ax, cx
    call disp_str

    ret

._s_test_data: dw 0x1234
._s_buf: times 128 db 0x00
._s_expect: db 0x31, 0x32, 0x33, 0x34, 0x00

._w_cnt: db 0x04
._s_success: db 'SUCCESS!! (^^)b', 0x0d, 0x0a, 0x00
._s_fail: db 'fail (T_T)', 0x0d, 0x0a, 0x00

._s_hdr_in:  db 'indata : ', 0x00
._s_hdr_ret: db 'return : ', 0x00
._s_hdr_exp: db 'expect : ', 0x00

;********************************
; 読み込み確認
;********************************
exp_test_read_disk:

    ; Befor Area1

    mov ax, ._s_hdr_addr
    call disp_str

    mov ax, ._w_area1_addr
    call disp_word_hex
    call disp_nl

    mov ax, ._s_hdr_before_mem
    call disp_str

    mov ax, ._w_area1_addr
    mov bx, ._w_msg_size
    call disp_mem

    mov ax, ._s_hdr_before_msg
    call disp_str

    mov ax, ._w_area1_addr
    call disp_str
    call disp_nl

    ; Befor Area2

    mov ax, ._s_hdr_addr
    call disp_str

    mov ax, ._w_area2_addr
    call disp_word_hex
    call disp_nl

    mov ax, ._s_hdr_before_mem
    call disp_str

    mov ax, ._w_area2_addr
    mov bx, ._w_msg_size
    call disp_mem

    mov ax, ._s_hdr_before_msg
    call disp_str

    mov ax, ._w_area2_addr
    call disp_str
    call disp_nl

    ; Befor Area3

    mov ax, ._s_hdr_addr
    call disp_str

    mov ax, ._w_area3_addr
    call disp_word_hex
    call disp_nl

    mov ax, ._s_hdr_before_mem
    call disp_str

    mov ax, ._w_area3_addr
    mov bx, ._w_msg_size
    call disp_mem

    mov ax, ._s_hdr_before_msg
    call disp_str

    mov ax, ._w_area3_addr
    call disp_str
    call disp_nl

    ; Disk write

    mov ax, _c_seg         ; セグメント
    mov bx, ._w_area1_addr ; アドレス
    mov ch, 0x80           ; ドライブ番号
    mov cl, ._read_sector1 ; セクタ番号
    mov dh, 0x4            ; セクタ数
    call read_disk

    mov ax, ._s_hdr_addr
    call disp_str

    mov ax, ._w_area1_addr
    call disp_word_hex
    call disp_nl

    mov ax, ._s_hdr_after_mem
    call disp_str

    mov ax, ._w_area1_addr
    mov bx, ._w_msg_size
    call disp_mem

    mov ax, ._s_hdr_after_msg
    call disp_str

    mov ax, ._w_area1_addr
    call disp_str

    mov ax, ._s_hdr_addr
    call disp_str

    mov ax, ._w_area2_addr
    call disp_word_hex
    call disp_nl

    mov ax, ._s_hdr_after_mem
    call disp_str

    mov ax, ._w_area2_addr
    mov bx, ._w_msg_size
    call disp_mem

    mov ax, ._s_hdr_after_msg
    call disp_str

    mov ax, ._w_area2_addr
    call disp_str

    mov ax, ._s_hdr_addr
    call disp_str

    mov ax, ._w_area3_addr
    call disp_word_hex
    call disp_nl

    mov ax, ._s_hdr_after_mem
    call disp_str

    mov ax, ._w_area3_addr
    mov bx, ._w_msg_size
    call disp_mem

    mov ax, ._s_hdr_after_msg
    call disp_str

    mov ax, ._w_area3_addr
    call disp_str
    call disp_nl
;mov ax, ._w_area1_addr
;mov bx, 64
;call disp_mem
;mov ax, ._w_area2_addr
;mov bx, 64
;call disp_mem
;mov ax, ._w_area3_addr
;mov bx, 64
;call disp_mem
    ret

._w_base_addr equ 0x4600

._w_area1_addr equ ._w_base_addr
._w_area2_addr equ ._w_base_addr + 0x200
._w_area3_addr equ ._w_base_addr + 0x400

._read_sector1 equ 0x21
._read_sector2 equ 0x0e
._read_sector3 equ 0x10

._w_msg_size equ 20



._s_hdr_addr :       db 'address   : ', 0x00
._s_hdr_before_mem : db 'befor mem : ', 0x00
._s_hdr_before_msg : db 'befor msg : ', 0x00
._s_hdr_after_mem :  db 'after mem : ', 0x00
._s_hdr_after_msg :  db 'after msg : ', 0x00

._s_msg1:
    db 'All out!', 0x0d, 0x0a, 0
    times 50 db 0x00
._s_msg2:
    db 'Pull the throttie!', 0x0d, 0x0a, 0
    times 50 db 0x00
._s_msg3:
    db "All right Let's Go!", 0x0d, 0x0a, 0
    times 50 db 0x00



;********************************
; 書き込み確認
;********************************
exp_test_write_disk:
    ; Befor Area1

    mov ax, ._s_hdr_addr
    call disp_str

    mov ax, ._w_area1_addr
    call disp_word_hex
    call disp_nl

    mov ax, ._s_hdr_before_mem
    call disp_str

    mov ax, ._w_area1_addr
    mov bx, ._w_msg_size
    call disp_mem

    mov ax, ._s_hdr_before_msg
    call disp_str

    mov ax, ._w_area1_addr
    call disp_str

    ; Befor Area2

    mov ax, ._s_hdr_addr
    call disp_str

    mov ax, ._w_area2_addr
    call disp_word_hex
    call disp_nl

    mov ax, ._s_hdr_before_mem
    call disp_str

    mov ax, ._w_area2_addr
    mov bx, ._w_msg_size
    call disp_mem

    mov ax, ._s_hdr_before_msg
    call disp_str

    mov ax, ._w_area2_addr
    call disp_str

    ; Befor Area3

    mov ax, ._s_hdr_addr
    call disp_str

    mov ax, ._w_area3_addr
    call disp_word_hex
    call disp_nl

    mov ax, ._s_hdr_before_mem
    call disp_str

    mov ax, ._w_area3_addr
    mov bx, ._w_msg_size
    call disp_mem

    mov ax, ._s_hdr_before_msg
    call disp_str

    mov ax, ._w_area3_addr
    call disp_str
    call disp_nl


    ; データの設定

    mov ax, ._s_msg1
    mov bx, ._w_area1_addr
    mov cx, ._w_msg_size 
    call set_mem

    mov ax, ._s_msg2
    mov bx, ._w_area2_addr
    mov cx, ._w_msg_size 
    call set_mem

    mov ax, ._s_msg3
    mov bx, ._w_area3_addr
    mov cx, ._w_msg_size 
    call set_mem

    ; Befor Area1

    mov ax, ._s_hdr_addr
    call disp_str

    mov ax, ._w_area1_addr
    call disp_word_hex
    call disp_nl

    mov ax, ._s_hdr_after_mem
    call disp_str

    mov ax, ._w_area1_addr
    mov bx, ._w_msg_size
    call disp_mem

    mov ax, ._s_hdr_after_msg
    call disp_str

    mov ax, ._w_area1_addr
    call disp_str

    ; Befor Area2

    mov ax, ._s_hdr_addr
    call disp_str

    mov ax, ._w_area2_addr
    call disp_word_hex
    call disp_nl

    mov ax, ._s_hdr_after_mem
    call disp_str

    mov ax, ._w_area2_addr
    mov bx, ._w_msg_size
    call disp_mem

    mov ax, ._s_hdr_after_msg
    call disp_str

    mov ax, ._w_area2_addr
    call disp_str

    ; Befor Area3

    mov ax, ._s_hdr_addr
    call disp_str

    mov ax, ._w_area3_addr
    call disp_word_hex
    call disp_nl

    mov ax, ._s_hdr_after_mem
    call disp_str

    mov ax, ._w_area3_addr
    mov bx, ._w_msg_size
    call disp_mem

    mov ax, ._s_hdr_after_msg
    call disp_str

    mov ax, ._w_area3_addr
    call disp_str

;mov ax, 0x4200
;mov bx, 20
;call disp_mem
    ; Disk write

    mov ax, _c_seg         ; セグメント
    mov bx, ._w_area1_addr ; アドレス
    mov ch, 0x80           ; ドライブ番号
    mov cl, ._read_sector1 ; セクタ番号
    mov dh, 0x01           ; セクタ数
    call write_disk

    mov ax, _c_seg         ; セグメント
    mov bx, ._w_area2_addr ; アドレス
    mov ch, 0x80           ; ドライブ番号
    mov cl, ._read_sector2 ; セクタ番号
    mov dh, 0x01           ; セクタ数
    call write_disk

    mov ax, _c_seg         ; セグメント
    mov bx, ._w_area3_addr ; アドレス
    mov ch, 0x80           ; ドライブ番号
    mov cl, ._read_sector3 ; セクタ番号
    mov dh, 0x01           ; セクタ数
    call write_disk


    ret

._w_base_addr equ 0x4000

._w_area1_addr equ ._w_base_addr
._w_area2_addr equ ._w_base_addr + 0x200
._w_area3_addr equ ._w_base_addr + 0x400

._read_sector1 equ 0x21
._read_sector2 equ 0x22
._read_sector3 equ 0x23

._w_msg_size equ 20

._s_hdr_addr :       db 'address    : ', 0x00
._s_hdr_before_mem : db 'before mem : ', 0x00
._s_hdr_before_msg : db 'before msg : ', 0x00
._s_hdr_after_mem :  db 'after mem  : ', 0x00
._s_hdr_after_msg :  db 'after msg  : ', 0x00

._s_msg1:
    db 'All out!',  0x0d, 0x0a, 0x000
    times 50 db 0x00
._s_msg2:
    db 'Pull the throttie!', 0x0d, 0x0a, 0x000
    times 50 db 0x00
._s_msg3:
    db "All right Let's Go!", 0
    times 50 db 0x00


;>===========================
;>  BIOSコールラッパー
;>===========================

;********************************
; get_key
;   0x00    Read Keyboard Input
;       キー入力待ちして、押下されたキーコードとアスキーコードを返す
;	（未確認だけどアスキーコードがないキーを押されるとアスキーコードに0x00が返るんじゃないかな）
; returen ; ah : キーコード
;           al : アスキーコード
;********************************
get_key:
	

    mov ah, 0x00
    int 0x16

    ret

;********************************
; get_kb_sts
;   0x01    Return Keyboard Status
;       キーボードの状態を得る
; return : ZF : 0 : 読み込める
;               1 : 読み込めない
;          ah : スキャンコード
;          al : アスキーコード
; remarks: 前のRead Keyboard Inputが入力待ちでブロックされるので
;          こいつで回して読み込める時にRead Keyboard Inputをする
;          感じかな。向こうでバッファクリアだし。
;********************************
get_kb_sts:

    mov ah, 0x01
    int 0x16

    ret

;********************************
; get_kb_cond
;   0x02    Return Shift Flag Status
;       キーボードのシフトとかの押下状態を得る
; returen ; al : 状態のフラグ
;********************************
get_kb_cond:

    mov ah, 0x02
    int 0x16

    ret

;********************************
; get_kb_tr
;   0x03    Set Typematic Rate
;       キーボードの自動リピート、レートなどを設定する
; param     : ah : 0x03（固定）
;             al : 0x03 : タイプマティック遅延を設定します
;                  0x05 : タイプマティックレートを設定します
;             bl : 0x03 : al=0x03
;                           0x03	1000ミリ秒
;                         al=0x05
;                           0x1F	2.0文字/秒
; return    : なし
;********************************
set_kb_tr:

    mov ah, 0x03
    mov al, al
    mov bl, bl

    int 0x16

    ret

;********************************
; set_kb_buf
;       キーボードバッファにキーデータを書き込む
; param  : ah : 書き込むスキャンコード
;          al : 書き込むアスキーコード
;
;   0x05    Push Data to Keyboard
; param     : ah : 0x05（固定）
;             ch : 書き込むスキャンコード
;             cl : 書き込むアスキーコード
; return    : ZF : 0 : 成功
;                  1 : 失敗
;             al : 0x00 : エラーなし
;                  0x01 : キーボードバッファフル
;********************************
set_kb_buf:

    mov bx, ax
    mov ah, 0x05
    mov cx, bx

    int 0x16

    ret


;********************************
; enh_get_key_data
;   0x10    Enhanced Read Keyboardt
;       キー入力待ちして、押下されたキーコードとアスキーコードを返す
;	（未確認だけどアスキーコードがないキーを押されるとアスキーコードに0x00が返るんじゃないかな）
; returen ; ah : キーコード
;           al : アスキーコード
;********************************
enh_get_key:

    mov ah, 0x10
        int 0x16

    ret

;********************************
; enh_get_kb_sts
;   x11 Enhanced Read Keyboard Status
;       キーボードの状態を得る
; return : ZF : 0 : 読み込める
;               1 : 読み込めない
;          ah : スキャンコード
;          al : アスキーコード
; remarks: 前のRead Keyboard Inputが入力待ちでブロックされるので
;          こいつで回して読み込める時にRead Keyboard Inputをする
;          感じかな。向こうでバッファクリアだし。
;           『このファンクションの互換機能がDOSに実装されているため、通常このファンクションは使用しません』
;           だそうだけど、つまりBIOS機能は別途実装可能ってことね
;********************************
enh_get_kb_sts:

    mov bx, _b_false
    mov ah, 0x11
    int 0x16
    jne ._end
    mov bx, _b_true

._end:
    ret

;********************************
; enh_get_kb_cond
;   0x12    Enhanced Read Keyboard Flags	拡張キーボードフラグ読み込み
;       キーボードのシフトとかの押下状態を得る
; returen ; al : 状態のフラグ
;********************************
enh_get_kb_cond:

    mov ah, 0x12
    int 0x16

    ret

;********************************
; read_disk
;    ahで指定されたドライブのalで指定されたセクタからbhで
;    指定された数だけディスクからセクタを読み込む
;       ax : Extra Segmentを指定
;       bx : 読み込んだデータを書き込むアドレスを指定
;       ch : 読み込むドライブ番号
;       cl : 読み込みを始めるセクタ番号（MBR:1、通常2以上)
;       dh : 読み込むセクタ数
;********************************
read_disk:


    ;mov ax, ax
    mov es, ax   ; 読み込むセグメント
    ;mov bx, bx  ; 読み込む先のアドレス

    mov ah, 0x02 ; セクタ読み込みを指示
    mov al, dh   ; セクタ数
    mov ch, 0x00 ; シリンダ
    mov cl, cl   ; 開始セクタ
    mov dh, 0x00 ; ヘッダ
    mov dl, 0x80 ; ドライブ番号
    int 0x13     ; 読み込み実行

    ret


;********************************
; write_disk
;    ahで指定されたドライブのalで指定されたセクタからbhで
;    指定された数だけディスクからセクタを読み込む
;       ax : Extra Segmentを指定
;       bx : 書き込むデータのあるアドレスを指定
;       ch : 書き込むドライブ番号
;       cl : 書き込みを始めるセクタ番号（MBR:1、通常2以上)
;       dh : 書き込むセクタ数
;********************************
write_disk:


    ;mov ax, ax
    mov es, ax   ; 読み込むセグメント
    ;mov bx, bx  ; 読み込む先のアドレス

    mov ah, 0x03 ; セクタ書き込みを指示
    mov al, dh   ; セクタ数
    mov ch, 0x00 ; シリンダ
    mov cl, cl   ; 開始セクタ
    mov dh, 0x00 ; ヘッダ
    mov dl, 0x80 ; ドライブ番号
    int 0x13     ; 書き込み実行

    ret


;********************************
; get_cpu_speed
;       CPUの速度を設定する
; param  : なし
; return : al : 0x00 : CPUクロックを低速にする
;               0x01 : CPUクロックを中速にする
;               0x02 : CPUクロックを高速にする
;
;   0xF1    Get CPU Speed
; param  : ah : 0xF0
; return : al : 0x00 : CPUクロックを低速にする
;               0x01 : CPUクロックを中速にする
;               0x02 : CPUクロックを高速にする
;********************************
get_cpu_speed:

    mov ah, 0xf1

    int 0x16

    ret


;********************************
; get_vbe_info
;       VBEの情報を取得する
; param  : ES:DI : beInfoBlock 構造体が格納されるバッファーアドレスを指定する。
; return : ax : VBEステータス
;
;   x00 Return VBE Controller Information
; param  : ah   : 0x4F  : VBEのファンクション番号を指定する。
;          al     0x00  : VBEコントローラー情報取得ファンクション番号を指定する。
;         ES:DI : beInfoBlock 構造体が格納されるバッファーアドレスを指定する。
;                       (beInfoBlock:512Byte、VBE3.0の情報 : VbeSignatureに”VBE2”をセットし)
; return : ax : VBEステータス
;
;********************************
get_vbe_info:

    mov ah, 0x4f
    mov al, 0x00

    int 0x00

    ret

;********************************
; get_cursor_pos
; カーソル位置取得
; paramater : なし
; return    : ah : 現在の行（0オリジン）
;           : al : 現在の列（0オリジン）
;********************************
get_cursor_pos:

    push bx
    push cx

    mov ah, 0x03
    mov al, 0x00
    mov bh, 0x00    ; 当面0ページ固定で様子を見る
    mov bl, 0x00    ; 当面0ページ固定で様子を見る
    int 0x10

    mov ax, dx
    mov bx, cx

    pop dx
    pop cx

    ret


;********************************
; set_cursor_pos
; カーソル位置設定
; parameter : ah : 設定する行（0オリジン）
;           : al : 設定する列（0オリジン）
; return : 事実上なし
;********************************
set_cursor_pos:

    push ax
    push bx

    mov dx, ax
    mov ah, 0x02
    mov al, 0x00
    mov bh, 0x00    ; 当面０ページで固定
    mov bl, 0x00    ; 当面０ページで固定
    int 0x10

    pop bx
    pop ax

    ret


;>===========================
;> 	サブルーチン
;>===========================

;********************************
; bin_nibble_hex
;       4bit整数を16進文字に変換する
;       0～15 -> '0'～'f'
; param  : al : 変換する数値
;               16以上を指定すると上位ニブルは無視され、下位ニブルが変換されて返る
;                 e.g. 0x21 -> '1'
; return : bl : 変換された文字
;******************************
bin_nibble_hex:
        and al, 0x0f
        cmp al, 0x09
        ja .gt_9
        add al, 0x30
        jmp .cnv_end
.gt_9:
        add al, 0x37

.cnv_end:
        mov bl, al
        ret

;********************************
; bin_byte_hex
;       1バイトの数値を16進文字列に変換する
; param  : al : 変換したい数値
; return : bx : 変換した2文字の16進文字
;********************************
bin_byte_hex:
    push cx
    push dx

    mov cl, al
    sar al, 4
    and al, 0x0f
    mov ah, 0
    call bin_nibble_hex
    mov dh, bl

    mov al, cl
    and al, 0x0f
    mov ah, 0
    call bin_nibble_hex
    mov dl, bl

    mov bx, dx

    pop dx
    pop cx

    ret

;********************************
; bin_strm_hex
;      バイトデータを16進文字に変換してメモリに設定する
; param  : al : 16進文字に変換するバイトデータ
;          bx : 変換した16進文字を設定するメモリのアドレス
;********************************
bin_strm_hex:
    push dx

    mov si, ax
    mov di, bx
    mov dx, cx

._loop:
    cmp dx, 0
    je ._loop_end
    lodsb

    call bin_byte_hex
    mov [di], bh
    inc di
    mov [di], bl
    inc di
    dec dx
    jmp ._loop
._loop_end:

    pop dx

    ret

;********************************
; set_mem
;       fill mem.
; param : ax : addr of mem where value will be set.
;         bl : value to be set.
;         cx : size to be set.
;********************************
fill_mem:
    push cx
    push si
    push bx
    push dx

    mov si, ax
    mov dx, cx

._loop:
    mov byte [si], bl
    inc si
    dec dx
    or dx, dx
    jne ._loop

._loop_end:
    pop dx
    pop bx
    pop si
    pop cx

    ret

;********************************
; copy_mem
;       copy from mem to mem.
; param : ax : addr of mem where to-value will be set.
;         bx : addr of mem where from-value is set.
;         cx : copy size.
;********************************
copy_mem:

    call set_mem

    ret

;********************************
; cmp_mem
;       2つの領域を指定したサイズで比べる
; param : ax : 1つ目のエリアのアドレス
;         bx : 2つ目のエリアのアドレス
;         cx : 比較するサイズ
; return: dl : 一致したら0、異なっていたら1が返る
;********************************
cmp_mem:
    push ax
    push bx
    push cx

    mov si, ax
    mov di, bx
    mov dx, cx

    mov bx, 0x000

._loop:
    or dx, 0
    je ._success

    mov al, [si]
    mov bl, [di]

    cmp al, bl
    jne ._fail

    inc si
    inc di
    dec dx
    inc bx

    jmp ._loop

._loop_end: 

._success:
    mov dl, 0
    jmp ._exit

._fail:
    mov dh, bl
    mov dl, 1

._exit:
    pop cx
    pop bx
    pop ax

    ret



    mov ax, [_w_cx]
    cmp cx, [_w_cx]
    je ._e

    mov byte al, [bx]
    cmp [si], al
    jne ._ne

    inc si
    inc bx
    inc cx
    jmp ._loop

._ne:
    mov dl, 1
    jmp ._end

._e:
    mov dl, 0

._end:
    pop cx
    pop bx
    pop ax
    ret

;********************************
; get_mem
;       get mem.
; param : ax : 取り出した内容を設定するエリアのアドレス
;         bx : 対象のメモリのアドレス
;         cx : 取り出すサイズ
;********************************
get_mem:
    
    call set_mem

    ret


;********************************
; set_mem
;       get mem.
; param : ax : 値を設定するエリアのアドレス
;         bx : 設定する内容のエリアのアドレス
;         cx : 設定するサイズ
;********************************
set_mem:

    push ax
    push bx
    push dx
    
    mov si, ax
    mov di, bx
    mov dx, cx

._loop:
    or dx, dx
    je ._exit
    mov al, [si]
    mov [di], al
    inc si
    inc di
    dec dx
    jmp ._loop

._exit:

    pop dx
    pop bx
    pop ax
    
    ret


;********************************
; str_len
;       ゼロターミネートされた文字列の長さを求める
; param   : ax : 文字列のアドレス
; returen ; bx : 文字列の長さ
;********************************
str_len:

    push si

    mov si, ax
    mov bx, 0

._loop:
    cmp byte [si], 0x00
    je ._exit_loop
    inc si
    inc bx
    jmp ._loop

._exit_loop:

    pop si

    ret

;********************************
; hex_bin
;   alに設定された16進文字をバイナリに変換してalに返す
;   0～9、A～F以外が指定されると0とみなされる
;   2桁でなく1桁を指定すると後続に0が指定されたとみなされる。恐らく。
;********************************
hex_bin:
; in ax
; out al
    push bx
    push cx

    mov bx, ax

    mov al,  bh
    call hex_nibble
    mov ch, al

    mov al, bl
    call hex_nibble
    mov cl, 0x00
    mov cl, al
    mov al, cl

    mov ah, ch
    mov al, cl
    add cl, ch
    mov ah, 0x00
    mov al, cl

    pop cx
    pop bx

    ret


;********************************
; hex_nibble
;    alに指定された0～9、A～Fの文字をバイナリに変換してalに返す
;    範囲外が指定されると0を返す。
;    2桁指定されると、恐らく下位の位が変換されて返る。
;********************************
hex_nibble:
    cmp al, 0x30
    jl ._ng
    cmp al, 0x3a
    jl ._ok_0_9
    cmp al, 0x41
    jl ._ng
    cmp al, 0x47
    jl ._ok_A_F
    cmp al, 0x61
    jl ._ng
    cmp al, 0x67
    jl ._ok_a_f
._ng:
    mov al, 0x00
    jmp ._exit

._ok_0_9:
    sub al, 0x30
    jmp ._exit

._ok_A_F:
    sub al, 0x37
    jmp ._exit

._ok_a_f:
    sub al, 0x57
    jmp ._exit

._exit:

    ret


;********************************
; hex_str_bin
;    axで指定されたアドレスにある16進文字列をbyteに変換し同じアドレス移送して返す
;    変換できるのは結果が255バイトまで？
;********************************
hex_str_bin:

    push si
    push cx
    push dx
    push word [_w_ax]
    
    mov si, ax
    mov [_w_ax], ax
    mov bx, ._s_buf
    mov cx, 0x0000

._loop:
    mov dx, 0x0000
    lodsb

    cmp al, 0x30
    jl ._loop_end

    call hex_nibble
    mov dh, al

    lodsb

    call hex_nibble
    mov dl, al

    sal dh, 4
    add dl, dh
    mov al, dl

    mov [bx], al

    inc bx
    inc cx

    jne ._loop

._loop_end:

    mov ax, [_w_ax]
    mov bx, ._s_buf
    mov cx, cx
    call copy_mem

    mov bx, cx

    pop word [_w_ax]
    pop dx
    pop cx
    pop si

    ret

._s_buf: times 256 db 0x00


;********************************
; dec_bin
;    alで指定された1文字をbyteに変換してalに返す
;    範囲外は無視なんだろうなぁ
;********************************
dec_bin:
    push bx
    
    mov bl, 0x00
    
    cmp al, 0x30
    jl ._under
    
    cmp al, 0x3a
    jg ._over

    sub al, 0x30
    mov bl, al


;    jmp ._exit
    
._under:
._over:
._exit:
    mov al, bl

    pop bx
    
    ret

;********************************
; dec_str_bin
;    axで指定されたアドレスにある10進文字列をbyteに変換してbxに返す
;    65535までしか変換できない
;********************************
dec_str_bin:

    push ax
    push cx

    mov si, ax
    mov bx, 0x0000    
    mov cx, 0x0000    

._loop:
    lodsb
    or al, al
    je ._loop_end

    call dec_bin
    mov ah, 0x00
    
    mov cx, bx
    sal bx, 3
    add bx, cx
    add bx, cx
    
    add bx, ax
    jmp ._loop

._loop_end:
    
    pop cx
    pop ax
    
    ret

;>===========================
;>  ユーティリティ
;>===========================
;********************************
; debug_print
;********************************
debug_print:
    push ax
    push bx

    mov ax, ._s_debug
    call disp_str

    pop bx
    pop ax

    ret

._s_debug:
    db 'I HAVE COME THIS FAR. by Sun Wukong.', 0x0d, 0x0a, 0


;****************************
; disp_nl
;   改行する
;****************************
disp_nl:

    push ax

    mov ax, _s_crlf
    call disp_str

    pop ax
    
    ret


;********************************
; disp_dec
;      1ワードの数値を10進で表示する
; param  : ax : 表示したい数値
;********************************
disp_dec:
    push ax
    push bx

    mov bx, 0
    mov si, ._buf
    add si, 3

._loop:
    mov dx, 0
    mov bx, 10
    div bx
    mov bx, ax
    mov al, dl
    add al, 0x30
    mov [si], al
    inc si
    mov ax, bx
    cmp bx, 0
    jne ._loop
    dec si
    std
    mov ax, si
    call disp_str
    cld

    pop bx
    pop ax

    ret

._buf db 0x00, 0x0a, 0x0d
    times 12 db 0

;********************************
; disp_byte_hex
;      1バイトの数値を16進で表示する
; param  : al : 表示したい数値
;********************************
disp_byte_hex:
    push ax
    push bx

    call bin_byte_hex
    mov ah, 0x0e
    mov al, bh
    int 0x10
    mov al, bl
    int 0x10

    pop bx
    pop ax

    ret

;********************************
; disp_mem
;       指定された領域を16進で指定したサイズ表示する
; param : ax : 表示する領域のアドレス
;         bx : 表示するサイズ
;********************************
disp_mem:

    push ax
    push cx
    push si

    cmp bx, 0
    je ._end

    mov si, ax
    mov cx, bx

._loop:
    mov byte al, [si]
    
    mov al, [si]
    call disp_byte_hex

    inc si
    dec cx

    cmp cx, 0
    je ._loop_end

    jmp ._loop

._loop_end:

    pop si
    pop cx
    pop ax

._end:

    call disp_nl
      
    ret


;********************************
; disp_word_hex
;       2バイト（1ワード）のデータを表示する
;	（ビッグエンディアン表記）
; param : ax : 表示するword
;********************************
disp_word_hex:

    push ax
    push bx

    mov bx, ax
    mov al, bh
    call disp_byte_hex

    mov al, bl
    call disp_byte_hex

._end:

    pop bx
    pop ax

    ret


;********************************
; disp_str
;       display null-terminated string.
; param : ax : addr of mem where string is set.
;********************************
disp_str:

    push ax
    push si

    mov si, ax
    mov ah, 0x0E

._loop:
    lodsb
    or al, al
    jz ._loop_end
    int 0x10
    jmp ._loop

._loop_end:
    pop si
    pop ax

    ret

;********************************
; バイナリ列を表示可能Asciiに変換する
; ax→ax
; 表示可能な文字は変換せず、不可な文字を「.」に変換する
;********************************
bin_strm_ascii:

    mov di, ._s_buf
    mov si, ax
    
._loop:
    lodsb
    or al, al
    je ._loop_end

    mov al, [si]
    call bin_byte_ascii
    
    mov [di], al
    
    jmp ._loop

._loop_end:



ret

    ._s_buf: times 256 db 0x00


;********************************
; 1ByteバイナリをAsciiに変換する
; al→al
; 表示可能な文字は変換せず、不可な文字を「.」に変換する
;********************************
bin_byte_ascii:

    push bx
    
    mov bl, 0x00

    cmp al, 0x20
    jl ._under
    
    cmp al, 0x7e
    jg ._over

    jmp ._exit

._under:
._over:
    mov al, 0x2e

._exit:
    ;mov al, bl

    pop bx

    ret

;>===========================
;>  サンプル
;>===========================
;****************************
; get_str_ascii
;   キーボードから文字列を取り込んでアドレスをaxに返す
;****************************
get_str_ascii:

    push si
    push bx

    mov [._w_buf_addr], ax
    mov si, ax

._loop:

    call enh_get_kb_sts
    or bx, bx
    jne ._loop

    call enh_get_key
    mov bx, ax
    cmp bl, 0x20
    jg ._add_b
    cmp bx, 0x1c0a
    je ._exit
    cmp bx, 0x1c00
    je ._exit
    cmp bl, 0x0d
    je ._exit 


    cmp si, [._w_buf_addr]
    je ._loop

._add_b:
    mov ax, bx
    mov ah, 0x0e
    int 0x10
    mov [si], al
    inc si
    jmp ._loop

._exit:
    mov byte [si], 0x0d
    inc si
    mov byte [si], 0x0a
    inc si
    mov byte [si], 0x00
    call disp_nl

    mov ax, [._w_buf_addr]

    pop bx
    pop si

    ret


._buf db 0x00

._w_buf_addr: dw 0x0000


;****************************
; power_off
; 	パワーオフ
;****************************
power_off:

    ; APM-BIOSのバージョン取得
    mov ax, 0x5300
    mov bx, 0
    int 0x15
    jc _hlt
    cmp ax, 0x0101
    js _hlt

    ; リアルモードからの制御を宣言（これ、もしかしたらリアルモードへの変更かも）
    mov ax, 0x5301
    mov bx, 0
    int 0x15

    ; APM-BIOS ver 1.1を有効化
    mov ax, 0x530e
    mov bx, 0
    mov cx, 0x0101
    int 0x15
    jc _hlt

    ; 全デバイスのAPM設定を連動させる
    mov ax, 0x530f
    mov bx, 0x0001
    mov cx, 0x0001
    int 0x15
    jc _hlt

    ; 全デバイスのAPM機能有効化
    mov ax, 0x5308
    mov bx, 0x0001
    mov cx, 0x0001
    int 0x15
    jc _hlt

    ; 電源OFF
    mov ax, 0x5307
    mov bx, 0x0001
    mov cx, 0x0003
    int 0x15

    jmp _hlt

    ret


;==============================================================
; ファイル長の調整
;==============================================================
_padding:
    times 0x100000-($-$$) db 0

