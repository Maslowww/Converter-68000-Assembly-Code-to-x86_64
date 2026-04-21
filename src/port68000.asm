global _start
default rel

%define SYS_READ 0
%define SYS_WRITE 1
%define SYS_EXIT 60
%define STDIN_FD 0
%define STDOUT_FD 1
%define EXIT_SUCCESS 0
%define EXIT_FAILURE 1
%define LINE_BUFFER_CAPACITY 128
%define INPUT_BUFFER_CAPACITY 4096

section .data
    prompt_text db 'Enter number: '
    prompt_text_len equ $ - prompt_text

    result_text db 'The sum is: '
    result_text_len equ $ - result_text

    final_result_text db 'Final sum is: '
    final_result_text_len equ $ - final_result_text

    invalid_input_text db 'Invalid input. Please enter a signed 64-bit integer.', 10
    invalid_input_text_len equ $ - invalid_input_text

    input_too_long_text db 'Input is too long. Try a shorter number.', 10
    input_too_long_text_len equ $ - input_too_long_text

    overflow_text db 'Overflow detected while adding values.', 10
    overflow_text_len equ $ - overflow_text

    eof_text db 'Unexpected end of input.', 10
    eof_text_len equ $ - eof_text

    newline_text db 10
    min_int64_text db '-9223372036854775808'
    min_int64_text_len equ $ - min_int64_text

    positive_limit dq 9223372036854775807
    negative_limit dq 9223372036854775808

section .bss
    input_buffer resb INPUT_BUFFER_CAPACITY
    input_length resq 1
    input_position resq 1
    line_buffer resb LINE_BUFFER_CAPACITY

section .text
_start:
    xor r12, r12
    mov r13, 3

.loop_start:
    cmp r13, 0
    je .print_final_sum

    call read_valid_int
    mov r14, rax

    call read_valid_int
    mov r15, rax

    mov rdi, r14
    mov rsi, r15
    call register_adder
    test rdx, rdx
    jnz .overflow_exit
    mov rbx, rax

    mov rdi, r12
    mov rsi, rbx
    call register_adder
    test rdx, rdx
    jnz .overflow_exit
    mov r12, rax

    mov rdi, result_text
    mov rsi, result_text_len
    mov rdx, rbx
    call print_labeled_int

    dec r13
    jmp .loop_start

.print_final_sum:
    mov rdi, final_result_text
    mov rsi, final_result_text_len
    mov rdx, r12
    call print_labeled_int
    mov rdi, EXIT_SUCCESS
    call exit_program

.overflow_exit:
    mov rdi, overflow_text
    mov rsi, overflow_text_len
    call write_stdout
    mov rdi, EXIT_FAILURE
    call exit_program

read_valid_int:
    push rbp
    mov rbp, rsp

.read_again:
    mov rdi, prompt_text
    mov rsi, prompt_text_len
    call write_stdout

    mov rdi, line_buffer
    mov rsi, LINE_BUFFER_CAPACITY
    call read_line
    cmp rdx, 1
    je .eof_exit
    cmp rdx, 2
    je .too_long

    mov rdi, line_buffer
    mov rsi, rax
    call parse_int64
    test rdx, rdx
    jz .done

    mov rdi, invalid_input_text
    mov rsi, invalid_input_text_len
    call write_stdout
    jmp .read_again

.too_long:
    mov rdi, input_too_long_text
    mov rsi, input_too_long_text_len
    call write_stdout
    jmp .read_again

.eof_exit:
    mov rdi, eof_text
    mov rsi, eof_text_len
    call write_stdout
    mov rdi, EXIT_FAILURE
    call exit_program

.done:
    pop rbp
    ret

read_line:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    push r15

    mov r12, rdi
    mov r13, rsi
    xor r14, r14
    xor r15, r15

.read_char:
    call read_next_char
    cmp rdx, 1
    je .handle_eof
    cmp al, 10
    je .finish_line
    cmp r15, 0
    jne .discard_char
    mov rbx, r13
    dec rbx
    cmp r14, rbx
    jae .line_too_long
    mov [r12 + r14], al
    inc r14
    jmp .read_char

.line_too_long:
    mov r15, 1

.discard_char:
    jmp .read_char

.handle_eof:
    cmp r14, 0
    jne .finish_line
    cmp r15, 0
    jne .return_too_long
    xor rax, rax
    mov rdx, 1
    jmp .cleanup

.finish_line:
    mov byte [r12 + r14], 0
    mov rax, r14
    cmp r15, 0
    jne .return_too_long
    xor rdx, rdx
    jmp .cleanup

.return_too_long:
    mov byte [r12], 0
    xor rax, rax
    mov rdx, 2

.cleanup:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

read_next_char:
    push rbp
    mov rbp, rsp
    push rbx

    mov rax, [input_position]
    mov rbx, [input_length]
    cmp rax, rbx
    jb .have_data

    mov rax, SYS_READ
    mov rdi, STDIN_FD
    mov rsi, input_buffer
    mov rdx, INPUT_BUFFER_CAPACITY
    syscall
    cmp rax, 0
    jle .end_of_input
    mov [input_length], rax
    mov qword [input_position], 0

.have_data:
    mov rbx, [input_position]
    mov al, [input_buffer + rbx]
    inc rbx
    mov [input_position], rbx
    xor rdx, rdx
    pop rbx
    pop rbp
    ret

.end_of_input:
    xor eax, eax
    mov rdx, 1
    pop rbx
    pop rbp
    ret

parse_int64:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    push r15

    mov r12, rdi
    mov r13, rsi
    xor r14, r14
    xor r15, r15
    xor r8, r8

.skip_leading_spaces:
    cmp r14, r13
    jae .fail
    mov al, [r12 + r14]
    cmp al, ' '
    je .consume_leading_space
    cmp al, 9
    je .consume_leading_space
    jmp .check_sign

.consume_leading_space:
    inc r14
    jmp .skip_leading_spaces

.check_sign:
    mov al, [r12 + r14]
    cmp al, '-'
    jne .check_plus
    mov r15, 1
    inc r14
    jmp .prepare_digits

.check_plus:
    cmp al, '+'
    jne .prepare_digits
    inc r14

.prepare_digits:
    cmp r14, r13
    jae .fail
    mov al, [r12 + r14]
    cmp al, '0'
    jb .fail
    cmp al, '9'
    ja .fail

    xor rbx, rbx
    cmp r15, 0
    je .load_positive_limit
    mov rbx, [negative_limit]
    jmp .parse_loop

.load_positive_limit:
    mov rbx, [positive_limit]

.parse_loop:
    cmp r14, r13
    jae .parse_done
    movzx r9, byte [r12 + r14]
    cmp r9b, '0'
    jb .parse_done
    cmp r9b, '9'
    ja .parse_done

    sub r9, '0'
    mov rax, rbx
    xor rdx, rdx
    mov rcx, 10
    div rcx
    cmp r8, rax
    ja .fail
    jne .safe_digit
    cmp r9, rdx
    ja .fail

.safe_digit:
    mov rax, r8
    imul rax, rax, 10
    add rax, r9
    mov r8, rax
    inc r14
    jmp .parse_loop

.parse_done:
    cmp r14, r13
    jae .build_result

.skip_trailing_spaces:
    cmp r14, r13
    jae .build_result
    mov al, [r12 + r14]
    cmp al, ' '
    je .consume_trailing_space
    cmp al, 9
    je .consume_trailing_space
    jmp .fail

.consume_trailing_space:
    inc r14
    jmp .skip_trailing_spaces

.build_result:
    cmp r15, 0
    je .positive_result
    mov rax, [negative_limit]
    cmp r8, rax
    jne .regular_negative
    mov rax, 0x8000000000000000
    xor rdx, rdx
    jmp .cleanup

.regular_negative:
    mov rax, r8
    neg rax
    xor rdx, rdx
    jmp .cleanup

.positive_result:
    mov rax, r8
    xor rdx, rdx
    jmp .cleanup

.fail:
    xor rax, rax
    mov rdx, 1

.cleanup:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

register_adder:
    mov rax, rdi
    add rax, rsi
    seto dl
    movzx rdx, dl
    ret

print_labeled_int:
    push rbp
    mov rbp, rsp
    push r12
    push r13

    mov r12, rdi
    mov r13, rsi
    mov rax, rdx

    mov rdi, r12
    mov rsi, r13
    call write_stdout

    mov rdi, rax
    call print_signed_int
    call print_newline

    pop r13
    pop r12
    pop rbp
    ret

print_signed_int:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    sub rsp, 40

    mov rax, rdi
    mov rbx, 0x8000000000000000
    cmp rax, rbx
    jne .not_min_value
    mov rdi, min_int64_text
    mov rsi, min_int64_text_len
    call write_stdout
    jmp .cleanup

.not_min_value:
    lea r12, [rsp + 39]
    mov byte [r12], 0
    xor r13, r13
    xor r14, r14
    mov rbx, 10

    test rax, rax
    jns .prepare_digits
    mov r14, 1
    neg rax

.prepare_digits:
    cmp rax, 0
    jne .digit_loop
    dec r12
    mov byte [r12], '0'
    inc r13
    jmp .maybe_sign

.digit_loop:
    xor rdx, rdx
    div rbx
    add dl, '0'
    dec r12
    mov [r12], dl
    inc r13
    test rax, rax
    jne .digit_loop

.maybe_sign:
    cmp r14, 0
    je .write_number
    dec r12
    mov byte [r12], '-'
    inc r13

.write_number:
    mov rdi, r12
    mov rsi, r13
    call write_stdout

.cleanup:
    add rsp, 40
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

print_newline:
    mov rdi, newline_text
    mov rsi, 1
    call write_stdout
    ret

write_stdout:
    mov rax, SYS_WRITE
    mov rdx, rsi
    mov rsi, rdi
    mov rdi, STDOUT_FD
    syscall
    ret

exit_program:
    mov rax, SYS_EXIT
    syscall
