NASM = nasm

all: os.img

# 各 bin ファイルの生成
boot.bin: boot.asm
	$(NASM) -f bin boot.asm -o boot.bin

main.bin: main.asm
	$(NASM) -f bin main.asm -o main.bin


# カーネル（main + irq0 結合）
kernel.bin: main.bin
	cat main.bin  > kernel.bin

# OS イメージ生成（boot + kernel + tasks）
os.img: boot.bin kernel.bin
	cat boot.bin kernel.bin > os.img
	truncate -s 1474560 os.img

clean:
	rm -f *.bin *.img


run: $(IMG)
	qemu-system-i386 -hda os.img -vga std


dis1: $(IMG)
	nasm -f bin $(IMG) -o $(OBJ) -l __a.tmp
	cat __a.tmp

dis2: $(IMG)
	objdump -b binary -m i8086 -M intel -D --show-raw-insn --prefix-addresses os.img

dis3: $(IMG)
	nasm -f bin -l output.lst main.asm

dis4: $(IMG)
	nasm -f bin -l output.lst routine.asm



dump: $(IMG)
	od -tx1z -Ax os.img

DEBUG: $(IMG)
	qemu-system-x86_64 -enable-kvm -kernel boot.img -s -S

