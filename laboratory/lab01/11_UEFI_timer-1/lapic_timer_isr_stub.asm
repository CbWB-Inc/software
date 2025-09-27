BITS 64
default rel
section .text
global  lapic_timer_isr_stub
extern  lapic_base
extern  isr_timer_hook
extern get_current_rsp

extern  puthex
extern  puthexdbg

align 16

section .bss
iret_sandbox:  resq 3     ; [0]=RIP, [1]=CS, [2]=RFLAGS
align 16
gdt_snap:  resb 16
idtr_s:    resb 10
gdtr_s:    resb 10

section .text

lapic_timer_isr_stub:
    ; GPRs保存 (15個)
    push rax
    push rcx
    push rdx
    push rsi
    push rdi
    push r8
    push r9
    push r10
    push r11
    push rbx
    push rbp
    push r12
    push r13
    push r14
    push r15

    mov     r13, rsp

    ; call前: RSP%16==8 に調整
    mov     rax, rsp
    and     rax, 15
    xor     r12, r12
    cmp     rax, 8
    je      .aligned8
    sub     rsp, 8
    mov     r12, 8
.aligned8:
    sub     rsp, 2048             ; red zone を塞ぐ
    mov     rdi, r13
    call    isr_timer_hook       ; rax = next_rsp or 0
    add     rsp, 2048

    mov     r14, rax             ; next_rsp を保存

    ; LAPIC EOI
    mov     rdx, [rel lapic_base]
    mov     dword [rdx+0xB0], 0

    cli
    test    r14, r14
    jz      .no_switch

    ; ===== タスクスイッチ処理 =====
    ; 現在のスタックポインタ位置でGPRs復元の準備
    ; r12には整列調整値が入っている
    test    r12, r12
    jz      .restore_switch
    add     rsp, 8               ; 整列調整を戻す
.restore_switch:

    ; 新しいタスクのスタック（next_rsp）に切り替え
    ; next_rspは保存されたGPRsを指している
    mov     rsp, r14

    ; 新タスクのコンテキストでGPRs復元
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbp
    pop     rbx
    pop     r11
    pop     r10
    pop     r9
    pop     r8
    pop     rdi
    pop     rsi
    pop     rdx
    pop     rcx
    pop     rax

    ; カーネル空間同士なので、iretフレームはそのまま元の割り込み元に戻る
    iretq

.no_switch:
    ; スイッチしない場合：元のスタックでGPRs復元
    test    r12, r12
    jz      .restore_nosw
    add     rsp, 8
.restore_nosw:
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbp
    pop     rbx
    pop     r11
    pop     r10
    pop     r9
    pop     r8
    pop     rdi
    pop     rsi
    pop     rdx
    pop     rcx
    pop     rax

    iretq