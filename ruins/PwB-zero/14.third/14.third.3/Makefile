NASM = nasm

all: os.img

# 各 bin ファイルの生成
boot.bin: boot.asm
	$(NASM) -f bin boot.asm -o boot.bin

main.bin: main.asm routine.asm
	$(NASM) -f bin main.asm -o main.bin

k_task.bin: k_task.asm routine.asm
	$(NASM) -f bin k_task.asm -o k_task.bin

d_task.bin: d_task.asm routine.asm
	$(NASM) -f bin d_task.asm -o d_task.bin

p_task.bin: p_task.asm routine.asm
	$(NASM) -f bin p_task.asm -o p_task.bin

# カーネル（main + irq0 結合）
kernel.bin: main.bin k_task.bin d_task.bin
	cat main.bin  k_task.bin d_task.bin > kernel.bin

# OS イメージ生成（boot + kernel + tasks）
os.img: boot.bin kernel.bin p_task.bin
	cat boot.bin kernel.bin p_task.bin > os.img
	truncate -s 1474560 os.img

clean:
	rm -f *.bin *.img


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

