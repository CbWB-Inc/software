; routine.inc

global disp_str
global disp_nl
global putc
global disp_word_hex
global disp_hex
global disp_byte_hex
global disp_mem
global get_cursor_pos
global set_cursor_pos
;global cls
;global putcd
global get_key_b
global power_off
global str_len
global ucase
global lcase
global str_cmp
global line_input
global set_own_seg
global get_tick
global set_tick
global sleep
global _wait
;global decide_next_p_task
global set_own_seg
;global write_log
;global read_log
global lock_log
global unlock_log
;global get_key
;global read_key_buf

global tick_ptr
global sleep_sec

global tick_addr
global tick_seg

global ctx_current
global ctx_next
global ctx_temp

global shared_buf_seg
global shared_head_ofs
global shared_tail_ofs
global shared_data_ofs
global shared_buf_len

global log_lock_seg
global log_lock_off

global g_cursor
global g_cursor.x
global g_cursor.y
global g_key_condition

global key_buf_seg
global key_buf_head_ofs
global key_buf_tail_ofs
global key_buf_data_ofs
global key_buf_len
