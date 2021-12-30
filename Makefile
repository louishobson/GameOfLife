#!/bin/make
#
# Copyright (C) 2021 Louis Hobson <louis-hobson@hotmail.co.uk>. All Rights Reserved.
#
# Distributed under MIT licence as a part of a cellular automaton project.
# For details, see: https://github.com/louishobson/GameOfLife/blob/master/LICENSE
#
# Executable dependencies:
#
# zxbasm: Z80 assembler: https://zxbasic.readthedocs.io/
# tzxmerge: Joins TZX files: https://shredzone.org/docs/tzxtools/
# tape2wav: Converts a TZX to a WAV file: Part of FUSE Emulator utils
# fuse: Spectrum emulator: https://sourceforge.net/projects/fuse-emulator/
# vlc: VLC media player

all: tzx bin wav

tzx: tzx/GameOfLifeLoader.tzx tzx/GameOfLifeBytes.tzx tzx/GameOfLife.tzx
bin: bin/GameOfLifeBytes.bin
wav: wav/GameOfLife.wav

.PHONY: clean
clean:
	find . -type f -name "*\.bin" -delete -print
	find . -type f -name "*\.tzx" -delete -print
	find . -type f -name "*\.wav" -delete -print

.PHONY: prepare
prepare:
	mkdir -p bin tzx wav

tzx/GameOfLifeLoader.tzx: GameOfLifeLoader.tzx_
	cp GameOfLifeLoader.tzx_ tzx/GameOfLifeLoader.tzx

tzx/GameOfLifeBytes.tzx: Interface.asm World.asm NextGeneration.asm IO.asm Macros.asm
	zxbasm -T -O0 Interface.asm -o tzx/GameOfLifeBytes.tzx

bin/GameOfLifeBytes.bin: Interface.asm World.asm NextGeneration.asm IO.asm Macros.asm
	zxbasm -O0 Interface.asm -o bin/GameOfLifeBytes.bin

tzx/GameOfLife.tzx: tzx/GameOfLifeLoader.tzx tzx/GameOfLifeBytes.tzx
	tzxmerge tzx/GameOfLifeLoader.tzx tzx/GameOfLifeBytes.tzx -o tzx/GameOfLife.tzx

wav/GameOfLife.wav: tzx/GameOfLife.tzx
	tape2wav tzx/GameOfLife.tzx wav/GameOfLife.wav

run: tzx/GameOfLife.tzx
	fuse --no-sound --no-auto-load --tape tzx/GameOfLife.tzx

play: wav/GameOfLife.wav
	vlc wav/GameOfLife.wav