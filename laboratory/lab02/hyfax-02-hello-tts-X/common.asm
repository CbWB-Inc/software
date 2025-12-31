; ============================================================
; common.asm - 共通ルーチン群
; ============================================================
 BITS 16
 SECTION .text

%define STACK_SEG  0x0050
%define BUF_SEG    0x09E0
%define BUF_OFF    0x0000
%define PART_LBA   2048          ; 物理パーティション先頭（VBRのLBA）
%define APP_SEG    0x1000
%define APP_OFF    0x0000
%define MON_SEG    0x0050
%define MON_ADDR    0x0000
%define PART_OFFSET 2048

global ps
global pc
global pcd
global psd
global phd1
global phd2
global phd4
global dump_mem

global memcpy

global exit_return

; ds:ax -> es:bx , cx Byte
memcpy:
  push ax
  push bx
  push cx
  push si
  push di

  mov si, ax
  mov di, bx
.loop:
  mov al, ds:[si]
  mov es:[di], al
  inc si
  inc di
  loop .loop

  pop di
  pop si
  pop cx
  pop bx
  pop ax

  ret

memset:
  push ax
  push bx
  push cx
  push di

  mov di, ax
.loop:
  mov ds:[di], bl
  inc di
  loop .loop

  pop di
  pop cx
  pop bx
  pop ax

  ret

ps:
  push ax
  mov si, ax
.loop:
  lodsb
  test al, al
  jz .exit
  mov ah, 0x0e
  int 0x10
  jmp .loop
.exit:
  pop ax
  ret

pc:
  push ax
  mov ah, 0x0e
  int 0x10
  pop ax
  ret

; --- Debug Output (Bochs/VMware port E9)
pcd:
  push ax
  out 0xE9, al
  pop ax
  ret

psd:
  mov si, ax
.loop:
  lodsb
  cmp al, 0
  je .exit
  push ax
  out 0xE9, al
  pop ax
  jmp .loop
.exit:
  ret

phd4:
  push ax
  mov al, ah
  call phd2
  pop ax
  ; push ax
  call phd2
  ; pop ax
  ret


phd2:
    push ax
    shr al, 4
    call phd1
    pop ax
    call phd1
    ret
  ; push ax
  ; shr al, 4
  ; call phd1
  ; pop ax
  ; push ax
  ; call phd1
  ; pop ax
  ; ret



phd1:
        push ax
        and al, 0x0f
        cmp al, 0x09
        ja .gt_9
        add al, 0x30
        jmp .cnv_end
.gt_9:
        add al, 0x37

.cnv_end:
        out 0xE9, al
        ; mov bl, al
        pop ax
        ret

; phd2:
;   push ax
;   mov ah, al
;   shr al, 4
;   call .n
;   mov al, ah
;   and al, 0x0F
;   call .n
;   pop ax
;   ret
; .n:
;   cmp al, 9
;   jbe .d
;   add al, 'A' - 10
;   jmp .o
; .d:
;   add al, '0'
; .o:
;   push ax
;   out 0xE9, al
;   pop ax
;   ret

dump_mem:
    push si
    push cx
    push ax
.next:
    test cx, cx
    jz .done
    mov al, [es:si]
    call phd2
    mov al, ' '
    out 0xE9, al
    inc si
    dec cx
    jmp .next
.done:
    pop ax
    pop cx
    pop si
    ret

strlen:
    mov si, ax
    xor cx, cx
.loop:
    cmp byte [si], 0x00
    jz .exit
    inc cx
    inc si
    jmp .loop
.exit:
    ret

; strcpy_ds
; IN : AX=dst_off, BX=src_off (both in DS)
; OUT: CX=bytes copied (not including NUL)
; CLOBBER: AX, CX
strcpy:
    push di
    push si

    mov di, ax
    mov si, bx
    xor cx, cx

.loop:
    mov al, [si]
    mov [di], al
    inc si
    inc di
    cmp al, 0
    je  .done
    inc cx
    jmp .loop

.done:
    pop si
    pop di
    ret

; strcmp
; DS:SI = s1
; DS:DI = s2
; AX = result (0, <0, >0)

strcmp:
.loop:
    mov al, [si]
    mov bl, [di]
    cmp al, bl
    jne .diff

    test al, al      ; 両方 0 なら終端
    je .equal

    inc si
    inc di
    jmp .loop

.diff:
    ; AX = (signed)al - (signed)bl
    mov ah, 0
    mov bh, 0
    sub ax, bx
    ret

.equal:
    xor ax, ax
    ret

exit_return:
    ; --- モニタへ戻る ---
    ; 既定：MON_SEG:0000 に戻る（monitor側の戻り口が0x0000想定）
    push word MON_SEG
    push word 0x0000
    retf
   
