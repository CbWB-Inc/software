main            equ 0x0200
main2           equ 0x2800
get_key         equ 0x1B18
get_kb_sts      equ 0x1B1D
get_kb_cond     equ 0x1B22
set_kb_tr       equ 0x1B27
set_kb_buf      equ 0x1B30
enh_get_key     equ 0x1B39
enh_get_kb_sts  equ 0x1B3E
enh_get_kb_cond equ 0x1B4B
read_disk       equ 0x1B50
write_disk      equ 0x1B61
get_cpu_speed   equ 0x1B72
get_vbe_info    equ 0x1B77
get_cursor_pos  equ 0x1B7E
set_cursor_pos  equ 0x1B91
bin_nibble_hex  equ 0x1BA2
bin_byte_hex    equ 0x1BB1
bin_strm_hex    equ 0x1BD1
fill_mem        equ 0x1BEC
copy_mem        equ 0x1C01
cmp_mem         equ 0x1C05
get_mem         equ 0x1C1E
set_mem         equ 0x1C52
str_len         equ 0x1C6C
str_cmp         equ 0x1C7D
ucase           equ 0x1CAE
lcase           equ 0x1CC9
hex_bin         equ 0x1CE6
hex_nibble      equ 0x1D09
hex_str_bin     equ 0x1D32
dec_bin         equ 0x1E79
dec_str_bin     equ 0x1E8C
cls             equ 0x1EB0
debug_print     equ 0x1EDD
disp_nl         equ 0x1F0F
disp_dec        equ 0x1F1F
disp_byte_hex   equ 0x1F5C
disp_mem        equ 0x1F6E
disp_word_hex   equ 0x1F91
disp_str        equ 0x1FA2
bin_strm_ascii  equ 0x1FB4
bin_byte_ascii  equ 0x20C8
one_line_editer equ 0x20D9
get_str_ascii   equ 0x2190
power_off       equ 0x21E1
print           equ 0x2238
exit            equ 0x2267

