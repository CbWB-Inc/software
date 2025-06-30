;>===========================
;>	BIOSで遊ぼっ！
;>===========================

section .data

	_c_seg          equ 0x07c0
	_c_ex_area_addr equ 0x200

	_c_true         equ '1'
	_c_false        equ '0'

	_b_true         equ 1
	_b_false        equ 0


section .text

boot:
	; set segment register
        mov ax, _c_seg
        mov ds, ax

    mov ah, 0x0e
    ;
    ; disk read
    ;     read to es:bx
    ;
    mov ax, _c_seg
    mov es, ax
    mov bx, _c_ex_area_addr

    mov ah, 0x02 ; Read Sectors From Drive
    mov dl, 0x80 ; Drive
    mov al, 0x20 ; Sectors To Read Count ;
    mov ch, 0x00 ; Cylinder
    mov cl, 0x02 ; Sector(starts from 1, not 0) ; set 2. becouse not need MBR
    mov dh, 0x00 ; Head

    int 0x13     ; Execute disk read


	jmp main



;>****************************
;> hlt
;>****************************
_hlt:
	hlt
	jmp _hlt


_m_isTest:       db 0



;>****************************
;> ブートローダパディング
;>****************************


times 510-($-$$) db 0

;********************************
; ブートセクタシグネチャ
;********************************

db 0x55
db 0xAA

;>********************************
;> definition of variables
;>********************************

_s_crlf:       db 0x0d, 0x0a, 0x00

_m_buf_str:
	times 128 db 0 
    ;db 0, 10, 13, '                             '

_m_rt_sts:
    db 0

_m_ax:
_m_al:
    db 0
_m_ah:
    db 0

_m_bx:
_m_bl:
    db 0
_m_bh:
    db 0

_m_cx:
_m_cl:
    db 0
_m_ch:
    db 0

_m_dx:
_m_dl:
    db 0
_m_dh:
    db 0

_m_x:
_m_xl:
    db 0
_m_xh:
    db 0
_m_y:
_m_yl:
    db 0
_m_yh:
    db 0


_m_zf: db _b_false

;********************************
; definition of strings
;********************************

_s_true:    db 'TRUE ', 13, 10, 0

_s_false:   db 'FALSE', 13, 10, 0



section .text

;>===========================
;>  実験
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
; enh_get_key
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

    mov ax, _b_false
    mov ah, 0x11
    int 0x16
    jne ._end
    mov ax, _b_true

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

; これ、なんか変わってる？実験が必要？
;   てか、こっち使わないとキーを特定できないな

;********************************
; set_cpu_speed
;       CPUの速度を設定する
; param  : al : 0x00 : CPUクロックを低速にする
;               0x01 : CPUクロックを中速にする
;               0x02 : CPUクロックを高速にする
; return : なし
;
;   0xF0    Set CPU Speed
; param     : ah : 0xF0
;           : al : 0x00 : CPUクロックを低速にする
;                  0x01 : CPUクロックを中速にする
;                  0x02 : CPUクロックを高速にする
; return    : なし
;********************************
set_cpu_speed:

    mov ah, 0xF0

    int 0x16

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



;>===========================
;>  BIOSコール 実験コード
;>===========================
;****************************
; 0x00    Read Keyboard Input
;****************************
exp_read_key:

    push ax
    push bx
    
    mov ax, ._title1
    call disp_str
    mov ax, _s_crlf
    call disp_str

    mov ax, ._title2
    call disp_str

    call get_key
    mov bx, ax
._loop:
    mov ax, _s_crlf
    call disp_str
    mov ax, ._header1
    call disp_str
    mov al, bh
    call disp_byte_hex
    mov ax, _s_crlf
    call disp_str
    
    mov ax, ._header2
    call disp_str
    mov al, bl
    call disp_byte_hex
    mov ax, _s_crlf
    call disp_str
    
    call get_key
    mov bx, ax
    jmp ._loop
    
    pop bx
    pop ax
    
    ret

._title1:
    db "******************************", 0x0d, 0x0a
    db "* 0x00    Read Keyboard Input" , 0x0d, 0x0a
    db "******************************", 0x0d, 0x0a, 0x00

._title2:
    db "Please enter key", 0x0d, 0x0a, 0x00

._header1:
    db "Key code   : ", 0x00

._header2:
    db "ASCII code : ", 0x00

;
; sign  Key     ASCII
;----------------------------
; ret   0x1c    0x0d
; Esc   0x01    0x1b
; F1    0x3b    0x00
; F2    0x3c    0x00
; F3    0x3d    0x00
; F4    0x3e    0x00
; F5    0x3f    0x00
; F6    0x40    0x00
; F7    0x41    0x00
; F8    0x42    0x00
; F09   0x43    0x00
; F10   0x44    0x00
; F11   0x85    0x00
; F12   0x86    0x00
; PrtSc   -       -
; PrtSc   -       -
; SclLck  -       -
; Pause 0x00    0x00
; 漢字  0x29    0x60
;   1   0x02    0x31
;   2   0x03    0x32
;   3   0x04    0x33
;   4   0x05    0x34
;   5   0x06    0x35
;   6   0x07    0x36
;   7   0x08    0x37
;   8   0x09    0x38
;   9   0x0a    0x39
;   0   0x0b    0x30
;   -   0x2c    0xcd
;   ^   0x0d    0x3d
;   \    -        -
;  BS   0x0e    0x08
;  INS  0x52    0x00
; Home  0x47    0x00
; PgUp  0x49    0x00
; Tab   0x0f    0x09
;   q   0x10    0x51
;   w   0x11    0x57
;   e   0x12    0x45
;   r   0x13    0x52
;   t   0x14    0x54
;   y   0x15    0x59
;   u   0x16    0x55
;   i   0x17    0x49
;   o   0x18    0x4f
;   p   0x19    0x50
;   @   0x10    0x5b
;   [   0x1b    0x5d
;  Del  0x53    0x00
;  End  0x4f    0x00
; PgDn  0x51    0x00
; CapLk  -        -
;   a   0x1e    0x41
;   s   0x1f    0x53
;   d   0x20    0x44
;   f   0x21    0x46
;   g   0x22    0x47
;   h   0x23    0x48
;   j   0x24    0x4a
;   k   0x25    0x4b
;   l   0x26    0x4c
;   ;   0x27    0x3b
;   :   0x28    0x27
;   ]   0x2b    0x5c
; L Sft   -       -
;   z   0x2c    0x5a
;   x   0x2d    0x58
;   c   0x2e    0x43
;   v   0x2f    0x56
;   b   0x30    0x42
;   n   0x31    0x4e
;   m   0x32    0x4d
;   ,   0x33    0x2c
;   .   0x34    0x2e
;   /   0x35    0x2f
;   \     -       -
; R Sft   -       -
;  ↑   0x48    0x00
;
;
;
;
;
;



;****************************
; 0x01    Return Keyboard Status
;****************************
exp_get_kb_sts:

;   今のところ何の役に立つのかわからない<Remarks timestamp="2024年5月5日 20:27:29"/>

    push ax
    push bx

    mov ax, ._title1
    call disp_str
    mov ax, _s_crlf
    call disp_str

    mov ax, ._title2
    call disp_str


._loop:

    mov ah, 0x01
    int 0x16
    
    je ._no_data

    mov ax, _s_crlf
    call disp_str
    mov ax, ._header1
    call disp_str
    mov al, bh
    call disp_byte_hex
    mov ax, _s_crlf
    call disp_str

    mov ax, ._header2
    call disp_str
    mov al, bl
    call disp_byte_hex
    mov ax, _s_crlf
    call disp_str

    call get_key
    
    mov ax, _s_crlf
    call disp_str
    mov ax, ._header1
    call disp_str
    mov al, bh
    call disp_byte_hex
    mov ax, _s_crlf
    call disp_str
    
    mov ax, ._header2
    call disp_str
    mov al, bl
    call disp_byte_hex
    mov ax, _s_crlf
    call disp_str
    
    jmp ._loop


._no_data:


    jmp ._loop


    ret

._title1:
    db "*********************************", 0x0d, 0x0a
    db "* 0x01    Return Keyboard Status" , 0x0d, 0x0a
    db "*********************************", 0x0d, 0x0a, 0x00

._title2:
    db "Please enter key", 0x0d, 0x0a, 0x00

._header1:
    db "Key code   : ", 0x00

._header2:
    db "ASCII code : ", 0x00




;********************************
; 0x02  Return Shift Flag Status
; exp_get_kb_cond
;       キーボードの状態を取得する
;********************************
exp_get_kb_cond:


    push bx
    push cx

    mov ax, ._title1
    call disp_str
    mov ax, _s_crlf
    call disp_str

    mov ax, ._title2
    call disp_str

._loop:

    call get_key
    mov bx, ax
    mov ax, ._header
    call disp_str
    mov ax, bx
    call disp_word_hex
    call disp_nl



    call get_kb_cond
    mov bx, ax

    mov cx, bx
    and cx, 0x01
    cmp cx, 0
    je ._next1
    mov ax, ._r_shift
    call disp_str

._next1:

    mov cx, bx
    and cx, 0x02
    cmp cx, 0
    je ._next2
    mov ax, ._l_shift
    call disp_str

._next2:

    mov cx, bx
    and cx, 0x04
    cmp cx, 0
    je ._next3
    mov ax, ._ctrl
    call disp_str

._next3:

    mov cx, bx
    and cx, 0x08
    cmp cx, 0
    je ._next4
    mov ax, ._alt
    call disp_str

._next4:


    mov cx, bx
    and cx, 0x10
    cmp cx, 0
    je ._next5
    mov ax, ._scroll_lock
    call disp_str

._next5:

    mov cx, bx
    and cx, 0x20
    cmp cx, 0
    je ._next6
    mov ax, ._num_lock
    call disp_str

._next6:

    mov cx, bx
    and cx, 0x40
    cmp cx, 0
    je ._next7
    mov ax, ._caps_lock
    call disp_str

._next7:

    mov cx, bx
    and cx, 0x80
    cmp cx, 0
    je ._next8
    mov ax, ._ins
    call disp_str

._next8:

    call disp_nl

    jmp ._loop

    mov ax, bx

    pop cx
    pop bx


	ret



._r_shift:
    db '  right shift', 0x0d, 0x0a, 0x00

._l_shift:
    db '  left  shift', 0x0d, 0x0a, 0x00

._ctrl:
    db '  CTRL', 0x0d, 0x0a, 0x00

._alt:
    db '  ALT', 0x0d, 0x0a, 0x00

._scroll_lock:
    db '  Scroll Lock', 0x0d, 0x0a, 0x00

._num_lock:
    db '  Num Lock', 0x0d, 0x0a, 0x00

._caps_lock:
    db '  Caps Lock', 0x0d, 0x0a, 0x00

._ins:
    db '  Insert Mode', 0x0d, 0x0a, 0x00

._header:
    db 'key : ', 0x00

._title1:
    db "*********************************", 0x0d, 0x0a
    db "* 0x02  Return Shift Flag Status" , 0x0d, 0x0a
    db "*********************************", 0x0d, 0x0a, 0x00

._title2:
    db "Please enter key", 0x0d, 0x0a, 0x00



;********************************
; 0x03  Set Typematic Rate
; exp_get_kb_cond
;       キーボードの状態を取得する
;********************************
exp_set_kb_tr:

    mov ax, ._title1
    call disp_str
    mov ax, _s_crlf
    call disp_str

    mov al, 0x03
    mov bl, 0x03
    call set_kb_tr
    

    mov al, 0x05
    mov bl, 0x1f
    call set_kb_tr
    

    ret

._title1:
    db "*********************************", 0x0d, 0x0a
    db "* 0x03  Set Typematic Rate" , 0x0d, 0x0a
    db "*********************************", 0x0d, 0x0a, 0x00


;********************************
; 0x12  Enhanced Read Keyboard Flags
; exp_enh_get_kb_cond
;       キーボードの状態を取得する
;********************************
exp_enh_get_kb_cond:



    mov ax, ._title1
    call disp_str
    mov ax, _s_crlf
    call disp_str

    je ._loop
    ret

._loop:

    call enh_get_key
    mov bx, ax
 
    mov ax, ._header
    call disp_str
    mov ax, bx
    call disp_word_hex
    call disp_nl

    call enh_get_kb_cond
    mov bx, ax
    call disp_nl

    mov cx, bx
    mov ch, 0x00
    and cx, 0x01
    cmp cx, 0
    je ._next1
    mov ax, ._r_shift
    call disp_str

._next1:

    mov cx, bx
    mov ch, 0x00
    and cx, 0x02
    cmp cx, 0
    je ._next2
    mov ax, ._l_shift
    call disp_str

._next2:

    mov cx, bx
    mov ch, 0x00
    and cx, 0x04
    cmp cx, 0
    je ._next3
    mov ax, ._ctrl
    call disp_str

    mov cx, bx
    mov cl, 0x00
    and ch, 0x04
    cmp cx, 0
    je ._next2_1
    mov ax, ._r_ctrl
    call disp_str

._next2_1:

    mov cx, bx
    mov cl, 0x00
    and ch, 0x01
    cmp cx, 0
    je ._next3
    mov ax, ._l_ctrl
    call disp_str

._next3:

    mov cx, bx
    mov ch, 0x00
    and cx, 0x08
    cmp cx, 0
    je ._next4
    mov ax, ._alt
    call disp_str

    mov cx, bx
    mov cl, 0x00
    and ch, 0x02
    cmp cx, 0
    je ._next3_1
    mov ax, ._l_alt
    call disp_str

._next3_1:

._next4:

    mov cx, bx
    mov ch, 0x00
    and cx, 0x10
    cmp cx, 0
    je ._next5
    mov ax, ._scroll_lock
    call disp_str

._next5:

    mov cx, bx
    mov ch, 0x00
    and cx, 0x20
    cmp cx, 0
    je ._next6
    mov ax, ._num_lock
    call disp_str

._next6:

    mov cx, bx
    mov ch, 0x00
    and cx, 0x40
    cmp cx, 0
    je ._next7
    mov ax, ._caps_lock
    call disp_str

._next7:

    mov cx, bx
    mov ch, 0x00
    and cx, 0x80
    cmp cx, 0
    je ._next8
    mov ax, ._ins
    call disp_str

._next8:

    mov cx, bx
    mov cl, 0x00
    and ch, 0x08
    cmp cx, 0
    je ._next9
    mov ax, ._sclk
    call disp_str

._next9:

    mov cx, bx
    mov cl, 0x00
    and ch, 0x20
    cmp cx, 0
    je ._next10
    mov ax, ._numlk
    call disp_str

._next10:

    mov cx, bx
    mov cl, 0x00
    and ch, 040
    cmp cx, 0
    je ._next11
    mov ax, ._caplk
    call disp_str

._next11:

    mov cx, bx
    mov cl, 0x00
    and ch, 08
    cmp cx, 0
    je ._next12
    mov ax, ._sysrq
    call disp_str

._next12:

    call disp_nl

    mov ax, bx

    ;jmp ._loop

    ret

._r_shift:
    db '  right shift', 0x0d, 0x0a, 0x00

._l_shift:
    db '  left  shift', 0x0d, 0x0a, 0x00

._ctrl:
    db '  CTRL', 0x0d, 0x0a, 0x00

._alt:
    db '  ALT', 0x0d, 0x0a, 0x00

._scroll_lock:
    db '  Scroll Lock', 0x0d, 0x0a, 0x00

._num_lock:
    db '  Num Lock', 0x0d, 0x0a, 0x00

._caps_lock:
    db '  Caps Lock', 0x0d, 0x0a, 0x00

._ins:
    db '  Insert Mode', 0x0d, 0x0a, 0x00

._sclk:
    db '  Scroll Lock', 0x0d, 0x0a, 0x00

._numlk:
    db '  Num Lock', 0x0d, 0x0a, 0x00

._caplk:
    db '  Caps Lock(Enh)', 0x0d, 0x0a, 0x00

._sysrq:
    db '  Sys Req', 0x0d, 0x0a, 0x00

._r_ctrl:
    db '  Right CTRL', 0x0d, 0x0a, 0x00

._l_ctrl:
    db '  Left CTRL', 0x0d, 0x0a, 0x00

._l_alt:
    db '  Left ALT', 0x0d, 0x0a, 0x00

._header:
    db 'key : ', 0x00

._title1:
    db "*********************************", 0x0d, 0x0a
    db "* 0x12  Enhanced Read Keyboard Flags" , 0x0d, 0x0a
    db "*********************************", 0x0d, 0x0a, 0x00


;********************************
; 0xF0  Set CPU Speed
; exp_enh_set_cpu_speed
;       CPUのクロックを設定する
;********************************
exp_set_cpu_speed:

    call exp_get_cpu_speed
    call disp_nl

    mov ax, ._title1
    call disp_str
    call disp_nl

    mov al, 0x02
    call disp_byte_hex
    call disp_nl

    call set_cpu_speed
    call disp_nl

    call exp_get_cpu_speed

    ret

._title1:
    db "*********************************", 0x0d, 0x0a
    db "* 0xF1  Set CPU Speed" , 0x0d, 0x0a
    db "*********************************", 0x0d, 0x0a, 0x00

;********************************
; 0xF1  Get CPU Speed
; exp_enh_get_cpu_speed
;       CPUのクロック設定を取得する
;********************************
exp_get_cpu_speed:

    mov ax, ._title1
    call disp_str
    mov ax, _s_crlf
    call disp_str

    call get_cpu_speed
    call disp_byte_hex

    ret

._title1:
    db "*********************************", 0x0d, 0x0a
    db "* 0xF1  Get CPU Speed" , 0x0d, 0x0a
    db "*********************************", 0x0d, 0x0a, 0x00



;********************************
; エコーの実験
;********************************
exp_echo:

    mov ax, ._title1
    call disp_str
    mov ax, _s_crlf
    call disp_str

    mov si, _m_buf_str

._loop:

    call enh_get_kb_sts
    ;cmp ax, 0
    jne ._loop
    
    call enh_get_key
    
    call disp_nl
    call disp_nl
    call disp_nl
    call disp_nl
    call disp_nl
    mov bx, ax
    
    cmp bl, 0x20
    jge ._skip

    mov byte [si], 0x0d
    inc si
    mov byte [si], 0x00
    inc si
    mov byte [si], 0x00

    mov si, _m_buf_str

    call disp_nl
    mov ax, si
    call disp_str
    call disp_nl

    mov ax, ._restart
    call disp_str

    mov ax, bx
    cmp bx, 0x1c0a
    je ._exit


    jmp ._loop

._skip:
    
    cmp bx, 0x20
    jl ._loop

    mov ax, bx
    cmp ax, 0x1c00
    je ._exit
    
    mov ah, 0x0e
    int 0x10

    mov [si], al
    inc si

    jmp ._loop


._exit:

    mov ax, si
    call disp_str
    call disp_nl
    call disp_nl

    mov ax, bx

    ret

._title1:
    db "*********************************", 0x0d, 0x0a
    db "* Echo" , 0x0d, 0x0a
    db "*********************************", 0x0d, 0x0a
    db "CTRL + Enter -> Power off", 0x0d, 0x0a
    db "Enter any key", 0x0d, 0x0a, 0x00

._restart: db '** : restart', 0x0d, 0x00a, 0x0d, 0x0a, 0x00


exp_echo2:

    mov ax, ._title1
    call disp_str
    mov ax, _s_crlf
    call disp_str

    call get_str_ascii

    mov ax, si
    call disp_str
    call disp_nl
    call disp_nl

    ret


._title1:
    db "*********************************", 0x0d, 0x0a
    db "* Echo2" , 0x0d, 0x0a
    db "*********************************", 0x0d, 0x0a
    db "CTRL + Enter -> Power off", 0x0d, 0x0a
    db "Enter any key", 0x0d, 0x0a, 0x00

._restart: db '** : restart', 0x0d, 0x00a, 0x0d, 0x0a, 0x00



;>===========================
;> 	サブルーチン
;>===========================

;********************************
; nibble_hex
;       4bit整数を16進文字に変換する
;       0～15 -> '0'～'f'
; param  : al : 変換する数値
;               16以上を指定すると上位ニブルは無視され、下位ニブルが変換されて返る
;                 e.g. 0x21 -> '1'
; return : al : 変換された文字
;******************************
nibble_hex:

        and al, 0x0f

        cmp al, 0x09
        ja .gt_9

        add al, 0x30
        jmp .cnv_end

.gt_9:
        add al, 0x37

.cnv_end:

        ret


;
; jmpもcmpも美しくない。というわけでこんなの書いてみました。
;
nibble_hex2:

    push bx


    and al, 0x0f
    mov bx, 0
    mov bl, al
    sub bx, 10
    mov bl, bh

    sar bl, 7
    not bl

    and bl, 7

    add al, bl
    add ax, 0x30

    pop bx

    ret


;********************************
; byte_hex
;       1バイトの数値を16進文字列に変換する
; param  : al : 変換したい数値
; return : bx : 変換した2文字の16進文字
;********************************
byte_hex:
    push ax
    push cx

    mov cl, al
    and al, 0x0f
    mov ah, 0
    call nibble_hex
    mov bh, al

    mov al, cl
    shr al, 4
    mov ah, 0
    call nibble_hex
    mov bl, al

    pop cx
    pop ax

    ret


;********************************
; disp_byte_hex
;      1バイトの数値を16進で表示する
; param  : al : 表示したい数値
;********************************
disp_byte_hex:
    push ax
    push bx

    call byte_hex

    mov ah, 0x0e
    mov al, bl
    int 0x10
    mov al, bh
    int 0x10

    pop bx
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
; byte_hex_mem


;********************************
; byte_hex_mem
;      バイトデータを16進文字に変換してメモリに設定する
; param  : al : 16進文字に変換するバイトデータ
;          bx : 変換した16進文字を設定するメモリのアドレス
;********************************
byte_hex_mem:
        push bx
    push cx
    push word [_m_bx]
    mov word [_m_bx], bx

    call byte_hex
    mov cx, bx

    mov word bx, [_m_bx]
    mov byte [bx], cl
    add bx, 1
    mov byte [bx], ch

    pop word [_m_bx]
    pop cx
    pop bx

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
;        cld
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
; mem_set
;       set mem.
; param : ax : addr of mem where value will be set.
;         bl : value to be set.
;         cx : size to be set.
;********************************
mem_set:
    push cx
    push si
    push word [_m_cx]
    push bx
    push dx

    mov word [_m_cx], cx

    mov si, ax
    mov cx, 0

._value_set_loop:
    mov byte [si], bl
    inc si
    inc cx

    mov dx, cx
    cmp dx, [_m_cx]
    jne ._value_set_loop

    pop dx
    pop bx
    pop word [_m_cx]
    pop si
    pop cx

    ret


;********************************
; mem_cpy
;       copy from mem to mem.
; param : ax : addr of mem where to-value will be set.
;         bx : addr of mem where from-value is set.
;         cx : copy size.
;********************************
mem_cpy:
    push bx
    push cx
    push dx
    push word [_m_bx]
    push word [_m_cx]
    push si

    mov word [_m_bx], bx
    mov word [_m_cx], cx

    mov cx, 0
    mov si, ax

._copy_loop:
    mov byte dh, [bx]
    mov [si], dh

    inc si
    inc bx
    inc cx

    cmp cx, [_m_cx]
    jb ._copy_loop

    pop si
    pop word [_m_cx]
    pop word [_m_bx]
    pop dx
    pop cx
    pop bx

    ret


;********************************
; mem_cmp
;       2つの領域を指定したサイズで比べる
; param : ax : 1つ目のエリアのアドレス
;         bx : 2つ目のエリアのアドレス
;         cx : 比較するサイズ
; return: dl : 一致したら0、異なっていたら1が返る
;********************************
mem_cmp:
    mov dl, 0

    push ax
    push bx
    push cx
    push si
    push word [_m_cx]


    mov [_m_cx], cx
    mov cx, 0
    mov si, ax

._loop:

    mov ax, [_m_cx]
    cmp cx, [_m_cx]
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
    pop word [_m_cx]
    pop si
    pop cx
    pop bx
    pop ax

    ret


;********************************
; mem_dsp
;       指定された領域を16進で指定したサイズ表示する
; param : ax : 表示する領域のアドレス
;         bx : 表示するサイズ
;********************************
mem_dsp:

    push ax
    push cx
    push si

    cmp bx, 0
    je ._end
._loop:
    mov byte al, [si]
    call disp_byte_hex
    inc si
    inc cx
    cmp cx, bx
    jb ._loop


    pop si
    pop cx
    pop ax

._end:
        
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

;****************************
; get_str_ascii
;   キーボードから文字列を取り込んでアドレスをaxに返す
;****************************
get_str_ascii:

    mov si, _m_buf_str

._loop:

    call enh_get_kb_sts
    jne ._loop

    call enh_get_key
    mov bx, ax
    
    cmp bl, 0x20
    jg ._skip

._l1:

    cmp bx, 0x1c0a
    je ._exit

    mov cx, bx
    mov ch, 0x00
    cmp cl, 0x0d
    jne ._nnl

    cmp si, _m_buf_str
    je ._loop

    mov byte [si], 0x0d
    inc si
    mov byte [si], 0x0a
    inc si
    mov byte [si], 0x00

    call disp_nl
    call disp_nl
    mov si, _m_buf_str
    mov ax, si
    call disp_str
    call disp_nl
    mov byte [si], 0x00

    jmp ._loop

._nnl
    mov ax, bx

    cmp si, _m_buf_str
    je ._loop

    mov [si], al
    inc si

    jmp ._loop

._skip:

    mov ax, bx
    
    mov ah, 0x0e
    int 0x10

    mov [si], al
    inc si

    jmp ._loop

._exit:

    mov ax, si

    ret






;>===========================
;> テスト
;>===========================
_test_codes:

;>===========================
;> 個別テスト
;>===========================

;>===========================
;> 一括テスト
;>===========================
test_all:

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



;>===========================
;> main
;>===========================

main:
    ; set segment register
    mov ax, _c_seg
    mov ds, ax

    ; ビデオモードの設定
    mov ah, 0x0
    mov al, 0x3    ; 16色テキスト、80x25
    ; mov al, 0x6a  ; 800x600x4bitカラー（ビデオカードによってはサポートされない）
    int 0x10

    ; 念のため初期化
    cld



;********************************
;   0x00    Read Keyboard Inputの実験
;********************************
    ;call exp_read_key

;********************************
;   0x01    Return Keyboard Statusの実験
;********************************
    ;call exp_get_kb_sts

;********************************
;   0x02    Return Shift Flag Statusの実験
;********************************
    ;call exp_get_kb_cond

;********************************
;   0x03    Set Typematic Rateの実験
;********************************
    ;call exp_set_kb_tr

;********************************
;   0x12    Set Typematic Rateの実験
;********************************
    ;call exp_enh_get_kb_cond

;********************************
;   0xF0    Set CPU Speedの実験
;********************************
    ;call exp_set_cpu_speed

;********************************
;   0xF1    Get CPU Speedの実験
;********************************
    ;call exp_get_cpu_speed


    ;call exp_echo
    call exp_echo2
    jmp _end

mov ax, 0x0000
mov bx, _test
mov byte al, [bx]
mov bx, ax
call disp_word_hex
call disp_byte_hex

loop:

mov dx, 0
mov ax, bx
mov bx, 10
div bx
mov cx, dx
mov bx, ax
mov ah, 0x0e
mov al, dl
add al, 0x30
int 0x10

cmp bx, 0
jne loop

_end:
    mov ax, _bye
    call disp_str

    ; 処理終了
    ;call power_off
    call _hlt

_bye: db 'bye', 0x0d, 0x0a, 0x00

_test: db 0x33, 0x00

;==============================================================
; ファイル長の調整
;==============================================================
_padding:
    times 0x100000-($-$$) db 0

