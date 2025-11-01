;>===========================
;>      BIOSと戯れてみる
;>===========================
BITS 16
ORG 0x7C00

start:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00
    sti

.load:
    ; --- Disk address packet (for INT 13h AH=42h) ---
    mov si, dap
    mov dl, 0x80           ; HDD (0x00=FDD)
    mov ah, 0x42           ; Extended Read
    int 0x13
    jc  .fail

    mov si, 0x8000
    mov cx, 0x10
    call dump_mem

    jmp .hlt
    
.fail:
    mov al, ah
    call ph1
    mov al, ':'
    call pc
    mov si, msg_fail
    call ps
.showfail:
    lodsb
    or  al, al
    jz  .hlt
    mov ah, 0x0E
    int 0x10
    jmp .showfail

.hlt:
    hlt
    jmp .hlt

; --- メッセージ ---
msg_fail  db "Disk read error!", 0x0D,0x0A,0

; --- DAP構造体 (16バイト) ---
align 16
dap:
    db 0x10        ; size of packet (16 bytes)
    db 0x00        ; reserved
    dw 1           ; sectors to read (1)
    dw 0x8000      ; offset to load
    dw 0x0000      ; segment to load
    dq 0           ; LBA of VBR (boot1) ひとつだけあるパーティションのVBRを決め打ち。パーティションテーブルの検査はしない。


;>****************************
;> pc : 1文字出力
;>****************************
pc:
    push ax
    mov ah, 0x0e
    int 0x10
    pop ax
    ret

;>****************************
;> ps : 文字列出力
;>****************************
ps:
    push ax
    push si
    mov si, ax
.loop:
    lodsb
    test al, al
    jz .exit
    call pc
    jmp .loop
.exit:
    pop si
    pop ax
    ret

;>****************************
;> ph1 : 1Byteを16進で出力
;>****************************
ph1:
    push ax
    mov ah, al
    shr al, 4
    call .n
    mov al, ah
    and al, 0x0F
    call .n
    pop ax
    ret
.n:
    cmp al, 9
    jbe .d
    add al, 'A' - 10
    jmp .o
.d:
    add al, '0'
.o:
    call pc
    ret

;>****************************
;> dump_mem : メモリダンプ
;>****************************
dump_mem:
    push si
.next:
    test cx, cx
    jz .done
    mov al, [es:si]
    call ph1
    mov al, ' '
    call pc
    inc si
    dec cx
    jmp .next
.done:
    pop si
    ret


; --- パーティションテーブル + シグネチャ ---
times 446-($-$$) db 0               ; boot code: 446 bytes total
; partition entry 1 (bootable, FAT16, start=2048, length=18432)
db 0x80, 0x01, 0x01, 0x00, 0x06, 0xFE, 0x3F, 0x0F, 0x00, 0x08, 0x00, 0x00, 0x00, 0x48, 0x00, 0x00
times 64-16 db 0                   ; remaining partition entries
dw 0xAA55

Sector1 db 0x01, 'SECTOR 1', 0x0a, 0x0d, 0x00

times 1024-($-$$) db 0

Sector2 db 0x02, 'SECTOR 2', 0x0a, 0x0d, 0x00

times 2048-($-$$) db 0
