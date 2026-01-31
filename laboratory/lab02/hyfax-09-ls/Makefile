# ===============================================================
#  hiFAX-ex boot experiment / HDD-style FAT16 image builder
# ===============================================================
SHELL := /bin/bash

# --- ファイル構成 ---
BUILD     := build
IMG       := $(BUILD)/disk.img

ASM      = nasm
LD       = ld
OBJCOPY  = objcopy
BUILD    = build


BOOT0_SRC := boot0.asm
BOOT1_SRC := boot1.asm
MON_SRC   := monitor.asm
APP_SRC   := app.asm
APP1_SRC  := app1.asm
TTS_SRC   := tts.asm
ECHO_SRC  := echo.asm
BCD_SRC   := bcd.asm

BOOT0_BIN := $(BUILD)/BOOT0.BIN
BOOT1_BIN := $(BUILD)/BOOT1.BIN
MON_BIN   := $(BUILD)/MONITOR.BIN
APP_BIN   := $(BUILD)/APP.BIN
APP1_BIN  := $(BUILD)/APP1.BIN
TTS_BIN   := $(BUILD)/TTS.BIN
ECHO_BIN  := $(BUILD)/ECHO
BCD_BIN   := $(BUILD)/BCD
ALLOC_T_BIN   := $(BUILD)/ALLOCT
DEBUG_BIN   := $(BUILD)/DEBUG
LS_BIN   := $(BUILD)/LS

TARGETS = $(BUILD)/boot0.bin $(BUILD)/boot1.bin $(BUILD)/monitor.bin \
			$(BUILD)/app.bin $(BUILD)/tts.bin $(BUILD)/echo \
			$(BUILD)/app1.bin $(BUILD)/bcd $(BUILD)/alloct \
			$(BUILD)/debug $(BUILD)/ls

# --- サイズ関連 ---
SIZE_MB   := 30
SECTORS   := $(shell expr $(SIZE_MB) \* 2048)  # 512B単位

# ===============================================================
#  default: assemble only
# ===============================================================
#all: $(BOOT0_BIN) $(BOOT1_BIN) $(MON_BIN) $(APP_BIN)
all: $(BUILD) $(TARGETS)

$(BUILD):
	mkdir -p $(BUILD)

# ===============================================================
#  Assembly rules
# ===============================================================
NASMFLAGS = -f bin
NASMFLAGS2 = -f elf

$(BUILD)/boot0.bin: boot0.asm | $(BUILD)
	$(ASM) -f bin $< -o $@

$(BUILD)/boot1.bin: boot1.asm | $(BUILD)
	$(ASM) -f bin $< -o $@

$(BUILD)/bcd: bcd.asm bcdlib.asm common.asm loadapp.asm| $(BUILD)
	$(ASM) -f bin $< -o $@

# $(BUILD)/monitor.o: monitor.asm | $(BUILD)
# 	$(ASM) -f elf $< -o $@

$(BUILD)/common.o: common.asm | $(BUILD)
	$(ASM) -f elf $< -o $@

# $(BUILD)/diskIO.o: diskIO.asm | $(BUILD)
# 	$(ASM) -f elf $< -o $@

# $(BUILD)/loadapp.o: loadapp.asm | $(BUILD)
# 	$(ASM) -f elf $< -o $@

$(BUILD)/monitor.bin: monitor.asm common.asm loadapp.asm  | $(BUILD)
	$(ASM) -f bin $< -o $@
# 	$(LD) -m elf_i386 --oformat binary -T linker.ld -o $@ $^

# $(BUILD)/monitor.bin: $(BUILD)/monitor.elf
# 	$(OBJCOPY) -O binary $< $@

$(BUILD)/app.o: app.asm common.asm loadapp.asm | $(BUILD)
	$(ASM) -f elf $< -o $@

$(BUILD)/app1.o: app1.asm common.asm loadapp.asm | $(BUILD)
	$(ASM) -f elf $< -o $@

$(BUILD)/echo.o: echo.asm common.asm loadapp.asm | $(BUILD)
	$(ASM) -f elf $< -o $@

$(BUILD)/alloct.o: alloct.asm common.asm loadapp.asm alloc.asm | $(BUILD)
	$(ASM) -f elf $< -o $@

$(BUILD)/debug.o: debug.asm common.asm loadapp.asm | $(BUILD)
	$(ASM) -f elf $< -o $@

$(BUILD)/ls.o: ls.asm common.asm loadapp.asm | $(BUILD)
	$(ASM) -f elf $< -o $@

# $(BUILD)/bcd.o: bcd.asm | $(BUILD)
# 	$(ASM) -f elf $< -o $@

# $(BUILD)/app.bin: app.asm | $(BUILD)
# 	$(ASM) -f elf $< -o $@

$(BUILD)/tts.bin: tts.asm common.asm | $(BUILD)
	$(ASM) -f bin $< -o $@

# $(BUILD)/echo.bin: echo.asm common.asm | $(BUILD)
# 	$(ASM) -f bin $< -o $@

# $(BUILD)/app.elf: $(BUILD)/app.o $(BUILD)/common.o 
# 	$(LD) -m elf_i386 -Ttext 0x0000 -o $@ $^
$(BUILD)/app.elf: $(BUILD)/app.o $(BUILD)/common.o 
	$(LD) -m elf_i386 -Ttext 0x0000 -o $@ $^

$(BUILD)/app.bin: $(BUILD)/app.elf
	$(OBJCOPY) -O binary $< $@

$(BUILD)/app1.elf: $(BUILD)/app1.o 
	$(LD) -m elf_i386 -Ttext 0x0000 -o $@ $^

$(BUILD)/app1.bin: $(BUILD)/app1.elf
	$(OBJCOPY) -O binary $< $@

$(BUILD)/echo.elf: $(BUILD)/echo.o 
	$(LD) -m elf_i386 -Ttext 0x0000 -o $@ $^

$(BUILD)/echo: $(BUILD)/echo.elf
	$(OBJCOPY) -O binary $< $@

$(BUILD)/alloct.elf: $(BUILD)/alloct.o $(BUILD)/common.o
	$(LD) -m elf_i386 -Ttext 0x0000 -o $@ $^

$(BUILD)/alloct: $(BUILD)/alloct.elf
	$(OBJCOPY) -O binary $< $@

$(BUILD)/debug.elf: $(BUILD)/debug.o 
	$(LD) -m elf_i386 -Ttext 0x0000 -o $@ $^

$(BUILD)/debug: $(BUILD)/debug.elf
	$(OBJCOPY) -O binary $< $@

$(BUILD)/ls.elf: $(BUILD)/ls.o 
	$(LD) -m elf_i386 -Ttext 0x0000 -o $@ $^

$(BUILD)/ls: $(BUILD)/ls.elf
	$(OBJCOPY) -O binary $< $@

# $(BUILD)/bcd.elf: $(BUILD)/bcd.o 
# 	$(LD) -m elf_i386 -Ttext 0x0000 -o $@ $^

# $(BUILD)/bcd: $(BUILD)/bcd.elf
# 	$(OBJCOPY) -O binary $< $@
# $(BUILD)/boot1.elf: $(BUILD)/boot1.o $(BUILD)/common.o $(BUILD)/diskIO.o 
# 	$(LD) -m elf_i386 -Ttext 0x0000 -o $@ $^

# $(BUILD)/boot1.bin: $(BUILD)/boot1.elf
# 	$(OBJCOPY) -O binary $< $@
# ===============================================================
#  Image build (requires mtools)
# ===============================================================
image: all
#	sudo modprobe loop || true
#	sudo losetup -f
	@echo "=== Create $(SIZE_MB)MB raw image ==="
	mkdir -p $(BUILD)
#	dd if=/dev/zero of=$(IMG) bs=512 count=20480 status=none
# 	dd if=/dev/zero of=$(IMG) bs=1M count=10 status=none
	dd if=/dev/zero of=$(IMG) bs=1M count=32 status=none

	parted -s $(IMG) mklabel msdos
	parted -s $(IMG) mkpart primary fat16 1MiB 100%
	parted -s $(IMG) set 1 boot on

# 	# FAT16でフォーマット
# 	mformat -i $(IMG)@@1048576 -F 32 :: > /dev/null

 	# FAT32でフォーマット
	mkfs.fat -F 16 -n MYDISK --offset 2048 $(IMG)

	@echo "=== Initialize MBR manually ==="
	# MBR領域の最初446Bを boot0 で上書き
	dd if=$(BOOT0_BIN) of=$(IMG) bs=446 count=1 conv=notrunc status=none

# 	@echo "=== Write partition table ==="
# 	# Start=2048 (0x800), Size=18432 (0x4800)
# 	printf '\x80\x01\x01\x00\x06\xFE\xFF\xFF\x00\x08\x00\x00\x00\x48\x00\x00' | \
# 	dd of=$(IMG) bs=1 seek=446 conv=notrunc status=none
# 	printf '\x55\xAA' | dd of=$(IMG) bs=1 seek=510 conv=notrunc status=none

#	@echo "=== Format FAT16 filesystem ==="
#	mformat -i $(IMG)@@1048576 -F :: > /dev/null

	@echo "=== Copy binaries ==="
	mcopy -i $(IMG)@@1048576 $(MON_BIN) ::/MONITOR.BIN
	mcopy -i $(IMG)@@1048576 $(TTS_BIN) ::/TTS.BIN
	mcopy -i $(IMG)@@1048576 $(ECHO_BIN) ::/ECHO
	mcopy -i $(IMG)@@1048576 $(BCD_BIN) ::/BCD
	mcopy -i $(IMG)@@1048576 $(ALLOC_T_BIN) ::/ALLOCT
	mcopy -i $(IMG)@@1048576 $(DEBUG_BIN) ::/DEBUG
	mcopy -i $(IMG)@@1048576 $(LS_BIN) ::/LS
	mcopy -i $(IMG)@@1048576 $(APP_BIN) ::/APP.BIN
	mcopy -i $(IMG)@@1048576 $(APP1_BIN) ::/APP1.BIN
	mcopy -i $(IMG)@@1048576 $(APP_BIN) ::/APP2.BIN
	mcopy -i $(IMG)@@1048576 $(APP_BIN) ::/APP3.BIN
	mcopy -i $(IMG)@@1048576 $(APP_BIN) ::/APP4.BIN
	mcopy -i $(IMG)@@1048576 $(APP_BIN) ::/APP5.BIN
	mcopy -i $(IMG)@@1048576 $(APP_BIN) ::/APP6.BIN
	mcopy -i $(IMG)@@1048576 $(APP_BIN) ::/APP7.BIN
	mcopy -i $(IMG)@@1048576 $(APP_BIN) ::/APP8.BIN
	mcopy -i $(IMG)@@1048576 $(APP_BIN) ::/APP9.BIN
# 	mcopy -i $(IMG)@@1048576 $(APP_BIN) ::/APPA.BIN
# 	mcopy -i $(IMG)@@1048576 $(APP_BIN) ::/APPB.BIN
# 	mcopy -i $(IMG)@@1048576 $(APP_BIN) ::/APPC.BIN
# 	mcopy -i $(IMG)@@1048576 $(APP_BIN) ::/APPD.BIN
# 	mcopy -i $(IMG)@@1048576 $(APP_BIN) ::/APPE.BIN
# 	mcopy -i $(IMG)@@1048576 $(APP_BIN) ::/APPF.BIN
	mmd -i $(IMG)@@1048576 ::/TESTDIR

# 	@echo "=== Install boot sector (VBR) ==="
# 	dd if=$(BOOT1_BIN) of=$(IMG) bs=512 seek=2048 conv=notrunc status=none
	dd if=$(BOOT1_BIN) of=$(IMG) bs=512 seek=2048 count=4 conv=notrunc status=none
	@echo "=== Done: $(IMG) ready ==="

# ===============================================================
#  Cleanup
# ===============================================================
clean:
	rm -rf $(BUILD)


.PHONY: all image clean
mount:
	sudo losetup -Pf --show -f $(IMG)

unmount:
	sudo losetup -D

img: $(IMG)

run: $(IMG)
	qemu-system-i386 \
		-drive file=build/disk.img,format=raw,if=ide,index=0,media=disk \
		-boot c \
		-debugcon stdio -serial none -monitor none

# 	qemu-system-i386 -drive file=build/disk.img,format=raw,if=ide -boot c \
# 	-debugcon stdio -serial none -monitor none

#	qemu-system-i386 -hda $(IMG) -boot c \
#		-debugcon stdio  -serial none -monitor none 
#	qemu-system-i386 -drive file=$(IMG),format=raw,if=floppy -boot a \
#		-debugcon stdio  -d cpu_reset,int -no-reboot -serial none -monitor none 2>&1 | tee qemu.log

dump: $(IMG)
	od -tx1z -Ax $(IMG)


#clean:
#	@rm -rf $(OUT)

#
#	mshowfat -i build/disk.img@@1048576 ::/MONITOR.BIN
#	mdir -i build/disk.img@@1048576 ::
#
