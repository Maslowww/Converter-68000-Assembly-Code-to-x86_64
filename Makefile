ASM = nasm
CC = gcc
ASMFLAGS = -f elf64 -g -F dwarf
CFLAGS = -std=c11 -Wall -Wextra -Werror -pedantic
LDFLAGS =

BUILD_DIR = build
TEST_BIN_DIR = tests/bin
PROGRAM = $(BUILD_DIR)/port68000
ASM_OBJECT = $(BUILD_DIR)/port68000.o
TEST_BINARY = $(TEST_BIN_DIR)/test_port

.PHONY: all clean run test

all: $(PROGRAM)

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(TEST_BIN_DIR):
	mkdir -p $(TEST_BIN_DIR)

$(ASM_OBJECT): src/port68000.asm | $(BUILD_DIR)
	$(ASM) $(ASMFLAGS) $< -o $@

$(PROGRAM): $(ASM_OBJECT)
	ld $< -o $@

$(TEST_BINARY): tests/test_port.c | $(TEST_BIN_DIR)
	$(CC) $(CFLAGS) $< -o $@ $(LDFLAGS)

run: $(PROGRAM)
	./$(PROGRAM)

test: $(PROGRAM) $(TEST_BINARY)
	./$(TEST_BINARY)

clean:
	rm -rf $(BUILD_DIR) $(TEST_BIN_DIR)
