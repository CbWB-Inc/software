EFIINC = /usr/include/efi
EFILIB = /usr/lib
EFILDS = /usr/lib/elf_x86_64_efi.lds
EFICRT = /usr/lib/crt0-efi-x86_64.o
EFILIBS = $(EFILIB)/libgnuefi.a $(EFILIB)/libefi.a

TARGET = bootdisk/EFI/BOOT/BOOTX64.EFI
KERNEL = kernel.bin
FATIMG = fat.img

.PHONY: all run clean

all: $(TARGET) $(KERNEL)

loader.o: loader.c
	gcc -I$(EFIINC) -I$(EFIINC)/x86_64 -DEFI_FUNCTION_WRAPPER \
	    -fno-stack-protector -fpic -fshort-wchar -mno-red-zone \
	    -c $< -o $@


loader.so: loader.o 
	x86_64-linux-gnu-ld -nostdlib -znocombreloc -T $(EFILDS) -shared -Bsymbolic \
	    $(EFICRT) loader.o $(EFILIBS) -o $@

$(KERNEL): kernel.c
	gcc -I$(EFIINC) -I$(EFIINC)/x86_64 -DEFI_FUNCTION_WRAPPER \
	    -fno-stack-protector -fpic -fshort-wchar -mno-red-zone \
	    -c $< -o $@


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
	    -m 1024 \
		-bios OVMF.fd \
	    -drive file=$(FATIMG),format=raw \
	    -serial stdio 
#		-no-reboot

clean:
	rm -f loader.o loader.so $(TARGET) $(KERNEL)
	rm -f $(FATIMG)
	rm -rf bootdisk
