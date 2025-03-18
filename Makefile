all:
		nasm -f bin ./src/boot.asm -o ./out/boot.bin

clean:
		rm -f ./out/boot.bin
