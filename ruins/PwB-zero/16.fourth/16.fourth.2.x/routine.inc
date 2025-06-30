; routine.inc
extern disp_str
extern disp_hex
extern disp_byte_hex
extern disp_word_hex
extern disp_nl
extern disp_mem
extern bin_byte_hex
extern bin_nibble_hex
extern get_cursor_pos
extern set_cursor_pos
extern cls
extern get_key
extern exit
extern power_off
extern str_len
extern ucase
extern lcase
extern str_cmp
extern line_input
extern set_own_seg
extern putc
extern get_tick
extern set_tick
extern sleep
extern _wait
extern decide_next_p_task
extern write_log
extern read_log
extern write_log_str
extern read_log_str
extern acquire_lock
extern release_lock
extern print_seg_offset
extern get_c_msg_off
extern get_c_buf_off

tick_addr equ 0xfff0
tick_seg equ 0x8000
tick_ptr dw 0

key_buf_off equ 0xffd0
key_buf_seg equ 0x8000
key_buf_ptr dw key_buf_off

_s_common_buf : times 128 db 0
