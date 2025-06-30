
jmp setup


setup:
    mov ax, cs
    mov ds, ax
    mov es, ax

    ; ビデオモードの設定
    mov ah, 0x0
    mov al, 0x3    ; 16色テキスト、80x25
    int 0x10

start:
    
    ; メモリ量を知る。結果がaxに返る
    ; 実行したところ0x27fが返ってきた。
    ; 0x27f=639だそうな
    ;
    mov ax, 0x0000
    int 0x12
    call disp_word_hex
    call disp_nl
    ;
    ; ちなみに0xa0000=655360バイト=640Kbyte
    ; というわけで、メモリ上限は9ffffらしいです。
    ;
    
    ;
    ; 拡張メモリ容量を知る
    ; コンベンショナルメモリ（640KB)以降のメモリ量を得る
    ; 結果はaxに返る。axが16bitなので65535即ち約64MBまでしかわからないらしい
    ;
    mov ah, 0x88
    int 0x15
    jc .error
    call disp_word_hex
    call disp_nl
    jmp ._disk

.error:
    mov al, 'E'
    call putc
    call disp_nl
    ;
    ; 実行したところ0xfc00が返ってきた
    ; 約63MBだそうだ。
    ; コンベンショナルと合わせて64MBってことなのかもね
    
._disk:

    ;
    ; ディスク関係
    ; dl:drive no : 0x00-0x7f : FDD
    ;               0x80-     : HDD
    ; cx: シリンダ＆セクタ  面倒くさいやつ
    ; dh: head no : 0x0-0xd
    ; dl: 利用可能なドライブ数

    mov ah, 0x08
    mov dl, 0x00
    int 0x13
    jc ._fdd_error
    call disp_word_hex
    call disp_nl
    
    mov ax, cx
    call disp_word_hex
    call disp_nl
    
    mov ax, dx
    call disp_word_hex
    call disp_nl
    ;
    ; 結果
    ; 0000
    ; 4f24
    ; 0101
    ;
    ; ヘッダは0/1の２つ、ドライブは1台利用可能らしい
    ;
    ;
    jmp ._hdd

._fdd_error:
    mov al, 'E'
    call putc
    call disp_nl


._hdd:
    mov ah, 0x08
    mov dl, 0x80
    int 0x13
    jc ._hdd_error
    
    call disp_word_hex
    call disp_nl
    
    mov ax, cx
    call disp_word_hex
    call disp_nl
    
    mov ax, dx
    call disp_word_hex
    call disp_nl
    jmp ._ehdd_check
    ;
    ; 結果
    ; 0000  : 0番だけ有効（1シリンダ有効）
    ; 003F  : セクタ数63（理論最大値）
    ; 0f01  : ヘッド数16個
    ;
    ; ヘッダは0-15の16個、ドライブは1台利用可能らしい
    ; 147560Byte=288セクタ
    ; この結果はダミー値みたいだね
    ; 31M程度まではセクタ0、ヘッダ0で読めそう？
    ;
._hdd_error:
    mov al, 'E'
    call putc
    call disp_nl

._ehdd_check:
    ;
    ; LBA拡張読み出しの対応チェック
    ; BIOSが Enhanced Disk Drive Services（EDD） に対応しているか確認する。
    ;
    ; bxに0x55aaを送ってエラーなしで0xaa55が返ってくればサポートされてる
    ;
    ;
    
    
    mov ax, 0x4100
    mov bx, 0x55aa
    mov dl, 0x80
    int 0x13
    jc ._check_error
    
    mov ax, bx
    call disp_word_hex
    call disp_nl
    jmp ._edd_info

._check_error:
    mov al, 'E'
    call putc
    call disp_nl


._edd_info:
    ;
    ; LBA対応ディスクの詳細情報取得
    ;   HDDの 総容量
    ;   LBAサポートの範囲
    ;   その他 ジオメトリやBIOS能力
    ;
    ;
    ;
    ;
    
    mov ah, 0x48
    mov dl, 0x80
    mov si, 0x1a
    mov bx, _edd_buf
    mov di, bx
    mov bx, ds
    mov es, bx
    int 0x13
    jc ._edd_error

    mov si, _edd_buf
    mov cx, 13
._loop
    mov ax, si
    call disp_word_hex
    mov al, ' '
    call putc
    inc si
    inc si
    loop ._loop


    
;    mov ax, edd_sec
;    mov bx, ds
;    mov cx, 8
;    call disp_mem
;    call disp_nl

;    mov ax, edd_sec
;    mov bx, ds
;    mov cx, 8
;    call disp_mem
;    call disp_nl

;    mov ax, edd_head
;    mov bx, ds
;    mov cx, 4
;    call disp_mem
;    call disp_nl

;    mov ax, edd_sum
;    mov bx, ds
;    mov cx, 4
;    call disp_mem
;    call disp_nl


    jmp ._exit


._edd_error:
    mov al, 'E'
    call putc
    call disp_nl




._exit:



_hlt2:
    hlt
    jmp _hlt2



disp_str2:
    push ds
    mov si, ax
    mov ds, cx
    mov ah, 0x0e
._loop:
    lodsb
    cmp al, 0x00
    je ._exit
    int 0x10
    jmp ._loop
    
._exit:
    pop ds
    ret


_edd_buf :
    edd_size    dw 0x1a
    edd_flsg    dw 0
                dw 0
    edd_sec     dw 0
                dw 0
                dw 0
                dw 0
    edd_head    dw 0
                dw 0
    edd_sum     dw 0
                dw 0

buffer:
    dw 0x1A          ; 構造体サイズ（オフセット0） ← SIと一致させる
    times 0x1A - 2 db 0  ; 残りをゼロクリア


%include "routine.asm"

times 2048-($-$$) -2 db 0
dw 0x5E5E
