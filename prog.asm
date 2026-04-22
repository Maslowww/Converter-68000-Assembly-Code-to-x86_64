; =====================================================
; Title        : Parameter Passing Example - x86_64
; Author       : Philip Bourke
; Date         : March 25, 2025
; Module       : Assembly Project II - 2025/2026
;
; Description  :
;   Port of a Motorola 68000 assembly program to x86_64
;   Linux assembly (NASM syntax).
;
;   Prompts user for two integers, adds them via the
;   register_adder subroutine, accumulates a running
;   sum over 3 loop iterations, displays the final total.
;
;   Security vulnerabilities from the original 68000
;   code have been addressed:
;     1. Bounded input buffer (max 20 bytes) prevents
;        stack-based buffer overflow
;     2. Input validation - every character checked
;        before conversion (no blind TRAP #15)
;     3. Signed overflow detection in parse_integer
;        (number too large for 64-bit register)
;     4. Signed overflow detection in register_adder
;        via x86 'jo' instruction
;
; Build:
;   nasm -f elf64 prog.asm -o prog.o
;   ld prog.o -o prog
;   ./prog
;
; Test:
;   nasm -f elf64 prog.asm -o prog.o
;   gcc test_program.c prog.o -o test_program -no-pie -nostartfiles -e main
;   ./test_program
; =====================================================

section .data
    prompt          db  "Enter number: "
    prompt_len      equ $ - prompt

    result_msg      db  "The sum is: "
    result_msg_len  equ $ - result_msg

    final_msg       db  "Final sum is: "
    final_msg_len   equ $ - final_msg

    newline         db  10
    minus_sign      db  '-'

    err_invalid     db  "Error: Invalid input. Please enter an integer.", 10
    err_invalid_len equ $ - err_invalid

    err_overflow    db  "Error: Arithmetic overflow detected.", 10
    err_overflow_len equ $ - err_overflow

section .bss
    input_buf   resb 20
    num1        resq 1
    num2        resq 1

section .text
    global _start
    global register_adder

_start:
    xor     r12, r12
    mov     r13, 3

game_loop:
    mov     rax, 1
    mov     rdi, 1
    lea     rsi, [rel prompt]
    mov     rdx, prompt_len
    syscall

    mov     rax, 0
    mov     rdi, 0
    lea     rsi, [rel input_buf]
    mov     rdx, 20
    syscall

    lea     rdi, [rel input_buf]
    mov     rcx, rax
    call    parse_integer
    cmp     rax, -2
    je      handle_invalid
    mov     [rel num1], rax

    mov     rax, 1
    mov     rdi, 1
    lea     rsi, [rel prompt]
    mov     rdx, prompt_len
    syscall

    mov     rax, 0
    mov     rdi, 0
    lea     rsi, [rel input_buf]
    mov     rdx, 20
    syscall

    lea     rdi, [rel input_buf]
    mov     rcx, rax
    call    parse_integer
    cmp     rax, -2
    je      handle_invalid
    mov     [rel num2], rax

    mov     rdi, [rel num1]
    mov     rsi, [rel num2]
    call    register_adder
    cmp     rax, -1
    je      handle_overflow

    push    rax
    add     r12, rax

    mov     rax, 1
    mov     rdi, 1
    lea     rsi, [rel result_msg]
    mov     rdx, result_msg_len
    syscall

    pop     rdi
    call    print_integer
    call    print_newline

    dec     r13
    jnz     game_loop

    mov     rax, 1
    mov     rdi, 1
    lea     rsi, [rel final_msg]
    mov     rdx, final_msg_len
    syscall

    mov     rdi, r12
    call    print_integer
    call    print_newline

    mov     rax, 60
    xor     rdi, rdi
    syscall

handle_invalid:
    mov     rax, 1
    mov     rdi, 1
    lea     rsi, [rel err_invalid]
    mov     rdx, err_invalid_len
    syscall
    mov     rax, 60
    mov     rdi, 1
    syscall

handle_overflow:
    mov     rax, 1
    mov     rdi, 1
    lea     rsi, [rel err_overflow]
    mov     rdx, err_overflow_len
    syscall
    mov     rax, 60
    mov     rdi, 2
    syscall

register_adder:
    push    rbp
    mov     rbp, rsp
    mov     rax, rdi
    add     rax, rsi
    jo      .overflow
    pop     rbp
    ret
.overflow:
    mov     rax, -1
    pop     rbp
    ret

parse_integer:
    push    rbx
    push    r8
    push    r9
    xor     rax, rax
    xor     r8,  r8
    xor     r9,  r9

.skip_ws:
    test    rcx, rcx
    jz      .invalid
    movzx   rbx, byte [rdi]
    cmp     rbx, ' '
    jne     .check_sign
    inc     rdi
    dec     rcx
    jmp     .skip_ws

.check_sign:
    cmp     rbx, '-'
    jne     .parse_loop
    mov     r8, 1
    inc     rdi
    dec     rcx

.parse_loop:
    test    rcx, rcx
    jz      .check_count
    movzx   rbx, byte [rdi]
    cmp     rbx, 10
    je      .check_count
    cmp     rbx, 13
    je      .check_count
    cmp     rbx, ' '
    je      .check_count
    cmp     rbx, '0'
    jl      .invalid
    cmp     rbx, '9'
    jg      .invalid
    sub     rbx, '0'
    imul    rax, rax, 10
    jo      .invalid
    add     rax, rbx
    jo      .invalid
    inc     r9
    inc     rdi
    dec     rcx
    jmp     .parse_loop

.check_count:
    test    r9, r9
    jz      .invalid
    test    r8, r8
    jz      .done
    neg     rax
.done:
    pop     r9
    pop     r8
    pop     rbx
    ret
.invalid:
    mov     rax, -2
    pop     r9
    pop     r8
    pop     rbx
    ret

print_integer:
    push    rbp
    mov     rbp, rsp
    sub     rsp, 32
    push    rbx

    mov     rax, rdi
    test    rax, rax
    jns     .positive

    push    rax
    mov     rax, 1
    mov     rdi, 1
    lea     rsi, [rel minus_sign]
    mov     rdx, 1
    syscall
    pop     rax
    neg     rax

.positive:
    lea     rcx, [rsp + 15]
    mov     byte [rcx], 0
    xor     rbx, rbx
    push    rcx
    mov     rcx, 10

.digit_loop:
    xor     rdx, rdx
    div     rcx
    add     dl, '0'
    pop     rsi
    dec     rsi
    mov     [rsi], dl
    push    rsi
    inc     rbx
    test    rax, rax
    jnz     .digit_loop

    pop     rsi
    mov     rax, 1
    mov     rdi, 1
    mov     rdx, rbx
    syscall

    pop     rbx
    add     rsp, 32
    pop     rbp
    ret

print_newline:
    mov     rax, 1
    mov     rdi, 1
    lea     rsi, [rel newline]
    mov     rdx, 1
    syscall
    ret