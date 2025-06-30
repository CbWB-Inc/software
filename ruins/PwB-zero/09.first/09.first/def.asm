disp_str_ptr:
    disp_str_off : dw 0x0200
    disp_str_seg : dw 0x8000

disp_byte_hex_ptr:
    disp_byte_hex_off : dw 0x0220
    disp_byte_hex_seg : dw 0x8000

disp_word_hex_ptr:
    disp_word_hex_off : dw 0x0237
    disp_word_hex_seg : dw 0x8000

bin_nibble_hex_ptr:
    bin_nibble_hex_off : dw 0x024e
    bin_nibble_hex_seg : dw 0x8000

bin_byte_hex_ptr:
    bin_byte_hex_off : dw 0x0265
    bin_byte_hex_seg : dw 0x8000

disp_nl_ptr:
    disp_nl_off : dw 0x028b
    disp_nl_seg : dw 0x8000

disp_mem_ptr:
    disp_mem_off : dw 0x029c
    disp_mem_seg : dw 0x8000

_hlt_ptr:
    _hlt_off : dw 0x02cf
    _hlt_seg : dw 0x8000

get_cursor_pos_ptr:
    get_cursor_pos_off : dw 0x02dc
    get_cursor_pos_seg : dw 0x8000

set_cursor_pos_ptr:
    set_cursor_pos_off : dw 0x02f5
    set_cursor_pos_seg : dw 0x8000

cls_ptr:
    cls_off : dw 0x030c
    cls_seg : dw 0x8000

get_key_ptr:
    get_key_off : dw 0x0334
    get_key_seg : dw 0x8000

exit_ptr:
    exit_off : dw 0x033d
    exit_seg : dw 0x8000

power_off_ptr:
    power_off_off : dw 0x0387
    power_off_seg : dw 0x8000

str_len_ptr:
    str_len_off : dw 0x03db
    str_len_seg : dw 0x8000

one_line_editor_ptr:
    one_line_editor_off : dw 0x03f8
    one_line_editor_seg : dw 0x8000

ucase_ptr:
    ucase_off : dw 0x04aa
    ucase_seg : dw 0x8000

lcase_ptr:
    lcase_off : dw 0x04cf
    lcase_seg : dw 0x8000

str_cmp_ptr:
    str_cmp_off : dw 0x04f4
    str_cmp_seg : dw 0x8000

line_input_ptr:
    line_input_off : dw 0x0519
    line_input_seg : dw 0x8000

main2_ptr:
    main2_off : dw 0x2600
    main2_seg : dw 0x8000

main_ptr:
    main_off : dw 0x0000
    main_seg : dw 0x8000
