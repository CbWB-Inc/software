; === keyboard IRQ stub (vector 0x61) ===
global  mouse_isr_stub
extern  mouse_isr_c
extern  lapic_base
section .text
align 16
mouse_isr_stub:
    ; GPR save（timerと同じ順）
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

    ; SysV call 整列 (RSP%16==8なら調整不要)
    mov rax, rsp
    and rax, 15
    mov r12, 0
    cmp rax, 8
    je  .aligned
    sub rsp, 8
    mov r12, 8
.aligned:
    sub rsp, 128            ; red-zone封じ
    call mouse_isr_c
    add rsp, 128
    test r12, r12
    jz  .noadj
    add rsp, 8
.noadj:

    ; LAPIC EOI
    mov rdx, [rel lapic_base]
    test rdx, rdx
    jz  .no_eoi
    mov dword [rdx + 0xB0], 0
    mov eax,  dword [rdx + 0x20]
.no_eoi:

    ; GPR restore → iretq（RFLAGSはCPUが積んだ物をそのままiretで戻す）
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    pop rbx
    pop r11
    pop r10
    pop r9
    pop r8
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rax
    iretq
    