; =========================
; Page Allocator (4KB, bitmap, linear scan) - SAFE REAL MODE
; FIX: CXレジスタを保護（マクロ内でCLを使用するため）
; FIX: page_freeの引数をDX:BXに変更（AHがサービス番号で使用されるため）
; =========================

BITS 16

PAGE_SHIFT        equ 12
PAGE_SIZE         equ (1 << PAGE_SHIFT)

MANAGED_BASE      equ 0x10000
MANAGED_BASE_PAGE equ (MANAGED_BASE >> PAGE_SHIFT)   ; = 0x10
MANAGED_SEG       equ (MANAGED_BASE >> 4)            ; = 0x1000

; ---- globals (Monitor常駐) ----
g_managed_end  dd 0
g_num_pages    dw 0
g_scan_hint    dw 0
bitmap_seg     dw 0

; ---------------------------------
; bitmap helpers - FIXED: CXを保護
; ---------------------------------
%macro BIT_TEST 1
    push cx
    mov di, bx
    shr di, 3
    mov al, [es:di]
    mov cl, bl
    and cl, 7
    shr al, cl
    and al, 1
    mov %1, al
    pop cx
%endmacro

%macro BIT_SET 0
    push cx
    mov di, bx
    shr di, 3
    mov al, [es:di]
    mov cl, bl
    and cl, 7
    mov ah, 1
    shl ah, cl
    or  al, ah
    mov [es:di], al
    pop cx
%endmacro

%macro BIT_CLR 0
    push cx
    mov di, bx
    shr di, 3
    mov al, [es:di]
    mov cl, bl
    and cl, 7
    mov ah, 1
    shl ah, cl
    not ah
    and al, ah
    mov [es:di], al
    pop cx
%endmacro

; ---------------------------------
; page_init
; DX:AX = managed_end physical address
; ---------------------------------
page_init:
    push ax
    push dx
    push bx
    push cx
    push di
    push es

    mov bx, MANAGED_SEG
    mov [cs:bitmap_seg], bx
    mov es, bx

    and ax, 0xF000

    mov [cs:g_managed_end], ax
    mov [cs:g_managed_end+2], dx

    mov bx, dx
    shl bx, 4
    mov cx, ax
    shr cx, 12
    or  bx, cx

    sub bx, MANAGED_BASE_PAGE
    mov [cs:g_num_pages], bx

    mov cx, bx
    add cx, 7
    shr cx, 3

    xor di, di
.clear:
    mov byte [es:di], 0
    inc di
    loop .clear

    mov si, [MHS_OFF]
    mov ax, [si + MHS.cnt]
    cmp ax, 0
    je .free_skip
    mov cx, ax
.free_loop:
    mov bx, cx
    shl bx, 1
    mov ax, [si + MHS.AXs + bx] 
    mov dx, [si + MHS.DXs + bx]
    mov bx, ax
    shl dx, 12
    mov ah, svc_page_free
    int 0x80
    loop .free_loop
.free_skip:

    xor bx, bx
    BIT_SET

    xor ax, ax
    mov [cs:g_scan_hint], ax

    pop es
    pop di
    pop cx
    pop bx
    pop dx
    pop ax
    ret

; ---------------------------------
; page_alloc
; ---------------------------------
page_alloc:
    push bx
    push cx
    push di
    push es

    mov ax, [cs:bitmap_seg]
    mov es, ax

    mov bx, [cs:g_scan_hint]
    mov cx, [cs:g_num_pages]

.scan1:
    cmp bx, cx
    jae .scan2

    BIT_TEST al
    cmp al, 0
    jne .next1

    BIT_SET

    mov ax, bx
    inc ax
    mov [cs:g_scan_hint], ax

    mov ax, bx
    add ax, MANAGED_BASE_PAGE

    mov dx, ax
    shl ax, 12
    shr dx, 4
    jmp .ok

.next1:
    inc bx
    jmp .scan1

.scan2:
    xor bx, bx

.scan2_loop:
    cmp bx, [cs:g_scan_hint]
    jae .fail

    BIT_TEST al
    cmp al, 0
    jne .next2

    BIT_SET

    mov ax, bx
    inc ax
    mov [cs:g_scan_hint], ax

    mov ax, bx
    add ax, MANAGED_BASE_PAGE

    mov dx, ax
    shl ax, 12
    shr dx, 4
    clc
    jmp .ok

.next2:
    inc bx
    jmp .scan2_loop

.fail:
    xor ax, ax
    xor dx, dx
    stc

.ok:
    pop es
    pop di
    pop cx
    pop bx
    ret

; ---------------------------------
; page_free
; 入力：DX:BX = ページ先頭物理アドレス 
; 出力：AX=0 成功 / AX!=0 エラー
; ---------------------------------
page_free:
    push bx
    push cx
    push di
    push es

    mov si, bx              ; BXを保存（AXの代わり）

    mov ax, [cs:bitmap_seg]
    mov es, ax

    ; range check: addr >= 0x0001:0000 (0x10000)
    cmp dx, 0x0001
    jb  .err
    jne .chk_align
    cmp si, 0x0000
    jb  .err

.chk_align:
    ; 4KB align check: low 12 bits must be 0
    test si, 0x0FFF
    jnz .err

    ; page_num = addr >> 12 = (DX<<4) | (BX>>12)
    mov bx, dx
    shl bx, 4
    mov cx, si
    shr cx, 12
    or  bx, cx              ; BX = page_num (absolute)

    ; index = page_num - MANAGED_BASE_PAGE
    sub bx, MANAGED_BASE_PAGE

    ; index 0 is reserved
    cmp bx, 0
    je  .err

    ; index < num_pages ?
    cmp bx, [cs:g_num_pages]
    jae .err

    ; double-free check: must be allocated
    BIT_TEST al
    cmp al, 1
    jne .err

    BIT_CLR
    xor ax, ax
    clc

    jmp .ok

.err:
    mov ax, 1
    stc

.ok:
    pop es
    pop di
    pop cx
    pop bx
    ret
