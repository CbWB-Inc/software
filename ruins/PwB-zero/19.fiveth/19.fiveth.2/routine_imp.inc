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
;extern decide_next_p_task
extern set_own_seg
;extern write_log
;extern read_log
extern logk_log
extern unlock_log
exterm get_key

extern tick_addr
extern tick_seg
extern tick_ptr

extern sleep_sec

extern ctx_current
extern ctx_next
extern ctx_temp


extern shared_buf_seg
extern shared_head_ofs
extern shared_tail_ofs
extern shared_data_ofs

extern shared_buf_len

; ロックアドレス
extern log_lock_seg
extern log_lock_off

extern g_cursor
extern g_key_condition


    c_data_seg equ 0x9000
    c_data_off equ 0xff00
    c_data_msg_off equ 0xff00
    c_data_buf_off equ 0xff02



