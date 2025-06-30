NASM = nasm
LD = ld
OBJCOPY = objcopy

NASMFLAGS = -f elf
LDFLAGS = -m elf_i386
LDENTRY = _start

# 各セグメント先頭アドレス
#KERNEL_ADDR = 0x8000
KERNEL_ADDR = 0x0000
#K_TASK_ADDR = 0x9000
K_TASK_ADDR = 0x0000

# 出力ファイル
BOOT_BIN = boot.bin
KERNEL_ELF = kernel.elf
KERNEL_BIN = kernel.bin
K_TASK_ELF = k_task.elf
K_TASK_BIN = k_task.bin
OS_IMG = os.img

# ソース
BOOT_SRC = boot.asm
MAIN_SRC = main.asm
TASK_SRC = k_task.asm
ROUTINE_SRC = routine.asm

# オブジェクト
MAIN_OBJ = main.o
TASK_OBJ = k_task.o
ROUTINE_OBJ = routine.o

.PHONY: all clean

all: $(OS_IMG)

$(BOOT_BIN): $(BOOT_SRC)
	$(NASM) -f bin -o $@ $<

$(MAIN_OBJ): $(MAIN_SRC)
	$(NASM) $(NASMFLAGS) -o $@ $<

$(ROUTINE_OBJ): $(ROUTINE_SRC)
	$(NASM) $(NASMFLAGS) -o $@ $<

$(KERNEL_BIN): $(MAIN_OBJ) $(ROUTINE_OBJ)
	$(LD) $(LDFLAGS) -Ttext $(KERNEL_ADDR) -o $(KERNEL_ELF) $(MAIN_OBJ) $(ROUTINE_OBJ)
	$(OBJCOPY) -O binary $(KERNEL_ELF) $@
	@# セクタ(512B)単位に切り上げてパディング
	@size=`stat -c %s $(KERNEL_BIN)`; \
	rem=$$(($$size % 512)); \
	if [ $$rem -ne 0 ]; then \
	  pad_size=$$((512 - $$rem)); \
	  echo "Padding $$pad_size bytes to align to 512-byte sector"; \
	  dd if=/dev/zero bs=1 count=$$pad_size >> $(KERNEL_BIN); \
	fi
$(K_TASK_BIN): $(TASK_SRC) $(ROUTINE_OBJ)
	$(NASM) -f elf -dK_TASK_SEG=$(K_TASK_ADDR) -o $(TASK_OBJ) $(TASK_SRC)
	$(LD) $(LDFLAGS) -Ttext $(K_TASK_ADDR) -o $(K_TASK_ELF) $(TASK_OBJ) $(ROUTINE_OBJ)
	$(OBJCOPY) -O binary $(K_TASK_ELF) $@

$(OS_IMG): $(BOOT_BIN) $(KERNEL_BIN) $(K_TASK_BIN)
	cat $(BOOT_BIN) $(KERNEL_BIN) $(K_TASK_BIN) > $(OS_IMG)

clean:
	rm -f *.o *.elf *.bin $(OS_IMG)
	

run: $(IMG)
	qemu-system-i386 -hda os.img


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
	qemu-system-x86_64 -enable-kvm -kernel os.img -s -S

