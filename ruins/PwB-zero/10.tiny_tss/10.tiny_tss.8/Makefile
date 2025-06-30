# ファイル名: Makefile

QEMU = qemu-system-x86_64

# ファイル名定義
BOOT_BIN = boot.bin
MAIN_BIN = main.bin
IMG = os.img

# デフォルトターゲット
all: $(IMG)

# boot.bin: ブートローダ
$(BOOT_BIN): boot.asm
	nasm -f bin boot.asm -o $(BOOT_BIN)

# main.bin: ABCマルチタスク本体（2セクタ目以降）
$(MAIN_BIN): main.asm
	nasm -f bin main.asm -o $(MAIN_BIN)

# os.img: 結合して起動ディスクイメージ作成
$(IMG): $(BOOT_BIN) $(MAIN_BIN)
	cat $(BOOT_BIN) $(MAIN_BIN) > $(IMG)

# QEMUで起動
run: $(IMG)
	$(QEMU) $(IMG)


# クリーンアップ
clean:
	rm -f $(BOOT_BIN) $(MAIN_BIN) $(IMG)

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

