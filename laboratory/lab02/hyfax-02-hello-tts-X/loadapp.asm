[BITS 16]

loadapp:

    mov [TARGET_APP_NAME], ax
    mov ax, es
    mov [TARGET_APP_SEG], ax
    mov [TARGET_APP_OFF], bx

    xor ax, ax
    mov es, ax
    ; -----------------------------------
    ; Bootドライブ
    ; -----------------------------------
    mov al, es:[BOOT_DRV_OFF]
    mov [BOOT_DRIVE], al
    ; -----------------------------------
    ; VBR_LBA = start_lba
    ; -----------------------------------
    mov ax, es:[VBR_START_LBA]
    mov word [VBR_LBA], ax
    ; -----------------------------------
    ; SEC_PER_CLUS
    ; -----------------------------------
    mov al, es:[SEC_PER_CLUS_OFF]
    mov byte [SEC_PER_CLUS], al
    ; -----------------------------------
    ; ROOT_ENT_CNT
    ; -----------------------------------
    mov ax, es:[ROOT_ENT_CNT_OFF]
    mov [ROOT_ENT_CNT], ax
    ; -----------------------------------
    ; FAT_LBA
    ; -----------------------------------
    mov ax, es:[FAT_START_LBA]
    mov [FAT_LBA], ax
    ; -----------------------------------
    ; DATA_LBA
    ; -----------------------------------
    mov ax, es:[DATA_START_LBA]
    mov word [DATA_LBA], ax
    ; -----------------------------------
    ; DIR_LBA
    ; -----------------------------------
    mov ax, es:[DIR_START_LBA]
    mov [DIR_LBA], ax
    ; -----------------------------------
    ; CLUS_SIZ
    ; -----------------------------------
    mov ax, es:[CLUS_SIZ_OFF]
    mov [CLUS_SIZ], ax
    ; -----------------------------------
    ; BYTE_PER_SEC
    ; -----------------------------------
    mov ax, es:[BYTE_PER_SEC_OFF]
    mov [BYTE_PER_SEC], ax
    mov [BYTE_PER_SEC_SAVE], ax

    ; --- 転送先を設定 ---
    mov bx, BUF_SEG
    mov es, bx
    mov bx, BUF_OFF
    
    ; -----------------------------------
    ; Dir EntからTarget Fileのエントリを探す
    ; -----------------------------------
    mov ax, [ROOT_ENT_CNT]
    mov bx, 32
    mul bx
    mov bx, [BYTE_PER_SEC]
    div bx
    mov word [DIR_ENT_SEC_CNT], ax

    mov ax, [DIR_LBA]
    mov si, [TARGET_APP_NAME]

dir_ent_sec_loop:

PUTC '+'

    ; -----------------------------------
    ; Dir Entを読み込む
    ; -----------------------------------
    ; Dir Entを読み込むための設定
    mov si, dap
    mov word [si + DAP.NumBlocks], ENT_SECTORS ; sectors
    mov word [si + DAP.BufferOff], BUF_OFF     ; buffer offset
    mov word [si + DAP.BufferSeg], BUF_SEG     ; buffer segment
    mov ax, [DIR_LBA]
    mov word [si + DAP.LBA_Low],   ax ; LBA low Low
    mov dword [si + DAP.LBA_High],  0 ; LBA high
    mov dl, [BOOT_DRIVE]
    mov ah, 0x42
    int 0x13

    jc disk_error

    mov di, BUF_OFF
    mov cx, 16

find_entry:

    mov al, es:[di]
    cmp al, 0x00
    je not_found
    cmp al, 0xE5
    je next_entry
    mov al, es:[di+11]
    test al, 0x18          ; Volume or Dir
    jnz next_entry

    ; --- compare 11 bytes "MONITOR BIN" ---
    push di
    mov si, [TARGET_APP_NAME]
    
    mov bx, 11
cmp_loop:
    mov al, es:[di]
    mov ah, [si]

    ; for debug
    ; PUTC '['
    ; PUTC ah
    ; PUTC ':'
    ; PUTC al
    ; PUTC ']'

    cmp al, ah
    jne cmp_ng
    inc di
    inc si
    dec bx
    jnz cmp_loop
    jmp find_dir_ent

cmp_ng:
    pop di
next_entry:
    add di, 32
    loop find_entry
next_sec:
    mov ax, [DIR_LBA]
    inc ax
    mov [DIR_LBA], ax
    mov ax, [DIR_ENT_SEC_CNT]
    dec ax
    mov [DIR_ENT_SEC_CNT], ax
    cmp ax, 0
    jnz dir_ent_sec_loop

not_found:
    mov al, 'N'
    out 0xE9, al
    stc                     ; CF=1 (ファイル未発見)
    jmp done

disk_error:
    mov al, 'X'
    out 0xE9, al
    mov al, ah
    call phd2
    stc                     ; CF=1 (ディスクエラー)
    jmp hlt

find_dir_ent:
find_dir_ent:
    ; --- 一致 ---
    ; クラスタ・LBA変換
    pop di
    mov bx, es:[di+26]        ; FirstCluster low
    mov ax, es:[di+20]        ; FirstCluster high
    mov [TARGET_CLUS], bx       ; ファイルのあるクラスタ
    sub bx, 2
    mov al, [SEC_PER_CLUS]
    mov ah, 0
    mul bx
    mov bx, ax
    mov ax, [DATA_LBA]          ; データ開始LBA
    add ax, bx
    mov [FILE_LBA], ax          ; ファイルのLBA

    ; ファイルサイズ・セクタ変換
    mov ax, es:[di+28]          ; File size low word
    add ax, 511
    shr ax, 9
    mov [FILE_SECTOR], ax       ; ファイルのセクタ数

    mov cx, 0
file_read_loop:
    PUTC '.'
    mov si, dap
    mov ax, [SEC_PER_CLUS]
    mov word [si + DAP.NumBlocks], ax ; sectors
    mov ax, [SEC_PER_CLUS]
    mov bx, [BYTE_PER_SEC_SAVE]
    mov [BYTE_PER_SEC], bx

    ; === 【修正】転送先アドレス計算 ===
    ; 
    ; セグメント = TARGET_APP_SEG + (cluster_index * paragraphs_per_cluster)
    ; paragraphs_per_cluster = SEC_PER_CLUS * 32
    ;
    ; ★ mul の結果は DX:AX に入るので、DX も考慮する
    ;

    ; --- Step 1: paragraphs_per_cluster 計算 ---
    xor dx, dx
    xor ax, ax
    mov al, [SEC_PER_CLUS]
    mov bx, 32
    mul bx              ; AX = SEC_PER_CLUS * 32

    ; --- Step 2: cluster_index * paragraphs_per_cluster ---
    mov bx, ax          ; BX = paragraphs_per_cluster
    mov ax, cx          ; AX = cluster_index (0, 1, 2, ...)
    mul bx              ; DX:AX = cluster_index * paragraphs_per_cluster
    
    ; --- Step 3: BASE + offset の計算 ---
    ; DX:AX (32ビット) を TARGET_APP_SEG (16ビット) に加算
    ; セグメントは 16 バイト単位なので、
    ; DX の値は paragraph 単位で 0x10000 paragraph = 1MB 相当
    ; 実際には DX が 0 でない場合、1MB を超えているので問題
    
    ; とりあえず AX だけを加算（DX != 0 なら警告を出すべき）
    add ax, [TARGET_APP_SEG]
    
    ; DX が 0 でないならエラー（デバッグ用）
    cmp dx, 0
    je .no_overflow
    PUTC '!'
    PUTC 'O'
    PUTC 'V'
    PUTC 'R'
.no_overflow:
    
    mov word [si + DAP.BufferSeg], ax

    mov ax, [TARGET_APP_OFF]    ; 推奨: 0
    mov word [si + DAP.BufferOff], ax
    mov ax, [FILE_LBA]
    mov word [si + DAP.LBA_Low],   ax ; LBA low Low
    mov dword [si + DAP.LBA_High],  0 ; LBA high
    mov dl, [BOOT_DRIVE]
    mov ah, 0x42
    int 0x13

    jc disk_error

    mov ax, [FILE_SECTOR]
    sub ax, [SEC_PER_CLUS]
    mov [FILE_SECTOR], ax
    cmp ax, 0
    jle exit_loop

    inc cx

    ; ------------------------------------------------
    ; FAT16チェーンを辿って次のクラスタを取得する
    ;  current cluster = [TARGET_CLUS]
    ; ------------------------------------------------
    ; ★ FAT16: エントリサイズ 2byte
    ;   offset_bytes = cluster * 2
    ;   FAT_sector   = FAT_LBA + offset_bytes / BytesPerSec
    ;   byte_offset  = offset_bytes % BytesPerSec
    ; ------------------------------------------------

    mov ax, [TARGET_CLUS]    ; 現在のクラスタ番号
    mov bx, 2
    mul bx                   ; DX:AX = cluster * 2 (FAT内オフセット[byte])
    mov bx, [BYTE_PER_SEC]   ; 通常 512
    div bx                   ; AX = FAT内セクタオフセット, DX = セクタ内byteオフセット

    mov [FAT_TARGET_CLUS], ax    ; FAT内セクタオフセットとして再利用
    mov [FAT_TARGET_ENT], dx     ; セクタ内byteオフセット

    ; FATセクタのLBA = FAT_LBA + FAT内セクタオフセット
    mov ax, [FAT_LBA]
    add ax, [FAT_TARGET_CLUS]
    mov [TARGET_FAT_LBA], ax

    ; ------------------------------------------------
    ; FATセクタを1セクタだけBUFへ読み込み
    ; ------------------------------------------------
    mov si, dap
    mov word [si + DAP.NumBlocks], 1      ; FATは1セクタで十分
    mov word [si + DAP.BufferOff], BUF_OFF
    mov word [si + DAP.BufferSeg], BUF_SEG
    mov ax, [TARGET_FAT_LBA]
    mov word [si + DAP.LBA_Low], ax
    mov dword [si + DAP.LBA_High], 0
    mov dl, [BOOT_DRIVE]
    mov ah, 0x42
    int 0x13
    jc disk_error

    ; ------------------------------------------------
    ; 読み込んだFATセクタから次クラスタ取得
    ; ------------------------------------------------
    mov ax, BUF_SEG
    mov es, ax
    mov si, BUF_OFF
    mov bx, [FAT_TARGET_ENT]      ; セクタ内byteオフセット
    add si, bx
    mov ax, [es:si]               ; FAT16なので2バイト読み

    ; ------------------------------------------------
    ; FAT16: 終端判定 (0xFFF8以上をEOFとみなす)
    ; ------------------------------------------------
    cmp ax, 0xFFF8
    jae exit_loop                 ; EOFなので読み込み終了
    cmp ax, 0x0002
    jb  exit_loop                 ; 無効クラスタはとりあえず終了扱い

    ; ------------------------------------------------
    ; 次クラスタ → FILE_LBAへ変換
    ;   clusterN → LBA = DATA_LBA + (clusterN - 2) * SEC_PER_CLUS
    ; ------------------------------------------------
    mov [TARGET_CLUS], ax         ; 現在クラスタを更新

    mov bx, ax                    ; bx = clusterN
    sub bx, 2
    mov al, [SEC_PER_CLUS]
    mov ah, 0
    mul bx                        ; AX = (clusterN - 2) * SEC_PER_CLUS
    mov bx, ax
    mov ax, [DATA_LBA]
    add ax, bx
    mov [FILE_LBA], ax            ; 次クラスタの先頭LBA

    jmp file_read_loop

    clc                     ; CF=0 (成功)
exit_loop:


done:

    ; 読み込んだ内容の冒頭をダンプ（目視確認用）
    ; mov ax, [TARGET_APP_SEG]
    ; mov es, ax
    ; mov si, [TARGET_APP_OFF]
    ; mov cx, 0x20
    ; call dump_mem

    ; mov ax, BOOT1_SEG
    ; mov ds, ax
    ; mov ax, _s_msg_jmp_monitor
    ; call ps


    ret


; _s_filename db 'APPF    BIN', 0x00

_s_msg_start db 'B1:Start', 0x0d, 0x0a, 0x00
_s_msg_jmp_monitor db 'B1:jmp', 0x0d, 0x0a, 0x00
_s_msg_read_monitor db 'B1:read', 0x0a, 0x0d, 0x00

BOOT_DRIVE db 0
SEC_PER_CLUS db 0
ROOT_ENT_CNT dw 0
VBR_LBA dw 0
DATA_LBA dw 0
DIR_LBA dw 0
FILE_SECTOR dw 0
FILE_LBA dw 0
DIR_ENT_LBA dw 0
DIR_ENT_SEC_CNT dw 0
FIRST_CLUS dw 0
TARGET_FAT_LBA dw 0
FAT_TARGET_ENT dw 0
FAT_TARGET_CLUS dw 0
FAT_LBA dw 0
FAT_ENT_CNT dw 0
FILE_TARGET_CLUS dw 0
BYTE_PER_CLUS dw 0
TARGET_CLUS dw 0
CLUS_SIZ dw 0
BYTE_PER_SEC dw 0
BYTE_PER_SEC_SAVE dw 0
TARGET_APP_SEG dw 0
TARGET_APP_OFF dw 0
TARGET_APP_NAME dw 0


align 16
dap:                ; 
    db 0x10, 0x00   ; size / reserved
    dw 0            ; sectors
    dw 0x0000       ; buffer offset
    dw 0x0          ; buffer segment
    dq 0x0          ; LBA (low=2048, high=0)