EFIINC = /usr/include/efi
EFILIB = /usr/lib
EFILDS = /usr/lib/elf_x86_64_efi.lds
EFICRT = /usr/lib/crt0-efi-x86_64.o
EFILIBS = $(EFILIB)/libgnuefi.a $(EFILIB)/libefi.a

TARGET = bootdisk/EFI/BOOT/BOOTX64.EFI
KERNEL = kernel.bin
FATIMG = fat.img

KSRCS := kernel.c log.c debug.c routine.c interrupt.c main.c framebuffer.c data.o \
			kbd_isr_stub.o mouse_isr_stub.o inout.c lapic_timer_isr_stub.o task.c disk.c rnd.c

KOBJS := $(KSRCS:.c=.o)

CFLAGS = -I$(EFIINC) -I$(EFILIB) \
  -fno-stack-protector -fpic -fshort-wchar \
  -ffreestanding -fno-stack-protector \
  -mno-red-zone -mno-mmx -mno-sse -mno-sse2 \
	-fno-asynchronous-unwind-tables -fno-exceptions -fno-pic \
  -ffreestanding -DEFI_FUNCTION_WRAPPER \
  -m64 \
  -msoft-float

CFLAGS2 = -I$(EFIINC) -I$(EFILIB) \
  -fno-stack-protector -fpic -fshort-wchar \
  -ffreestanding -fno-stack-protector \
  -mno-red-zone \
	-fno-asynchronous-unwind-tables -fno-exceptions -fno-pic \
  -ffreestanding -DEFI_FUNCTION_WRAPPER \
  -m64 \
  -msoft-float


.PHONY: all run clean

all: $(TARGET) $(KERNEL)

loader.o: loader.c
	gcc $(CFLAGS) -DEFI_FUNCTION_WRAPPER \
	    -fpic  \
	    -c $< -o $@

loader.so: loader.o 
	x86_64-linux-gnu-ld -nostdlib -znocombreloc -T $(EFILDS) -shared -Bsymbolic \
	    $(EFICRT) loader.o $(EFILIBS) -o $@

kernel.o: kernel.c handoff.h log.h
	$(CC) $(CFLAGS_KERNEL) $(CFLAGS) -c $< -o $@

log.o: log.c log.h
	$(CC) $(CFLAGS_KERNEL) $(CFLAGS) -c $< -o $@

debug.o: debug.c log.h
	$(CC) $(CFLAGS_KERNEL) $(CFLAGS) -c $< -o $@

routine.o: routine.c log.h
	$(CC) $(CFLAGS_KERNEL) $(CFLAGS) -c $< -o $@

main.o: main.c log.h
	$(CC) $(CFLAGS_KERNEL) $(CFLAGS2) -c $< -o $@

interrupt.o: interrupt.c log.h
	$(CC) $(CFLAGS_KERNEL) $(CFLAGS) -mgeneral-regs-only -I$(EFIINC) -I$(EFIINC)/x86_64 -c $< -o $@

framebuffer.o: framebuffer.c 
	$(CC) $(CFLAGS_KERNEL) $(CFLAGS) -c $< -o $@

task.o: task.c 
	$(CC) $(CFLAGS_KERNEL) $(CFLAGS) -c $< -o $@

inout.o: inout.c 
	$(CC) $(CFLAGS_KERNEL) $(CFLAGS) -c $< -o $@

disk.o: disk.c 
	$(CC) $(CFLAGS_KERNEL) $(CFLAGS) -c $< -o $@

rnd.o: rnd.c log.h
	$(CC) $(CFLAGS_KERNEL) $(CFLAGS2) -c $< -o $@

data.o: data.asm
	nasm -f elf64 data.asm -o data.o

kbd_isr_stub.o: kbd_isr_stub.asm
	nasm -f elf64 kbd_isr_stub.asm -o kbd_isr_stub.o

mouse_isr_stub.o: mouse_isr_stub.asm
	nasm -f elf64 mouse_isr_stub.asm -o mouse_isr_stub.o

lapic_timer_isr_stub.o: lapic_timer_isr_stub.asm
	nasm -f elf64 lapic_timer_isr_stub.asm -o lapic_timer_isr_stub.o

kernel.elf: $(KOBJS)
	ld -nostdlib -z max-page-size=0x1000 -Ttext 0x100000 -e kernel_main -o $@ $(KOBJS)

kernel.bin: kernel.elf
	objcopy -O binary $< $@

$(TARGET): loader.so
	mkdir -p $(dir $@)
	x86_64-linux-gnu-objcopy \
	    -j .text -j .sdata -j .data -j .rodata -j .dynamic \
	    -j .dynsym -j .rel -j .rela -j .reloc \
	    --target=efi-app-x86_64 $< $@

$(FATIMG):
	dd if=/dev/zero of=$@ bs=1M count=64
	mkfs.vfat $@

run: all $(FATIMG)
	mmd -i $(FATIMG) ::/EFI || true
	mmd -i $(FATIMG) ::/EFI/BOOT || true
	# Copy kernel binary
	mcopy -o -i $(FATIMG) $(KERNEL) ::/
	# Copy EFI loader
	mcopy -o -i $(FATIMG) $(TARGET) ::/EFI/BOOT/
	# Copy kernel binary
	mcopy -o -i fat.img kernel.bin ::/
	# ←同期を促す
	mdir -i fat.img ::/ > /dev/null	# Boot QEMU
	qemu-system-x86_64 \
		-cpu qemu64,+rdrand  \
		-bios ./OVMF.fd \
		-m 1024 \
		-debugcon file:debug.log -global isa-debugcon.iobase=0xe9 \
		-device ahci,id=ahci0 \
		-drive if=none,file=fat.img,format=raw,id=d0 \
		-device ide-hd,drive=d0,bus=ahci0.0	\
		-serial stdio \
		-no-reboot	\
		-machine q35


# 		-debugcon file:debug.log -global isa-debugcon.iobase=0xE9 

clean:
	rm -f *.o *.so *.elf $(TARGET) $(KERNEL)
	rm -f $(FATIMG)
	rm -rf bootdisk
