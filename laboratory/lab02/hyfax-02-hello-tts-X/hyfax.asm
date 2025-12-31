

%define STACK_SEG   0x0050
%define BUF_SEG     0x0960
%define BUF_OFF     0x0000
%define BOOT1_SEG   0x0800
%define BOOT1_OFF   0x0000
%define APP_SEG     0x1000
%define APP_OFF     0x0000
%define MON_SEG     0x0050
%define MON_OFF     0x0000
%define TTS_SEG     0x0600
%define TTS_OFF     0x0000
%define PART_TBL_OFF    0x9000
%define BPB_ADDR        0x9100
%define BOOT_DRV_OFF    0x9040
%define VBR_START_LBA   0x9042
%define FAT_START_LBA   0x9046
%define DIR_START_LBA   0x904A
%define DATA_START_LBA  0x904E
%define SEC_PER_CLUS_OFF    0x9050
%define CLUS_SIZ_OFF     0x9052
%define BYTE_PER_SEC_OFF 0x905D
%define ROOT_ENT_CNT_OFF 0x9060
%define PART_TBL_OFF 446
%define PART_ENT_SZ  16
%define VBR_SECTORS 1
%define ENT_SECTORS 1

%define svc_write   0x20
%define svc_puthex  0x21
%define svc_getkey  0x22
%define svc_putchar 0x23
%define svc_newline 0x24
%define svc_cls     0x25
%define svc_wreboot 0x26

%define line_buf_size 256

; ============================
; パーティションエントリ構造体 (16バイト)
; ============================
struc PART_ENTRY
    .boot_flag  resb 1
    .chs_start  resb 3
    .type       resb 1
    .chs_end    resb 3
    .lba_start  resd 1
    .sectors    resd 1
endstruc

;==========================================
; BIOS Parameter Block (BPB) + Extended BPB
; 対応: FAT12 / FAT16 / FAT32
;==========================================

struc BPB_FAT16
    ; --- 標準BPB部分（共通） ---
    .jmpBoot        resb 3      ; JMP命令 (例: EB 58 90)
    .OEMName        resb 8      ; OEM名 ("MSDOS5.0" など)
    .BytesPerSec    resw 1      ; セクタサイズ (通常 512)
    .SecPerClus     resb 1      ; 1クラスタあたりのセクタ数
    .RsvdSecCnt     resw 1      ; 予約セクタ数 (FATの前)
    .NumFATs        resb 1      ; FATテーブル数 (通常2)
    .RootEntCnt     resw 1      ; ルートディレクトリエントリ数 (FAT32では0)
    .TotSec16       resw 1      ; 総セクタ数 (小容量用)
    .Media          resb 1      ; メディアタイプ (0xF8=HDD)
    .FATSz16        resw 1      ; FATサイズ (FAT12/16のみ)
    .SecPerTrk      resw 1      ; トラックあたりセクタ数
    .NumHeads       resw 1      ; ヘッド数
    .HiddSec        resd 1      ; 隠しセクタ数
    .TotSec32       resd 1      ; 総セクタ数 (大容量用)

    ; ; --- FAT32拡張BPB部分 ---
    ; .FATSz32        resd 1      ; FAT1つのサイズ (セクタ単位)
    ; .ExtFlags       resw 1      ; 拡張フラグ (ミラー制御など)
    ; .FSVer          resw 1      ; FATバージョン (0x0000)
    ; .RootClus       resd 1      ; ルートディレクトリ開始クラスタ
    ; .FSInfo         resw 1      ; FSINFOセクタ番号
    ; .BkBootSec      resw 1      ; ブートセクタのバックアップ位置
    ; .Reserved       resb 12     ; 将来予約
    ; .DrvNum         resb 1      ; ドライブ番号 (INT13h DL値)
    ; .Reserved1      resb 1      ; 予約（0）
    ; .BootSig        resb 1      ; 拡張ブートシグネチャ (0x29)
    ; .VolID          resd 1      ; ボリュームシリアル番号
    ; .VolLab         resb 11     ; ボリュームラベル (空白埋め)
    ; .FilSysType     resb 8      ; ファイルシステム名 ("FAT32  ")
endstruc

;==========================================
; Disk Address Packet (DAP)
; for INT 13h AH=42h/43h
;==========================================
struc DAP
    .Size       resb 1      ; 構造体のサイズ (必ず16)
    .Reserved   resb 1      ; 予約 (0)
    .NumBlocks  resw 1      ; 読み/書きするセクタ数
    .BufferOff  resw 1      ; 転送先バッファのオフセット
    .BufferSeg  resw 1      ; 転送先バッファのセグメント
    .LBA_Low    resd 1      ; 開始LBA下位16bit
    .LBA_High   resd 1      ; 開始LBA上位32bit
endstruc

;===============================
; FAT Directory Entry (32 bytes)
; FAT16 / FAT32 共通
;===============================
struc DIR_ENTRY
    .Name        resb 8     ; 00h ファイル名
    .Ext         resb 3     ; 08h 拡張子
    .Attr        resb 1     ; 0Bh 属性
    .NTRes       resb 1     ; 0Ch 予約 (NT)
    .CrtTime10   resb 1     ; 0Dh 作成時刻10ms
    .CrtTime     resw 1     ; 0Eh 作成時刻
    .CrtDate     resw 1     ; 10h 作成日
    .LstAccDate  resw 1     ; 12h アクセス日
    .FstClusHI   resw 1     ; 14h 上位クラスタ番号 (FAT32)
    .WrtTime     resw 1     ; 16h 更新時刻
    .WrtDate     resw 1     ; 18h 更新日
    .FstClusLO   resw 1     ; 1Ah 下位クラスタ番号
    .FileSize    resd 1     ; 1Ch ファイルサイズ
endstruc

;===============================
; Token Handle Structure
;===============================
struc THS
    .off    resw 126   ; 02h オフセット
    .cnt    resw 1     ; 04h Item Num
endstruc

;===============================
; String Handle Structure
;===============================
struc SHS
    .off    resb 256   ; 02h オフセット
    .seg    resw 1     ; 00h セグメント
    .len    resw 1     ; 04h length
endstruc
