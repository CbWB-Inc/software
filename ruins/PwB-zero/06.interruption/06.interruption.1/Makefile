#
NASM = nasm
QEMU = qemu-system-x86_64

# 出力ファイル
IMG = os.img

# 各バイナリファイル名
BOOT_BIN = bios.bin
MAIN_BIN = main.bin
ROUTINE_BIN = routine.bin

# デフォルトターゲット
all: $(IMG)

# アセンブル
$(BOOT_BIN): bios.asm
	$(NASM) -f bin -o $@ $<

$(MAIN_BIN): main.asm
	$(NASM) -f bin -o $@ $<

$(ROUTINE_BIN): routine.asm
	$(NASM) -f bin -o $@ $<

# 結合してディスクイメージを作成
$(IMG): $(BOOT_BIN) $(MAIN_BIN) $(ROUTINE_BIN)
	cat $(BOOT_BIN) $(MAIN_BIN) $(ROUTINE_BIN) > $(IMG)

# QEMUで起動
run: $(IMG)
	$(QEMU) $(IMG)

# クリーン
clean:
	rm -f $(BOOT_BIN) $(MAIN_BIN) $(ROUTINE_BIN) $(IMG)

dis1: $(SRC)
	nasm -f bin $(SRC) -o $(OBJ) -l __a.tmp
	cat __a.tmp

dis2: $(SRC)
	nasm -f bin $(SRC) -o $(OBJ)
	objdump -b binary -m i8086 -M intel -D --show-raw-insn --prefix-addresses $(OBJ)

dump: $(SRC)
	od -tx1z -Ax $(OBJ)

DEBUG: $(OBJ)
	qemu-system-x86_64 -enable-kvm -kernel $(OBJ) -s -S


