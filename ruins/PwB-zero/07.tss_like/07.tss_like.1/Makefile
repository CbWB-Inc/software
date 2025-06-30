#
NASM=nasm
IMG=os.img
QEMU = qemu-system-x86_64

all: $(IMG)

# アセンブル各ファイル（flat binary形式）
bios.bin: bios.asm
	$(NASM) -f bin -o $@ $<

main.bin: main.asm
	$(NASM) -f bin -o $@ $<

func.bin: func.asm
	$(NASM) -f bin -o $@ $<

func2.bin: func2.asm
	$(NASM) -f bin -o $@ $<

#task.bin: task.asm
#	$(NASM) -f bin -o $@ $<

# padツール
# 引数：<出力名> <セクタ数>
define mkpad
	dd if=/dev/zero of=$1 bs=512 count=$2 status=none
endef

# OSイメージ構築（各ファイルを適切な位置に並べる）
$(IMG): bios.bin main.bin func.bin func2.bin
	@echo ">>> creating $@"

	# ステージ0: パディングを生成
	$(call mkpad,pad0.bin,1)    # セクタ1: 空き
	$(call mkpad,pad1.bin,5)    # セクタ3-7: 空き
	$(call mkpad,pad2.bin,4)    # セクタ20-23: 空き
	$(call mkpad,pad3.bin,2)    # セクタ25-26: 空き

	# ステージ1: 結合（順に注意）
	#cat bios.bin                \
	#    main.bin                \
	#    pad0.bin                \
	#    task.bin                \
	#    pad1.bin                \
	#    func.bin                \
	#    pad2.bin                \
	#    func2.bin               \
	#    pad3.bin                \
	#    > $(IMG)

	cat bios.bin pad1.bin main.bin pad2.bin func.bin pad3.bin func2.bin > os.img

	@echo ">>> done"

# QEMUで起動
run: $(IMG)
	$(QEMU) $(IMG)

clean:
	rm -f *.bin pad*.bin $(IMG)
	
dis1: $(IMG)
	nasm -f bin $(IMG) -o $(OBJ) -l __a.tmp
	cat __a.tmp

dis2: $(IMG)
	objdump -b binary -m i8086 -M intel -D --show-raw-insn --prefix-addresses $(IMG)

dump: $(IMG)
	od -tx1z -Ax $(IMG)

DEBUG: $(IMG)
	qemu-system-x86_64 -enable-kvm -kernel $(IMG) -s -S


