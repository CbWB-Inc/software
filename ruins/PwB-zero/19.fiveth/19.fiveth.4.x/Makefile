NASM = nasm
LD = ld
OBJCOPY = objcopy

NASMFLAGS = -f elf -g
LDFLAGS = -m elf_i386
LDENTRY = _start

# 各セグメント先頭アドレス
KERNEL_ADDR = 0x0000
K_TASK_ADDR = 0x0000
D_TASK_ADDR = 0x0000
P_TASK1_ADDR = 0x0000
P_TASK2_ADDR = 0x0000
P_TASK3_ADDR = 0x0000

# 出力ファイル
BOOT_BIN = boot.bin
KERNEL_ELF = kernel.elf
KERNEL_BIN = kernel.bin
K_TASK_ELF = k_task.elf
K_TASK_BIN = k_task.bin
D_TASK_ELF = d_task.elf
D_TASK_BIN = d_task.bin
P_TASK1_ELF = p_task1.elf
P_TASK1_BIN = p_task1.bin
P_TASK2_ELF = p_task2.elf
P_TASK2_BIN = p_task2.bin
P_TASK3_ELF = p_task3.elf
P_TASK3_BIN = p_task3.bin
OS_IMG = os.img

# ソース
BOOT_SRC = boot.asm
MAIN_SRC = main.asm
TASK_SRC = k_task.asm
TASK2_SRC = d_task.asm
TASK3_SRC = p_task1.asm
TASK4_SRC = p_task2.asm
TASK5_SRC = p_task3.asm
ROUTINE_SRC = routine.asm

# オブジェクト
MAIN_OBJ = main.o
TASK_OBJ = k_task.o
TASK2_OBJ = d_task.o
TASK3_OBJ = p_task1.o
TASK4_OBJ = p_task2.o
TASK5_OBJ = p_task3.o
ROUTINE_OBJ = routine.o

.PHONY: all clean

all: $(OS_IMG)

$(BOOT_BIN): $(BOOT_SRC)
	$(NASM) -f bin -o $@ $<

$(MAIN_OBJ): $(MAIN_SRC)
	$(NASM) $(NASMFLAGS) -g -o $@ $<

$(ROUTINE_OBJ): $(ROUTINE_SRC)
	$(NASM) $(NASMFLAGS) -g -o $@ $<

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
	$(NASM) -f elf -g -dK_TASK_SEG=$(K_TASK_ADDR) -g -o $(TASK_OBJ) $(TASK_SRC)
	$(LD) $(LDFLAGS) -Ttext $(K_TASK_ADDR) -o $(K_TASK_ELF) $(TASK_OBJ) $(ROUTINE_OBJ)
	$(OBJCOPY) -O binary $(K_TASK_ELF) $@
	@# セクタ(512B)単位に切り上げてパディング
	@size=`stat -c %s $(K_TASK_BIN)`; \
	rem=$$(($$size % 512)); \
	if [ $$rem -ne 0 ]; then \
	  pad_size=$$((512 - $$rem)); \
	  echo "Padding $$pad_size bytes to align to 512-byte sector"; \
	  dd if=/dev/zero bs=1 count=$$pad_size >> $(K_TASK_BIN); \
	fi

$(D_TASK_BIN): $(TASK2_SRC) $(ROUTINE_OBJ)
	$(NASM) -f elf -g -dD_TASK_SEG=$(D_TASK_ADDR) -g -o $(TASK2_OBJ) $(TASK2_SRC)
	$(LD) $(LDFLAGS) -Ttext $(D_TASK_ADDR) -o $(D_TASK_ELF) $(TASK2_OBJ) $(ROUTINE_OBJ)
	$(OBJCOPY) -O binary $(D_TASK_ELF) $@
	@# セクタ(512B)単位に切り上げてパディング
	@size=`stat -c %s $(D_TASK_BIN)`; \
	rem=$$(($$size % 512)); \
	if [ $$rem -ne 0 ]; then \
	  pad_size=$$((512 - $$rem)); \
	  echo "Padding $$pad_size bytes to align to 512-byte sector"; \
	  dd if=/dev/zero bs=1 count=$$pad_size >> $(D_TASK_BIN); \
	fi

$(P_TASK1_BIN): $(TASK3_SRC) $(ROUTINE_OBJ)
	$(NASM) -f elf -g -dP_TASK1_SEG=$(P_TASK1_ADDR) -g -o $(TASK3_OBJ) $(TASK3_SRC)
	$(LD) $(LDFLAGS) -Ttext $(P_TASK1_ADDR) -o $(P_TASK1_ELF) $(TASK3_OBJ) $(ROUTINE_OBJ)
	$(OBJCOPY) -O binary $(P_TASK1_ELF) $@
	@# セクタ(512B)単位に切り上げてパディング
	@size=`stat -c %s $(P_TASK1_BIN)`; \
	rem=$$(($$size % 512)); \
	if [ $$rem -ne 0 ]; then \
	  pad_size=$$((512 - $$rem)); \
	  echo "Padding $$pad_size bytes to align to 512-byte sector"; \
	  dd if=/dev/zero bs=1 count=$$pad_size >> $(P_TASK1_BIN); \
	fi

$(P_TASK2_BIN): $(TASK4_SRC) $(ROUTINE_OBJ)
	$(NASM) -f elf -g -dP_TASK2_SEG=$(P_TASK2_ADDR) -g -o $(TASK4_OBJ) $(TASK4_SRC)
	$(LD) $(LDFLAGS) -Ttext $(P_TASK2_ADDR) -o $(P_TASK2_ELF) $(TASK4_OBJ) $(ROUTINE_OBJ)
	$(OBJCOPY) -O binary $(P_TASK2_ELF) $@
	@# セクタ(512B)単位に切り上げてパディング
	@size=`stat -c %s $(P_TASK2_BIN)`; \
	rem=$$(($$size % 512)); \
	if [ $$rem -ne 0 ]; then \
	  pad_size=$$((512 - $$rem)); \
	  echo "Padding $$pad_size bytes to align to 512-byte sector"; \
	  dd if=/dev/zero bs=1 count=$$pad_size >> $(P_TASK2_BIN); \
	fi

$(P_TASK3_BIN): $(TASK5_SRC) $(ROUTINE_OBJ)
	$(NASM) -f elf -g -dP_TASK3_SEG=$(P_TASK3_ADDR) -g -o $(TASK5_OBJ) $(TASK5_SRC)
	$(LD) $(LDFLAGS) -Ttext $(P_TASK3_ADDR) -o $(P_TASK3_ELF) $(TASK5_OBJ) $(ROUTINE_OBJ)
	$(OBJCOPY) -O binary $(P_TASK3_ELF) $@
	@# セクタ(512B)単位に切り上げてパディング
	@size=`stat -c %s $(P_TASK3_BIN)`; \
	rem=$$(($$size % 512)); \
	if [ $$rem -ne 0 ]; then \
	  pad_size=$$((512 - $$rem)); \
	  echo "Padding $$pad_size bytes to align to 512-byte sector"; \
	  dd if=/dev/zero bs=1 count=$$pad_size >> $(P_TASK3_BIN); \
	fi

$(OS_IMG): $(BOOT_BIN) $(KERNEL_BIN) $(K_TASK_BIN) $(D_TASK_BIN) $(P_TASK1_BIN) $(P_TASK2_BIN) $(P_TASK3_BIN)
	cat $(BOOT_BIN) $(KERNEL_BIN) $(K_TASK_BIN) $(D_TASK_BIN) $(P_TASK1_BIN) $(P_TASK2_BIN) $(P_TASK3_BIN) > $(OS_IMG)

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
	#qemu-system-x86_64 -enable-kvm -kernel os.img -s -S
	qemu-system-i386 -hda os.img -s -S

