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
