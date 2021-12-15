#!/bin/make

all: GameOfLifeLoader.tzx GameOfLifeBytes.tzx GameOfLifeBytes.bin GameOfLife.tzx GameOfLife.wav

.PHONY: clean
clean:
	find . -type f -name "*\.bin" -delete -print
	find . -type f -name "*\.bin" -delete -print
	find . -type f -name "*\.tzx" -delete -print
	find . -type f -name "*\.wav" -delete -print

GameOfLifeLoader.tzx: GameOfLifeLoader.tzx_
	cp GameOfLifeLoader.tzx_ GameOfLifeLoader.tzx

GameOfLifeBytes.tzx: GameOfLife.asm
	/home/louis/Downloads/zxbasic/zxbasic/zxbasm -T -O0 GameOfLife.asm -o GameOfLifeBytes.tzx

GameOfLifeBytes.bin: GameOfLife.asm
	/home/louis/Downloads/zxbasic/zxbasic/zxbasm -O0 GameOfLife.asm -o GameOfLifeBytes.bin

GameOfLife.tzx: GameOfLifeLoader.tzx GameOfLifeBytes.tzx
	tzxmerge GameOfLifeLoader.tzx GameOfLifeBytes.tzx -o GameOfLife.tzx

GameOfLife.wav: GameOfLife.tzx
	tape2wav GameOfLife.tzx GameOfLife.wav

run: GameOfLife.tzx
	fuse --no-sound --no-auto-load --tape GameOfLife.tzx

play: GameOfLife.wav
	vlc GameOfLife.wav