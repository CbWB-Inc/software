; routine.inc

extern disp_str
extern disp_nl
extern putc
extern disp_word_hex
extern disp_hex
extern disp_byte_hex
extern disp_mem
extern get_cursor_pos
extern set_cursor_pos
extern cls
extern get_key_b
extern power_off
extern str_len
extern ucase
extern lcase
extern str_cmp
extern line_input
extern set_own_seg
extern get_tick
extern set_tick
extern sleep
extern _wait

tick_addr equ 0xfff0
tick_seg equ 0x8000
tick_ptr	dw 0

sleep_sec dw 0

shared_buf_seg  equ 0x9d00
shared_head_ofs equ 0x0000
shared_tail_ofs equ 0x0002
shared_data_ofs equ 0x0004

shared_buf_len  equ 256

key_buf_seg  		equ 0x9a00
key_buf_head_ofs 	equ 0x0000
key_buf_tail_ofs 	equ 0x0002
key_buf_data_ofs 	equ 0x0004
key_buf_len  		equ 256

; ロックアドレス
log_lock_seg equ 0x9e00
log_lock_off equ 0xfe00
