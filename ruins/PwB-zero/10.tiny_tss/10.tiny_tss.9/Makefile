# ファイル名: Makefile

NASM = nasm
LD   = ld
OBJCOPY = objcopy

# 出力ファイル名
BOOT_IMG = os.img
SECTORS  = 20

# ソース
BOOT_SRC = boot.asm
MAIN_SRC = main.asm
TASK_SRCS = task1.asm task2.asm task3.asm

# バイナリ出力
BOOT_BIN = boot.bin
MAIN_BIN = main.bin
TASK_BINS = task1.bin task2.bin task3.bin

.PHONY: all clean run

all: $(BOOT_IMG)

%.bin: %.asm
	$(NASM) -f bin -o $@ $<

$(MAIN_BIN): $(MAIN_SRC)
	$(NASM) -f bin -o $@ $<

$(BOOT_BIN): $(BOOT_SRC)
	$(NASM) -f bin -o $@ $<

$(BOOT_IMG): $(BOOT_BIN) $(MAIN_BIN) $(TASK_BINS)
	cat $(BOOT_BIN) $(MAIN_BIN) $(TASK_BINS) > $@
	dd if=/dev/zero bs=512 count=$(SECTORS) >> $@ 2>/dev/null
	dd if=/dev/null of=$@ bs=512 seek=$(SECTORS) 2>/dev/null

run: $(BOOT_IMG)
	qemu-system-i386 -hda $(BOOT_IMG)

clean:
	rm -f $(BOOT_IMG) $(BOOT_BIN) $(MAIN_BIN) $(TASK_BINS)

dis1: $(IMG)
	nasm -f bin $(IMG) -o $(OBJ) -l __a.tmp
	cat __a.tmp

dis2: $(IMG)
	objdump -b binary -m i8086 -M intel -D --show-raw-insn --prefix-addresses $(IMG)

dis3: $(IMG)
	nasm -f bin -l output.lst main.asm


dump: $(IMG)
	od -tx1z -Ax $(IMG)

DEBUG: $(IMG)
	qemu-system-x86_64 -enable-kvm -kernel $(IMG) -s -S

