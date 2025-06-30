#
CURRENT = bios

TARGET  = qemu
SRC    = $(CURRENT).asm
OBJ    = $(CURRENT).bin

$(TARGET): $(OBJ)
	# qemu-system-x86_64 $(OBJ)
	qemu-system-x86_64 -hda $(OBJ)

$(OBJ): $(SRC)
	nasm -f bin $(SRC) -o $(OBJ)

dis1: $(SRC)
	nasm -f bin $(SRC) -o $(OBJ) -l __a.tmp
	cat __a.tmp

dis2: $(SRC)
	nasm -f bin $(SRC) -o $(OBJ)
	objdump -b binary -m i8086 -M intel -D --show-raw-insn --prefix-addresses $(OBJ)

dump: $(SRC)
	od -tx1z -Ax $(OBJ)

clean:
	rm *.bin

