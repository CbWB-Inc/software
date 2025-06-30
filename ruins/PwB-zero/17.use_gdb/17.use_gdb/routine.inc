; routine.inc

extern disp_str
extern disp_nl
extern putc
extern disp_word_hex
extern disp_hex
extern get_cursor_pos
extern set_cursor_pos
extern get_tick
extern set_tick
extern sleep
extern _wait

tick_addr equ 0xfff0
tick_seg equ 0x8000
tick_ptr	dw 0

sleep_sec dw 0
