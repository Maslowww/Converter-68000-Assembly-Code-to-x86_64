# Converter-68000-Assembly-Code-to-x86_64

This project ports the provided Motorola 68000 example to Linux x86_64 assembly with NASM.

The original sample reads two integers three times, adds them with a register-based subroutine, prints each pair sum, and keeps a running total. The x86_64 version keeps the same visible behaviour but fixes the weak points from the source material by validating input and stopping on signed overflow.

## Project Structure

- `src/port68000.asm` contains the full x86_64 implementation.
- `tests/test_port.c` contains a small C test program based on `assert`.
- `docs/TEST_PLAN.md` contains the test plan and manual checks.
- `Materials/` keeps the assignment files.

## Build

```bash
make
```

## Run

```bash
make run
```

Example session:

```text
Enter number: 1
Enter number: 2
The sum is: 3
Enter number: 3
Enter number: 4
The sum is: 7
Enter number: 5
Enter number: 6
The sum is: 11
Final sum is: 21
```

## Test

```bash
make test
```

## 68000 to x86_64 Mapping

- `D1` and `D2` in the original code become argument registers in the x86_64 `register_adder` routine.
- The loop counter is stored in a general-purpose register and still runs exactly three times.
- The running sum is preserved across the whole loop, like the original `D3` usage.
- Helper routines use normal x86_64 stack frames where needed, so register use and stack use are both visible in the port.

## Security Improvements

- Each input line is validated before conversion.
- Numbers outside the signed 64-bit range are rejected.
- Addition overflow is detected before printing incorrect results.
- Overly long lines are rejected instead of being silently accepted.

## Notes

- The assignment also asks for a short execution video. That part is not generated in the repository, but the program is ready to record from the terminal.
- Comments inside code are written only in English.