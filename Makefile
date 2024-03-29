#####
## BUILD
#####
SPIKE=spike
CC=riscv64-unknown-linux-gnu-gcc
CFLAGS=-Wall -Wextra -pedantic -Wextra -O0 -g -std=c11
CFLAGS+=-static -ffreestanding -nostdlib -fno-exceptions
CFLAGS+=-march=rv64gc -mabi=lp64
INCLUDES=
LINKER_SCRIPT=-Tinit/src/lds/virt.ld

profile=
cargo_profile= 
TYPE=debug
ifeq ($(profile), release)
	TYPE=release 
	cargo_profile=--release
endif

RUST_TARGET_INIT=./init/target/riscv64_soft_float/$(TYPE)
RUST_TARGET_UKERNEL=./ukernel/target/riscv64_soft_float/$(TYPE)
LIBS=-L$(RUST_TARGET_INIT) -L$(RUST_TARGET_UKERNEL)

SOURCES_ASM=$(wildcard ukernel/src/asm/*.S)
SOURCES_C=$(wildcard ukernel/src/**/*.c)

LIB=-lukernel -linit -lgcc
OUT=os.elf
MODE=-d
mode=debug
ifeq ($(mode), log)
	MODE=-l 
endif


#####
## QEMU
#####
QEMU=qemu-system-riscv64
MACH=virt
CPU=rv64
CPUS=4
MEM=128M
DRIVE=hdd.dsk



all: 
	cd init; cargo build $(cargo_profile)
	cd ukernel; cargo build $(cargo_profile)
	$(CC) $(CFLAGS) $(LINKER_SCRIPT) $(INCLUDES) -o $(OUT) $(SOURCES_ASM) $(SOURCES_C) $(LIBS) $(LIB)

	
run: all
	$(QEMU) -machine $(MACH) -cpu $(CPU) -smp $(CPUS) -m $(MEM)  -nographic -serial mon:stdio -bios none -kernel $(OUT) -drive if=none,format=raw,file=$(DRIVE),id=foo -device virtio-blk-device,scsi=off,drive=foo

dumpdbt: 
	$(QEMU) -machine $(MACH) -machine dumpdtb=riscv64-$(MACH).dtb

spike: all dumpdbt
	$(SPIKE) --isa rv64gc --priv msu --dtb riscv64-$(MACH).dtb $(MODE) $(OUT)

.PHONY: clean
clean:
	cd init && cargo clean 
	cd ukernel && cargo clean
	rm -f $(OUT)
