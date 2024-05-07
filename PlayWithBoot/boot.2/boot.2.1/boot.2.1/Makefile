#
#boot.asm: /mnt/hgfs/share/boot.asm2
#	cp /mnt/hgfs/share/boot.asm2 ./boot.asm

boot.bin: boot.asm
	nasm -f bin boot.asm -o boot.bin

dis1: boot.asm
	nasm -f bin boot.asm -o boot.bin -l boot.tmp
	cat boot.tmp

dis2: boot.asm
	nasm -f bin boot.asm -o boot.bin
	objdump -b binary -m i8086 -M intel -D --show-raw-insn --prefix-addresses boot.bin

dump: boot.asm
	od -tx1z -Ax boot.bin

qemu: boot.bin
	qemu-system-x86_64 boot.bin

clean:
	rm *.bin

