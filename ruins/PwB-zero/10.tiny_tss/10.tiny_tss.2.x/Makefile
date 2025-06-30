# ファイル名: Makefile

ASM = nasm
ASMFLAGS = -f bin

SRC = boot.asm
IMG = boot.img

QEMU = qemu-system-i386
QEMUFLAGS = -hda $(IMG)

all: run

$(IMG): $(SRC)
	$(ASM) $(ASMFLAGS) $(SRC) -o $(IMG)

run: $(IMG)
	$(QEMU) $(QEMUFLAGS)

clean:
	rm -f $(IMG)
