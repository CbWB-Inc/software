# ファイル名: Makefile
NASM = nasm
ASMFLAGS = -f bin
QEMU = qemu-system-i386
IMG = boot.img

all: $(IMG)

$(IMG): boot.bin routine.bin main.bin task1.bin task2.bin task3.bin
	cat boot.bin routine.bin main.bin task1.bin task2.bin task3.bin > $(IMG)
	@echo "Created $(IMG)"

boot.bin: boot.asm
	$(NASM) $(ASMFLAGS) -o $@ $<

routine.bin: routine.asm
	$(NASM) $(ASMFLAGS) -o $@ $<

main.bin: main.asm
	$(NASM) $(ASMFLAGS) -o $@ $<

task1.bin: task1.asm
	$(NASM) $(ASMFLAGS) -o $@ $<

task2.bin: task2.asm
	$(NASM) $(ASMFLAGS) -o $@ $<

task3.bin: task3.asm
	$(NASM) $(ASMFLAGS) -o $@ $<

run: $(IMG)
	#$(QEMU) -fda $(IMG) -boot a -m 16M -rtc base=localtime -nographic
	$(QEMU) -hda $(IMG) 

clean:
	rm -f *.bin $(IMG)

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
	od -tx1z -Ax boot.img

DEBUG: $(IMG)
	qemu-system-x86_64 -enable-kvm -kernel boot.img -s -S

