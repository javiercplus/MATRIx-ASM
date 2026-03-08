# Variables
ASM = nasm
ASM_FLAGS = -f elf64
LD = ld
TARGET = matrix_asm
SRC = matrix_jp.asm
OBJ = matrix_jp.o

# Default target
all: $(TARGET)

# Link
$(TARGET): $(OBJ)
	$(LD) $(OBJ) -o $(TARGET)
	chmod +x $(TARGET)

# Assemble
$(OBJ): $(SRC)
	$(ASM) $(ASM_FLAGS) $(SRC) -o $(OBJ)

# Clean files
clean:
	rm -f $(OBJ) $(TARGET)

# Run
run: all
	./$(TARGET)