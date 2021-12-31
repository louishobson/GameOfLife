#!/bin/make
#
# Copyright (C) 2021 Louis Hobson <louis-hobson@hotmail.co.uk>. All Rights Reserved.
#
# Distributed under MIT licence as a part of a cellular automaton project.
# For details, see: https://github.com/louishobson/GameOfLife/blob/master/LICENSE
#
# See README.md for dependencies.

all: tzx bin wav

tzx: tzx/GameOfLife.tzx
bin: bin/GoLBytes.bin
wav: wav/GameOfLife.wav



.PHONY: clean
clean:
	find . -type f -name "*\.bin" -delete -print
	find . -type f -name "*\.tzx" -delete -print
	find . -type f -name "*\.wav" -delete -print



.PHONY: prepare
prepare:
	mkdir -p bin tzx wav



tzx/GameOfLife.tzx:  Interface.asm World.asm NextGeneration.asm IO.asm Macros.asm
	zxbasm -TBa -O0 Interface.asm -o tzx/GameOfLife.tzx -l "GameOfLife" -p "GoLBytes" -S 60000

bin/GoLBytes.bin: Interface.asm World.asm NextGeneration.asm IO.asm Macros.asm
	zxbasm -O0 Interface.asm -o bin/GoLBytes.bin



wav/GameOfLife.wav: tzx/GameOfLife.tzx
	tape2wav tzx/GameOfLife.tzx wav/GameOfLife.wav



run: tzx/GameOfLife.tzx
	fuse --no-sound tzx/GameOfLife.tzx

play: wav/GameOfLife.wav
	vlc wav/GameOfLife.wav