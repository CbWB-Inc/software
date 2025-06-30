#
NASM = nasm
QEMU = qemu-system-x86_64

# 出力ファイル
IMG = os.img

# 各バイナリファイル名
BOOT_BIN = bios.bin
MAIN_BIN = main.bin
#ROUTINE_BIN = routine.bin
#FUNC_BIN = func.bin
#FUNC2_BIN = func2.bin
#FUNC3_BIN = func3.bin
#FUNC4_BIN = func4.bin

# デフォルトターゲット
all: $(IMG)

# アセンブル
$(BOOT_BIN): bios.asm
	$(NASM) -f bin -o $@ $<

$(MAIN_BIN): main.asm
	$(NASM) -f bin -o $@ $<

$(FUNC_BIN): func.asm
	$(NASM) -f bin -o $@ $<

$(FUNC2_BIN): func2.asm
	$(NASM) -f bin -o $@ $<

$(FUNC3_BIN): func3.asm
	$(NASM) -f bin -o $@ $<

$(FUNC4_BIN): func4.asm
	$(NASM) -f bin -o $@ $<

# 結合してディスクイメージを作成
$(IMG): $(BOOT_BIN) $(MAIN_BIN) 
	cat $(BOOT_BIN) $(MAIN_BIN) > $(IMG)

# QEMUで起動
run: $(IMG)
	$(QEMU) $(IMG)

# クリーン
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


