disp_str_ptr:
    disp_str_off : dw 0x0000
    disp_str_seg : dw 0x9000

disp_byte_hex_ptr:
    disp_byte_hex_off : dw 0x0020
    disp_byte_hex_seg : dw 0x9000

disp_word_hex_ptr:
    disp_word_hex_off : dw 0x0037
    disp_word_hex_seg : dw 0x9000

bin_nibble_hex_ptr:
    bin_nibble_hex_off : dw 0x004e
    bin_nibble_hex_seg : dw 0x9000

bin_byte_hex_ptr:
    bin_byte_hex_off : dw 0x0065
    bin_byte_hex_seg : dw 0x9000

disp_nl_ptr:
    disp_nl_off : dw 0x008b
    disp_nl_seg : dw 0x9000

disp_mem_ptr:
    disp_mem_off : dw 0x009c
    disp_mem_seg : dw 0x9000

_hlt_ptr:
    _hlt_off : dw 0x00cf
    _hlt_seg : dw 0x9000

get_cursor_pos_ptr:
    get_cursor_pos_off : dw 0x00dc
    get_cursor_pos_seg : dw 0x9000

set_cursor_pos_ptr:
    set_cursor_pos_off : dw 0x00f5
    set_cursor_pos_seg : dw 0x9000

cls_ptr:
    cls_off : dw 0x010c
    cls_seg : dw 0x9000

get_key_ptr:
    get_key_off : dw 0x0134
    get_key_seg : dw 0x9000

exit_ptr:
    exit_off : dw 0x013d
    exit_seg : dw 0x9000

power_off_ptr:
    power_off_off : dw 0x0187
    power_off_seg : dw 0x9000

str_len_ptr:
    str_len_off : dw 0x01db
    str_len_seg : dw 0x9000

one_line_editor_ptr:
    one_line_editor_off : dw 0x01f8
    one_line_editor_seg : dw 0x9000

ucase_ptr:
    ucase_off : dw 0x02aa
    ucase_seg : dw 0x9000

lcase_ptr:
    lcase_off : dw 0x02cf
    lcase_seg : dw 0x9000

str_cmp_ptr:
    str_cmp_off : dw 0x02f4
    str_cmp_seg : dw 0x9000

line_input_ptr:
    line_input_off : dw 0x0319
    line_input_seg : dw 0x9000

