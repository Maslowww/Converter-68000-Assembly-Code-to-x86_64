# Assembly Project II — 68000 to x86_64 Port

**Author:** Philip Bourke  
**Module:** Assembly Project II — 2025/2026  
**Date:** March 25, 2025  

---

## Overview

This project ports a Motorola 68000 assembly program to x86_64 Linux assembly (NASM).

The original program prompts the user for two integers, adds them via a subroutine (`REGISTER_ADDER`), and accumulates a running sum across 3 loop iterations before displaying the final total.

The x86_64 port replicates this functionality exactly while fixing all security vulnerabilities present in the original code.

---

## Files

| File | Description |
|------|-------------|
| `prog.asm` | x86_64 NASM assembly — main program |
| `test_program.c` | C unit tests for `register_adder` |
| `README.md` | This file |
| `Materials/` | Original 68000 reference code |

---

## Build & Run

### Main program
```bash
nasm -f elf64 prog.asm -o prog.o
ld prog.o -o prog
./prog
```

### Unit tests
```bash
nasm -f elf64 prog.asm -o prog.o
gcc test_program.c prog.o -o test_program
./test_program
```

---

## Register Mapping — 68000 → x86_64

| 68000 Register | x86_64 Register | Purpose |
|----------------|-----------------|---------|
| D3 | r12 | Running sum (callee-saved) |
| D4 | r13 | Loop counter (callee-saved) |
| D1 | rdi / rax | First parameter / return value |
| D2 | rsi | Second parameter |
| A1 | rsi | String address for sys_write |

---

## Instruction Mapping — 68000 → x86_64

| 68000 | x86_64 | Notes |
|-------|--------|-------|
| `CLR.L D3` | `xor r12, r12` | Zero a 64-bit register |
| `MOVE.W #3, D4` | `mov r13, 3` | Set loop counter |
| `SUBQ.W #1, D4` | `dec r13` | Decrement counter |
| `BNE GAME_LOOP` | `jnz game_loop` | Branch if not zero |
| `BSR REGISTER_ADDER` | `call register_adder` | Call subroutine |
| `ADD.L D2, D1` | `add rax, rsi` | Addition in register_adder |
| `RTS` | `ret` | Return from subroutine |
| `TRAP #15` (task 14) | `syscall` (sys_write) | Print string to stdout |
| `TRAP #15` (task 4) | `syscall` (sys_read) | Read from stdin |
| `SIMHALT` | `mov rax, 60` / `syscall` | Exit program |

---

## Security Vulnerabilities Fixed

The original 68000 code contained three labeled `; Vulnerable!` comments. All three have been addressed:

### 1. Buffer Overflow (Stack-Based)
- **Original:** `TRAP #15` task 4 read user input with no size limit — an attacker could write past the buffer boundary, overwriting the return address on the stack (classic stack-based buffer overflow).
- **Fix:** `sys_read` is called with `rdx = 20`, limiting input to 20 bytes maximum.

### 2. No Input Validation
- **Original:** Input was used directly after `TRAP #15` with no character checking — non-numeric input would cause undefined behaviour.
- **Fix:** `parse_integer` validates every character. Any non-digit character (except leading `-` or whitespace) causes the program to exit with an error message.

### 3. No Arithmetic Bounds Checking
- **Original:** `ADD.L D2, D1` performed addition with no overflow check — large inputs could silently wrap around (integer overflow).
- **Fix:** The x86_64 `jo` (jump if overflow) instruction checks the CPU overflow flag after `add rax, rsi` in `register_adder`. If overflow is detected, the function returns `-1` and the program exits cleanly.

---

## Test Plan

| Test Case | Input | Expected Output |
|-----------|-------|-----------------|
| Basic addition | 3, 4 | 7 |
| Zero operands | 0, 0 | 0 |
| Negative + Positive | -5, 5 | 0 |
| Both negative | -3, -4 | -7 |
| Large values | 1000000, 2000000 | 3000000 |
| Overflow detection | MAX_LONG, 1 | -1 (overflow signal) |
| Running sum (3 iters) | (2,3), (10,5), (7,1) | 28 |
