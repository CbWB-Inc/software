# ファイル名: Makefile
NASM=nasm
IMG=os.img

all: $(IMG)

$(IMG): boot.bin main.bin child.bin chain.bin
	cat boot.bin main.bin child.bin chain.bin > $(IMG)

boot.bin: boot.asm
	$(NASM) -f bin boot.asm -o boot.bin

main.bin: main.asm
	$(NASM) -f bin main.asm -o main.bin

child.bin: child.asm
	$(NASM) -f bin child.asm -o child.bin

chain.bin: chain.asm
	$(NASM) -f bin chain.asm -o chain.bin

clean:
	rm -f *.bin $(IMG)

run: $(IMG)
	qemu-system-i386 -hda $(IMG)


dis1: $(IMG)
	nasm -f bin $(IMG) -o $(OBJ) -l __a.tmp
	cat __a.tmp

dis2: $(IMG)
	objdump -b binary -m i8086 -M intel -D --show-raw-insn --prefix-addresses $(IMG)

dis3: $(IMG)
	nasm -f bin -l output.lst main.asm

dis4: $(IMG)
	nasm -f bin -l output.lst routine.asm



dump: $(IMG)
	od -tx1z -Ax $(IMG)

DEBUG: $(IMG)
	qemu-system-x86_64 -enable-kvm -kernel boot.img -s -S

