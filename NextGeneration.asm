;
; Copyright (C) 2021 Louis Hobson <louis-hobson@hotmail.co.uk>. All Rights Reserved.
;
; Distributed under MIT licence as a part of a cellular automaton project.
; For details, see: https://github.com/louishobson/GameOfLife/blob/master/LICENSE
;
; NextGeneration.asm
;
; Contains functions for creating the next generation.



; Include macros
#include "Macros.asm"





; This function sets up the program calculates the next generation.
; ix and iy are automatically swapped.
NEXT_GENERATION:

	; Set b, the byte counter, to 9, so we can count bits before we need to write to the world
	ld		b,9

	; Set c, the column counter, to 96, so we can count columns and rows
	ld 		c,96

	; Set e, the column accumulator, to 0, so we can accumulate the next byte of the new world
	ld 		e,0

	; Swap the registers
	exx

	; Load in the top, middle and bottom rows
	ld		b,(ix - 4)
	ld		d,(ix + 0)
	ld		h,(ix + 4)

	; Zero the back, centre and front accumulators.
	; These accumulate neighbors, creating the centre, front and back bits.
	ld		c,0
	ld		e,0
	ld		l,0

	; Call accumulation
	call	START+ACCUM_NEIGHBORS

	; Reduce ix and iy back to their original values
	ld		bc,65536-96
	add		ix,bc
	add		iy,bc

	; Swap ix and iy
	push 	ix
	push 	iy
	pop		ix
	pop		iy

	; Return
	ret





; This part of the program accumulates neighbors.
ACCUM_NEIGHBORS:

	ACCUM_NEIGHBORS_TOP:

		; Test the top row and jump to the middle row if the bit is unset
		sla		b
		jr		nc,ACCUM_NEIGHBORS_MID

		; Acumulate neighbors
		inc		c
		inc		e
		inc		l

	ACCUM_NEIGHBORS_MID:

		; Test the middle row and jump to the bottom row if the bit is unset
		sla		d
		jr		nc,ACCUM_NEIGHBORS_BOT

		; Acumulate neighbors. Don't increment the centre accumulator (e): a cell is not its own neighbor
		inc		c
		inc		l

		; Increase e by 9 if it is alive
		ld		a,e
		add		a,9
		ld		e,a

	ACCUM_NEIGHBORS_BOT:

		; Test the bottom row and jump to the end if the bit is unset
		sla		h
		jr		nc,ACCUM_NEIGHBORS_FIN

		; Acumulate neighbors.
		inc		c
		inc		e
		inc		l

	ACCUM_NEIGHBORS_FIN:

		; Push the oldest two accumulators onto the stack
		push	de
		push 	bc

		; Now we jump to the update section (automatically since it is the next section in code)





; This part updates the next world in memory
ACCUM_WORLD:

	; Swap to update registers
	exx

	; We always want to write the back bit to the column accumulator
	pop		hl
	call	START+WRITE_WORLD_BIT

	; Pop the middle bit
	pop		hl

	; If the byte counter is now 1, then we have finished the column.
	; Otherwise we need to continue with this column.
	; However if the byte counter is 0, we need to write the column accumulator to memory.
	ld		a,b
	cp		1
	jr		z,ACCUM_WORLD_NEW_COLUMN
	jp		p,START+ACCUM_WORLD_SAME_COLUMN

	; The byte counter is 0, so write the column accumulator to memory and set the byte counter to 8.
    ld		(iy - 1),e
    ld		b,8

	; We are still working on the current column
	ACCUM_WORLD_SAME_COLUMN:

		; Swap to accum registers and return to accumulating
		exx
		jr		ACCUM_NEIGHBORS

	; We have entered a new column
	ACCUM_WORLD_NEW_COLUMN:

		; Increment ix and iy and decrement c
		inc		ix
		inc		iy
		dec 	c

		; If this is not a new row, load the next column into registers
		ld		a,c
		and 	%11
		jr		nz,ACCUM_WORLD_LOAD_NEXT_COLUMN

		; If we just finished a row, write the centre bit to the column accumulator.
		; We are now done with this byte, so write it to memory and the screen.
		; Set the byte counter back to 9, then resume accumulating.
		call	START+WRITE_WORLD_BIT
        ld		(iy - 1),e
        ld		b,9

		; If this is the end of the last row, return
		ld		a,c
		and		a
		ret		z

	; Load the next column and continue accumulating.
	ACCUM_WORLD_LOAD_NEXT_COLUMN:

		; Swap to accum registers
        exx

		; Update the top, middle and bottom bytes
		ld		b,(ix - 4)
		ld 		d,(ix + 0)
		ld 		h,(ix + 4)

		; Jump to accumulation
		jr		ACCUM_NEIGHBORS





; This part takes a number of neighbors, and updates the column accumulator accordingly.
; The number of neighbors must be stored in the register l.
; The back...front accumulators will be shifted along one step.
; The function will modify hl.
WRITE_WORLD_BIT:

	; Get the position in memory of the rule.
	; Since we have set l to the number of neighbors, we simply need to set h to the upper byte of the rules position
	ld		h,RULES_UPPER

	; Load the rule into the accumulator
	ld		a,(hl)

	; Shift the rule, so that its value goes into the carry bit.
	; Then shift the carry bit into e.
	rla
	rl		e

	; Decrement the byte counter
	dec		b

	; Shift back...front accumulator registers
	exx
	ld		c,e
	ld		e,l
	ld		l,0
	exx

	; Return
	ret