FILES = ./build/kernel.asm.o ./build/kernel.o
FLAGS = -g -ffreestanding -nostdlib -nostartfiles -nodefaultlibs -Wall -O0 -Iinc

all:
	# Bootloader mit NASM kompilieren
	nasm -f bin ./src/boot.asm -o ./out/boot.bin

	# Kernel-Assembly-Code kompilieren
	nasm -f elf -g ./src/kernel.asm -o ./build/kernel.asm.o

	# Kernel-C-Code kompilieren
	i686-elf-gcc -I./src $(FLAGS) -std=gnu99 -c ./src/kernel.c -o ./build/kernel.o

	# Objektdateien zu einer relocatable Datei linken
	i686-elf-ld -g -relocatable $(FILES) -o ./build/completeKernel.o

	# Alles zu einer finalen Kernel-Binärdatei linken
	i686-elf-gcc $(FLAGS) -T ./src/linkerScript.ld -o ./out/kernel.bin -ffreestanding -nostdlib ./build/completeKernel.o

	# Endgültige OS-Binärdatei erstellen
	dd if=./out/boot.bin of=./out/os.bin bs=512 seek=0
	dd if=./out/kernel.bin of=./out/os.bin bs=512 seek=1
	dd if=/dev/zero bs=512 count=8 >> ./out/os.bin

clean:
	# Alle generierten Dateien löschen
	rm -f ./out/boot.bin
	rm -f ./out/kernel.bin
	rm -f ./out/os.bin
	rm -f ./build/kernel.asm.o
	rm -f ./build/kernel.o
	rm -f ./build/completeKernel.o
