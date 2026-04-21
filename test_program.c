#include <stdio.h>
#include <assert.h>

// Declare the external asm subroutine
extern long register_adder(long a, long b);

int main() {
    // Test 1: Basic addition
    assert(register_adder(3, 4) == 7);
    printf("Test 1 passed: 3 + 4 = 7\n");

    // Test 2: Zero values
    assert(register_adder(0, 0) == 0);
    printf("Test 2 passed: 0 + 0 = 0\n");

    // Test 3: Negative numbers
    assert(register_adder(-5, 5) == 0);
    printf("Test 3 passed: -5 + 5 = 0\n");

    // Test 4: Large values
    assert(register_adder(1000000, 2000000) == 3000000);
    printf("Test 4 passed: large numbers ok\n");

    printf("All tests passed!\n");
    return 0;
}