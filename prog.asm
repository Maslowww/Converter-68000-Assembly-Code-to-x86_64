; =====================================================
; Title        : Parameter Passing Example - x86_64
; Author       : Philip Bourke
; Date         : March 25, 2025
; Module       : Assembly Project II - 2025/2026
;
; Description  :
;   This program is a port of a Motorola 68000 assembly
;   program to x86_64 Linux assembly (NASM syntax).
;
;   The program prompts the user to enter two integers,
;   adds them using the register_adder subroutine, and
;   accumulates a running sum over 3 loop iterations.
;   The final running sum is displayed at the end.
;
;   Security vulnerabilities from the original 68000
;   code have been addressed:
;     1. Bounded input buffer (max 20 bytes) to prevent
;        stack-based buffer overflow
;     2. Input validation - every character is checked
;        before conversion (no blind scanf)
;     3. Signed overflow detection using the x86 'jo'
;        instruction inside register_adder
;
; Build:
;   nasm -f elf64 prog.asm -o prog.o
;   ld prog.o -o prog
;   ./prog
; =====================================================

section .data
    ; Prompt string (equiv: PROMPT DC.B 'Enter number: ',0)
    prompt          db  "Enter number: "
    prompt_len      equ $ - prompt

    ; Intermediate result message (equiv: RESULT DC.B 'The sum is: ',0)
    result_msg      db  "The sum is: "
    result_msg_len  equ $ - result_msg

    ; Final result message (equiv: FINAL_RESULT DC.B 'Final sum is: ',0)
    final_msg       db  "Final sum is: "
    final_msg_len   equ $ - final_msg

    ; Newline character (equiv: CRLF DC.B $D,$A,0)
    newline         db  10

    ; Minus sign used by print_integer for negative numbers
    minus_sign      db  '-'

    ; Error messages (security additions - not in original)
    err_invalid     db  "Error: Invalid input. Please enter an integer.", 10
    err_invalid_len equ $ - err_invalid

    err_overflow    db  "Error: Arithmetic overflow detected.", 10
    err_overflow_len equ $ - err_overflow

section .bss
    ; Input buffer - fixed size prevents buffer overflow
    ; (original 68000 had no input size limit - Vulnerable!)
    input_buf   resb 20
    num1        resq 1      ; storage for first number
    num2        resq 1      ; storage for second number

section .text
    global _start
    global register_adder   ; exported so C test file can call it

; =====================================================
; _start - main entry point
; Equivalent to: START ORG $1000 in 68000
; =====================================================
_start:
    xor     r12, r12        ; running sum = 0   (equiv: CLR.L D3)
    mov     r13, 3          ; loop counter = 3  (equiv: MOVE.W #3, D4)

; =====================================================
; game_loop - main program loop
; Runs 3 times, reads two numbers and adds them
; Equivalent to: GAME_LOOP label in 68000
; =====================================================
game_loop:

    ; ---- Display prompt for first number ----
    ; Equivalent to: MOVE.B #14,D0 / LEA PROMPT,A1 / TRAP #15
    mov     rax, 1              ; sys_write
    mov     rdi, 1              ; stdout
    lea     rsi, [rel prompt]
    mov     rdx, prompt_len
    syscall

    ; ---- Read first number from stdin ----
    ; Buffer is bounded to 20 bytes - prevents buffer overflow
    ; (Original: MOVE.B #4,D0 / TRAP #15 - No input validation - Vulnerable!)
    mov     rax, 0              ; sys_read
    mov     rdi, 0              ; stdin
    lea     rsi, [rel input_buf]
    mov     rdx, 20             ; max 20 bytes (security fix)
    syscall

    ; Validate and parse the input string into an integer
    lea     rdi, [rel input_buf]
    mov     rcx, rax            ; rcx = number of bytes read
    call    parse_integer
    cmp     rax, -2             ; -2 signals invalid input
    je      handle_invalid
    mov     [num1], rax         ; store first number (equiv: MOVE.L D1,D2)

    ; ---- Display prompt for second number ----
    mov     rax, 1
    mov     rdi, 1
    lea     rsi, [rel prompt]
    mov     rdx, prompt_len
    syscall

    ; ---- Read second number from stdin ----
    mov     rax, 0
    mov     rdi, 0
    lea     rsi, [rel input_buf]
    mov     rdx, 20
    syscall

    ; Validate and parse second input
    lea     rdi, [rel input_buf]
    mov     rcx, rax
    call    parse_integer
    cmp     rax, -2
    je      handle_invalid
    mov     [num2], rax

    ; ---- Call register_adder subroutine ----
    ; Pass parameters via registers: rdi = num1, rsi = num2
    ; Result returned in rax
    ; Equivalent to: BSR REGISTER_ADDER
    mov     rdi, [num1]
    mov     rsi, [num2]
    call    register_adder
    cmp     rax, -1             ; -1 signals overflow
    je      handle_overflow

    ; ---- Add result to running sum ----
    ; Equivalent to: ADD.L D1, D3
    push    rax                 ; save result before print calls
    add     r12, rax

    ; ---- Display intermediate result ----
    ; Equivalent to: MOVE.B #14,D0 / LEA RESULT,A1 / TRAP #15
    mov     rax, 1
    mov     rdi, 1
    lea     rsi, [rel result_msg]
    mov     rdx, result_msg_len
    syscall

    pop     rdi                 ; restore result into rdi for printing
    call    print_integer
    call    print_newline

    ; ---- Decrement loop counter and repeat if not zero ----
    ; Equivalent to: SUBQ.W #1,D4 / BNE GAME_LOOP
    dec     r13
    jnz     game_loop

    ; ---- Display final running sum ----
    ; Equivalent to: MOVE.B #14,D0 / LEA FINAL_RESULT,A1 / TRAP #15
    mov     rax, 1
    mov     rdi, 1
    lea     rsi, [rel final_msg]
    mov     rdx, final_msg_len
    syscall

    mov     rdi, r12            ; r12 holds the running sum
    call    print_integer
    call    print_newline

    ; ---- Exit program ----
    ; Equivalent to: SIMHALT
    mov     rax, 60             ; sys_exit
    xor     rdi, rdi            ; exit code 0
    syscall

; =====================================================
; handle_invalid - prints error and exits (code 1)
; Security addition: original had no error handling
; =====================================================
handle_invalid:
    mov     rax, 1
    mov     rdi, 1
    lea     rsi, [rel err_invalid]
    mov     rdx, err_invalid_len
    syscall
    mov     rax, 60
    mov     rdi, 1
    syscall

; =====================================================
; handle_overflow - prints error and exits (code 2)
; Security addition: original had no overflow handling
; =====================================================
handle_overflow:
    mov     rax, 1
    mov     rdi, 1
    lea     rsi, [rel err_overflow]
    mov     rdx, err_overflow_len
    syscall
    mov     rax, 60
    mov     rdi, 2
    syscall

; =====================================================
; register_adder
;
;   Parameters : rdi = first number
;                rsi = second number
;   Returns    : rax = rdi + rsi
;                rax = -1 if signed overflow detected
;
;   Equivalent to: REGISTER_ADDER / ADD.L D2,D1 / RTS
;
;   Security fix: original had no bounds checking
;   (Original comment: "No bounds checking - Vulnerable!")
;   Fix: x86 'jo' instruction detects signed overflow
; =====================================================
register_adder:
    push    rbp
    mov     rbp, rsp

    mov     rax, rdi        ; rax = first number
    add     rax, rsi        ; rax = rdi + rsi  (equiv: ADD.L D2,D1)
    jo      .overflow       ; jump if overflow flag set (security fix)

    pop     rbp
    ret                     ; return result in rax (equiv: RTS)

.overflow:
    mov     rax, -1         ; signal overflow to caller
    pop     rbp
    ret

; =====================================================
; parse_integer
;
;   Parameters : rdi = pointer to ASCII input string
;                rcx = number of bytes in buffer
;   Returns    : rax = parsed integer value
;                rax = -2 if input contains invalid chars
;
;   Security: validates every character before conversion.
;   Original 68000 used TRAP #15 task 4 with no validation
;   (Original comment: "No input validation - Vulnerable!")
; =====================================================
parse_integer:
    push    rbx
    push    r8
    push    r9
    xor     rax, rax        ; accumulator = 0
    xor     r8,  r8         ; r8 = negative flag
    xor     r9,  r9         ; r9 = digit count (must have >= 1)

.skip_whitespace:
    test    rcx, rcx
    jz      .invalid
    movzx   rbx, byte [rdi]
    cmp     rbx, ' '
    jne     .check_sign
    inc     rdi
    dec     rcx
    jmp     .skip_whitespace

.check_sign:
    cmp     rbx, '-'
    jne     .parse_loop
    mov     r8, 1           ; set negative flag
    inc     rdi
    dec     rcx

.parse_loop:
    test    rcx, rcx
    jz      .check_digit_count
    movzx   rbx, byte [rdi]
    cmp     rbx, 10         ; newline = end of input
    je      .check_digit_count
    cmp     rbx, 13         ; carriage return = end of input
    je      .check_digit_count
    cmp     rbx, ' '
    je      .check_digit_count
    cmp     rbx, '0'        ; below '0' = not a digit = invalid
    jl      .invalid
    cmp     rbx, '9'        ; above '9' = not a digit = invalid
    jg      .invalid
    sub     rbx, '0'        ; convert ASCII to integer
    imul    rax, rax, 10    ; shift accumulator left by one decimal place
    add     rax, rbx        ; add new digit
    inc     r9              ; increment digit count
    inc     rdi
    dec     rcx
    jmp     .parse_loop

.check_digit_count:
    test    r9, r9          ; did we read at least one digit?
    jz      .invalid
    test    r8, r8          ; was there a minus sign?
    jz      .done
    neg     rax             ; negate for negative numbers
.done:
    pop     r9
    pop     r8
    pop     rbx
    ret

.invalid:
    mov     rax, -2         ; invalid input signal
    pop     r9
    pop     r8
    pop     rbx
    ret

; =====================================================
; print_integer
;
;   Parameters : rdi = signed 64-bit integer to print
;   Clobbers   : rax, rdx, rbx, rcx, rsi (not r12/r13)
;
;   Note: deliberately avoids r12 and r13 which hold
;   the running sum and loop counter respectively.
; =====================================================
print_integer:
    push    rbp
    mov     rbp, rsp
    sub     rsp, 32
    push    rbx

    mov     rax, rdi        ; move value into rax for division
    test    rax, rax
    jns     .positive

    ; Print minus sign for negative numbers
    push    rax
    mov     rax, 1
    mov     rdi, 1
    lea     rsi, [rel minus_sign]
    mov     rdx, 1
    syscall
    pop     rax
    neg     rax             ; make positive for digit extraction

.positive:
    ; Convert integer to ASCII digits right-to-left
    lea     rcx, [rsp + 15] ; rcx = pointer into local buffer
    mov     byte [rcx], 0
    xor     rbx, rbx        ; rbx = digit count
    push    rcx
    mov     rcx, 10         ; divisor = 10

.digit_loop:
    xor     rdx, rdx
    div     rcx             ; rax = quotient, rdx = remainder
    add     dl, '0'         ; convert digit to ASCII
    pop     rsi
    dec     rsi
    mov     [rsi], dl       ; store digit in buffer
    push    rsi
    inc     rbx
    test    rax, rax
    jnz     .digit_loop

    ; Write the string to stdout
    pop     rsi
    mov     rax, 1
    mov     rdi, 1
    mov     rdx, rbx
    syscall

    pop     rbx
    add     rsp, 32
    pop     rbp
    ret

; =====================================================
; print_newline
;
;   Prints a newline character to stdout.
;   Equivalent to: NEW_LINE subroutine (CRLF in original)
; =====================================================
print_newline:
    mov     rax, 1
    mov     rdi, 1
    lea     rsi, [rel newline]
    mov     rdx, 1
    syscall
    ret
