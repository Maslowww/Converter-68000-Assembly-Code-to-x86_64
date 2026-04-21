# Test Plan

## Goal

Validate that the x86_64 version behaves like the provided 68000 program while improving input safety and overflow handling.

## Test Cases

1. Positive flow
   - Input: `1 2 3 4 5 6`
   - Expected iteration sums: `3`, `7`, `11`
   - Expected final sum: `21`

2. Mixed signed values
   - Input: `-5 2 7 -9 10 -3`
   - Expected iteration sums: `-3`, `-2`, `7`
   - Expected final sum: `2`

3. Invalid input recovery
   - Input starts with a non-numeric value such as `abc`
   - Expected behaviour: the program prints an error and asks again without crashing

4. Addition overflow
   - Input: `9223372036854775807` and `1`
   - Expected behaviour: the program prints an overflow message and exits with failure

5. Long input line
   - Input longer than the line buffer
   - Expected behaviour: the program rejects the line and asks again

## Automated Coverage

The file `tests/test_port.c` covers:

- positive execution
- signed arithmetic
- invalid input recovery
- overflow exit path

## Manual Checks

- Build with `make`
- Run interactively with `make run`
- Record a short terminal demo after a successful run
