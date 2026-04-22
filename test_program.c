/*
 * =====================================================
 * Title   : Unit Tests for register_adder (x86_64)
 * Date    : March 25, 2025
 * Module  : Assembly Project II - 2025/2026
 *
 * Description:
 *   Tests the register_adder subroutine defined in
 *   prog.asm using the C assert library.
 *   Each test checks a specific input/output pair
 *   to verify correctness of the assembly function.
 *
 * Build:
 *   nasm -f elf64 prog.asm -o prog.o
 *   gcc test_program.c prog.o -o test_program
 *   ./test_program
 * =====================================================
 */

#include <stdio.h>
#include <assert.h>
#include <stdlib.h>

extern long register_adder(long a, long b);

int main(void) {
    printf("Running tests...\n");

    assert(register_adder(3, 4) == 7);
    printf("Test 1 passed\n");

    assert(register_adder(0, 5) == 5);
    printf("Test 2 passed\n");

    assert(register_adder(-5, 5) == 0);
    printf("Test 3 passed\n");

    assert(register_adder(-3, -4) == -7);
    printf("Test 4 passed\n");

    assert(register_adder(100, 200) == 300);
    printf("Test 5 passed\n");

    assert(register_adder(9223372036854775807LL, 1LL) == -1);
    printf("Test 6 passed\n");

    printf("All tests passed!\n");
    exit(0);
}