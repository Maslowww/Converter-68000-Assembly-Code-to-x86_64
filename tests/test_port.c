#define _POSIX_C_SOURCE 200809L

#include <assert.h>
#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/wait.h>

static char *read_all(FILE *stream) {
    size_t capacity = 4096;
    size_t length = 0;
    char *buffer = malloc(capacity);

    assert(buffer != NULL);

    for (;;) {
        if (length + 1 == capacity) {
            capacity *= 2;
            buffer = realloc(buffer, capacity);
            assert(buffer != NULL);
        }

        size_t bytes_read = fread(buffer + length, 1, capacity - length - 1, stream);
        length += bytes_read;

        if (bytes_read == 0) {
            break;
        }
    }

    buffer[length] = '\0';
    return buffer;
}

static char *run_program(const char *input, int *exit_code) {
    const char *command = "printf '%s' \"";
    (void) command;

    char input_path[] = "/tmp/port68000-input-XXXXXX";
    char output_path[] = "/tmp/port68000-output-XXXXXX";
    int input_fd = mkstemp(input_path);
    int output_fd = mkstemp(output_path);

    assert(input_fd >= 0);
    assert(output_fd >= 0);

    FILE *input_file = fdopen(input_fd, "w");
    assert(input_file != NULL);
    fputs(input, input_file);
    fclose(input_file);
    close(output_fd);

    char shell_command[1024];
    int written = snprintf(
        shell_command,
        sizeof(shell_command),
        "./build/port68000 < %s > %s",
        input_path,
        output_path
    );

    assert(written > 0);
    assert((size_t) written < sizeof(shell_command));

    int status = system(shell_command);
    assert(status != -1);

    FILE *output_file = fopen(output_path, "r");
    assert(output_file != NULL);
    char *output = read_all(output_file);
    fclose(output_file);

    remove(input_path);
    remove(output_path);

    if (WIFEXITED(status)) {
        *exit_code = WEXITSTATUS(status);
    } else {
        *exit_code = 255;
    }

    return output;
}

static void assert_contains(const char *haystack, const char *needle) {
    assert(strstr(haystack, needle) != NULL);
}

static void test_positive_flow(void) {
    int exit_code = 0;
    char *output = run_program("1\n2\n3\n4\n5\n6\n", &exit_code);

    assert(exit_code == 0);
    assert_contains(output, "The sum is: 3\n");
    assert_contains(output, "The sum is: 7\n");
    assert_contains(output, "The sum is: 11\n");
    assert_contains(output, "Final sum is: 21\n");

    free(output);
}

static void test_negative_flow(void) {
    int exit_code = 0;
    char *output = run_program("-5\n2\n7\n-9\n10\n-3\n", &exit_code);

    assert(exit_code == 0);
    assert_contains(output, "The sum is: -3\n");
    assert_contains(output, "The sum is: -2\n");
    assert_contains(output, "The sum is: 7\n");
    assert_contains(output, "Final sum is: 2\n");

    free(output);
}

static void test_invalid_input_recovery(void) {
    int exit_code = 0;
    char *output = run_program("abc\n1\n2\n3\n4\n5\n6\n", &exit_code);

    assert(exit_code == 0);
    assert_contains(output, "Invalid input. Please enter a signed 64-bit integer.\n");
    assert_contains(output, "Final sum is: 21\n");

    free(output);
}

static void test_overflow_exit(void) {
    int exit_code = 0;
    char *output = run_program("9223372036854775807\n1\n", &exit_code);

    assert(exit_code != 0);
    assert_contains(output, "Overflow detected while adding values.\n");

    free(output);
}

int main(void) {
    test_positive_flow();
    test_negative_flow();
    test_invalid_input_recovery();
    test_overflow_exit();
    puts("All tests passed.");
    return 0;
}
