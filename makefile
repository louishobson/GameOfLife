#!/bin/make

all: tzx bin wav

tzx: tzx/GameOfLifeLoader.tzx tzx/GameOfLifeBytes.tzx tzx/GameOfLife.tzx
bin: bin/GameOfLifeBytes.bin
wav: wav/GameOfLife.wav

.PHONY: clean
clean:
	find . -type f -name "*\.bin" -delete -print
	find . -type f -name "*\.bin" -delete -print
	find . -type f -name "*\.tzx" -delete -print
	find . -type f -name "*\.wav" -delete -print

tzx/GameOfLifeLoader.tzx: GameOfLifeLoader.tzx_
	cp GameOfLifeLoader.tzx_ tzx/GameOfLifeLoader.tzx

tzx/GameOfLifeBytes.tzx: Interface.asm NextGeneration.asm IO.asm Macros.asm
	/home/louis/Downloads/zxbasic/zxbasic/zxbasm -T -O0 Interface.asm -o tzx/GameOfLifeBytes.tzx

bin/GameOfLifeBytes.bin: Interface.asm NextGeneration.asm IO.asm Macros.asm
	/home/louis/Downloads/zxbasic/zxbasic/zxbasm -O0 Interface.asm -o bin/GameOfLifeBytes.bin

tzx/GameOfLife.tzx: tzx/GameOfLifeLoader.tzx tzx/GameOfLifeBytes.tzx
	tzxmerge tzx/GameOfLifeLoader.tzx tzx/GameOfLifeBytes.tzx -o tzx/GameOfLife.tzx

wav/GameOfLife.wav: tzx/GameOfLife.tzx
	tape2wav tzx/GameOfLife.tzx wav/GameOfLife.wav

run: tzx/GameOfLife.tzx
	fuse --no-sound --no-auto-load --tape tzx/GameOfLife.tzx

play: wav/GameOfLife.wav
	vlc wav/GameOfLife.wav