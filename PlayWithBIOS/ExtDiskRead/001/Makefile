# ===============================================================
#  hiFAX-ex boot experiment / HDD-style FAT16 image builder
# ===============================================================
SHELL := /bin/bash

# --- ファイル構成 ---
BUILD     := build
IMG       := $(BUILD)/disk.img

BIOS_SRC   := bios.asm

BIOS_BIN   := $(BUILD)/BIOS.BIN

# --- サイズ関連 ---
SIZE_MB   := 10
SECTORS   := $(shell expr $(SIZE_MB) \* 2048)  # 512B単位

# ===============================================================
#  default: assemble only
# ===============================================================
all: $(BIOS_BIN)

$(BUILD):
	mkdir -p $(BUILD)

# ===============================================================
#  Assembly rules
# ===============================================================
NASMFLAGS = -f bin

$(BIOS_BIN): $(BIOS_SRC) | $(BUILD)
	nasm $(NASMFLAGS) -o $@ $<


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
		-drive file=build/BIOS.BIN,format=raw,if=ide,index=0,media=disk \
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
