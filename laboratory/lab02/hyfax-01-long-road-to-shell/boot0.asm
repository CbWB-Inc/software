; ============================================================
; boot0.asm  -- Minimal MBR loader (for HDD, loads boot1 at LBA=2048)
; 制約: FAT16フォーマットのみ対応
; ============================================================

BITS 16
ORG 0x7C00

   MBR_BASE equ 0x7C00

  %include 'hyfax.asm'

%macro PUTC 1
    push ax
    mov  al, %1
    out  0xE9, al
    pop  ax
%endmacro

start:
    PUTC 'B'
    PUTC '0'
    PUTC ':'

    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, MBR_BASE
    sti

    mov [BOOT_DRIVE], dl

    ; --- 表示（任意） ---
    mov ax, msg_boot0
    call ps

.load:
    ; -----------------------------------
    ; boot driveの保存
    ; -----------------------------------
    xor ax, ax
    mov es, ax
    mov al, [BOOT_DRIVE]
    mov es:[BOOT_DRV_OFF], al
    
    ; -----------------------------------
    ; boot_indicatorを4件分検査
    ; -----------------------------------
    mov si, MBR_BASE     ; MBR先頭
    add si, PART_TBL_OFF ; パーティションテーブル開始位置
    mov cx, 4            ; 4エントリ
.show_loop:              ; ブート可能な最初のエントリを探す
    mov al, [si]         ; boot_indicator
    cmp al, 0x80         ; ブート可能か
    je .boot_ok
    add si, PART_ENT_SZ  ; 次のエントリ
    loop .show_loop

    mov ax, msg_fail2    ; ブート可能パーティションなし
    call ps

    jmp .hlt

.boot_ok:

    ; -----------------------------------
    ; VBR_START_LBAの保存
    ; -----------------------------------
    mov ax, [si + PART_ENTRY.lba_start]      ; start_lba VBR開始LBA
    mov es:[VBR_START_LBA], ax    


    ; --- Disk address packet (for INT 13h AH=42h) ---
    ; VBRを読み込む。コード節約のため最低限の設定しかしていない。
    push cs
    pop ds
    mov si, dap
    mov ax, es:[VBR_START_LBA]
    mov      [si + DAP.LBA_Low   ], ax         ; VBRのLBAを設定
    mov word [si + DAP.LBA_High  ], 0 
    ; mov dl, [BOOT_DRIVE]   ; HDD (0x00=FDD)
    mov dl, es:[BOOT_DRV_OFF]   ; HDD (0x00=FDD)
    mov ah, 0x42           ; Extended Read
    int 0x13
    jc  .fail

    pop es
    pop ds

    mov ax, BOOT1_SEG
    mov es, ax
    xor ax, ax
    mov ds, ax
    mov si, BOOT1_OFF
    ; -----------------------------------
    ; ROOT_ENT_CNTの保存
    ; -----------------------------------
    mov ax, es:[si + BPB_FAT16.RootEntCnt]
    mov ds:[ROOT_ENT_CNT_OFF], ax
    ; -----------------------------------
    ; FAT開始LBAの保存
    ; -----------------------------------
    mov si, BOOT1_OFF
    mov ax, es:[si + BPB_FAT16.RsvdSecCnt]
    add ax, ds:[VBR_START_LBA]
    mov ds:[FAT_START_LBA], ax
    ; -----------------------------------
    ; DATA開始LBAの保存
    ; -----------------------------------
    xor bx, bx
    mov bl, es:[si + BPB_FAT16.NumFATs]
    mov ax, es:[si + BPB_FAT16.FATSz16]
    mov bh, 0
    mul bx
    add ax, ds:[FAT_START_LBA]
    mov ds:[DIR_START_LBA], ax
    ; -----------------------------------
    ; SEC_PER_CLUS, CLUS_SIZの保存
    ; -----------------------------------
    mov al, es:[si + BPB_FAT16.SecPerClus]
    mov ds:[SEC_PER_CLUS_OFF], al
    mov ah, 0
    mov bx, es:[si + BPB_FAT16.BytesPerSec]
    mov ds:[BYTE_PER_SEC_OFF], bx
    mul bx
    mov ds:[CLUS_SIZ_OFF], ax

    mov ax, ds:[ROOT_ENT_CNT_OFF]
    mov bx, 32
    mul bx
    mov bx, es:[si + BPB_FAT16.BytesPerSec]
    div bx
    add ax, ds:[DIR_START_LBA]
    ; shr ax, 9
    mov ds:[DATA_START_LBA], ax

    ; -----------------------------------
    ; boot1へ遷移
    ; -----------------------------------
    jmp BOOT1_SEG:BOOT1_OFF ; jump to boot1 (VBR)

    ; push BOOT1_SEG
    ; push BOOT1_OFF
    ; retf


.fail:
    mov al, ah
    call phd1
    mov ax, msg_fail
    call ps

.hlt:
    hlt
    jmp .hlt

ps:
    mov si, ax
.print:
    lodsb
    or  al, al
    jz  .exit
    mov ah, 0x0E
    int 0x10
    jmp .print
.exit:
    ret

phd1:
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
  push ax
  out 0xE9, al
  pop ax
  ret

phd2:
  push ax
  mov al, ah
  call phd1
  pop ax
  push ax
  call phd1
  pop ax
  ret

; ds:ax -> es:bx , cx Byte
memcpy:
  push ax
  push bx
  push cx

  mov si, ax
  mov di, bx
.loop:
  mov al, ds:[si]
  mov es:[di], al
  inc si
  inc di
  loop .loop

  pop cx
  pop bx
  pop ax

  ret


BOOT_DRIVE  db 0x0

; --- メッセージ ---
; msg_boot0 db "B0: loading Boot1...", 0x0D,0x0A,0
; msg_fail  db "B0: Disk error!", 0x0D,0x0A,0
; msg_fail2 db "B0: Not Bootable", 0x0D,0x0A,0
msg_boot0 db "B0:loading Boot1...", 0x0D,0x0A,0
msg_fail  db " Disk error!", 0x0D,0x0A,0
msg_fail2 db " Not Bootable", 0x0D,0x0A,0


; --- DAP構造体 (16バイト) ---
align 16
dap:
    db 0x10        ; size of packet (16 bytes)
    db 0x00        ; reserved
    dw 4           ; sectors to read (1)
    dw BOOT1_OFF   ; offset to load
    dw BOOT1_SEG   ; segment to load
    dq 0           ; LBA of VBR 

times 446-($-$$) db 0               ; boot code: 446 bytes total
; --- パーティションテーブル + シグネチャ ---
; partition entry 1 (bootable, FAT16, start=2048, length=18432)
; PARTITION_ENTRY:
;     boot_indicator  db 0x80
;     start_head      db 0x01
;     start_sector    db 0x01
;     start_cylinder  db 0x00
;     partition_type  db 0x06
;     end_head        db 0xFE
;     end_sector      db 0x3F
;     end_cylinder    db 0x0F
;     start_lba_l     dw 0x0800
;     start_lba_h     dw 0x0000
;     total_sectors_l dw 0x4800
;     total_sectors_h dw 0x0000
; times 64-16 db 0                   ; remaining partition entries
; dw 0xAA55