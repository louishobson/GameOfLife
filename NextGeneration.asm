;
; NextGeneration.asm
;
; Contains functions for creating the next generation.

; Include macros
#include "Macros.asm"





; This function sets up the program calculates the next generation.
; ix and iy are automatically swapped.
NEXT_GENERATION:

	; Disable interrupts
	di

	; Set b, the byte counter, to 9 so we can count bits
	ld		b,9

	; Set c, the column counter, to 96 so we can count columns and rows
	ld 		c,96

	; Set e, the column accumulator, to 0 so we can accumulate the next byte of the new world
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

	; Enable interrupts
	ei

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

	; If the byte counter is now 1, then we have finished the column.
	; If the byte counter is now 0, then we write the column accumulator to memory (and set the byte counter to 8 implicitly).
	ld		a,b
	cp		1
	jr		z,ACCUM_WORLD_NEW_COLUMN
	call	m,START+WRITE_WORLD_BYTE

	; We are still working on the current column
	ACCUM_WORLD_SAME_COLUMN:

		; Pop the centre accumulator
		pop		hl

		; Swap to accum registers and return to accumulating
		exx
		jp		START+ACCUM_NEIGHBORS

	; We have entered a new column
	ACCUM_WORLD_NEW_COLUMN:

		; We may also have a new row.
		; We can detect this if the decremented column counter is a multiple of 4.
		; Write the centre bit to the column accumulator if there is a new row
		dec 	c
		ld		a,c
		and 	%11
		pop		hl
		call	z,START+WRITE_WORLD_BIT

	; Load the next column
	ACCUM_WORLD_LOAD_NEXT_COLUMN:

		; Increment ix and iy
		inc		ix
		inc		iy

		; If this is not a new row, jump to column skip detection
		ld		a,c
		and 	%11
		jr		nz,ACCUM_WORLD_SKIP_DETECT

		; We are now done with this byte, so write it to memory and the screen.
		; Set the byte counter back to 9, then resume accumulating.
		call	START+WRITE_WORLD_BYTE
		inc		b

		; If this is the end of the last row, return
		ld		a,c
		and		a
		ret		z

	; Possibly skip accumulation if top, middle and bottom bytes are 0
	ACCUM_WORLD_SKIP_DETECT:

		; Swap to accum registers
		exx

		; Update the top, middle and bottom bytes
		ld		b,(ix - 4)
		ld 		d,(ix + 0)
		ld 		h,(ix + 4)

		; If top, middle and bottom bytes are zero, and the centre accumulator is zero, we can skip the column.
		; We want the centre accumulator to be zero, as we don't want any non-zero neighbors in this column.
		xor		a
		or		b
		or		d
		or		e
		or		h
		jr		nz,ACCUM_NEIGHBORS

	; Skip this column (all zeros)
	ACCUM_WORLD_SKIP_COLUMN:

		; Push the back accumulator onto the stack
		push	bc

		; Zero the back accumulator
		ld		c,0

		; Swap to update registers
		exx

		; If we did not start a new row, we want to write the back bit to the column accumulator, and then write the accumulator to memory
		ld		a,c
		and		%11
		pop		hl
		call	nz,START+WRITE_WORLD_BIT
		ld		a,c
		and		%11
		call	nz,START+WRITE_WORLD_BYTE

		; Decrement the column counter
		dec		c

		; Fill the column accumulator with the no-neighbors rule
		ld		hl,RULES
		ld		e,(hl)

		; Set b to 1
		ld		b,1

		; Jump to ACCUM_WORLD_LOAD_NEXT_COLUMN
		jp		START+ACCUM_WORLD_LOAD_NEXT_COLUMN





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





; This part saves a byte back to the world, and also writes to the screen.
; The byte is taken from the column accumulator, and written to (iy-1).
; Has the byproduct of setting the byte counter to 8.
WRITE_WORLD_BYTE:

	; Write the column accumulator to memory
	ld		(iy - 1),e

	; Load 95 into a, and subtract the column counter.
	; This gives us the offset from the start of screen attributes in memory divided by 8.
	; Therefore we need to multiply it by 8.
	; We load a into hl, and add in the screen offset divided by 8.
	; We can then multiply hl by 8 to get the write offset.
	ld		a,95
	sub		c
	ld		h,ATTRIBUTE_DATA_UPPER/8
	ld		l,a
	add		hl,hl
	add		hl,hl
	add		hl,hl

	; Possibly flip the screen colors
	ld		a,(COLOR_FLIP)
	xor		e
	ld		e,a

	; Iterate over the bits in the column accumulator and set the attributes

	sla		e
	sbc		a,a
	ld		(hl),a
	inc		hl

	sla		e
    sbc		a,a
    ld		(hl),a
    inc		hl

	sla		e
    sbc		a,a
    ld		(hl),a
    inc		hl

	sla		e
    sbc		a,a
    ld		(hl),a
    inc		hl

	sla		e
    sbc		a,a
    ld		(hl),a
    inc		hl

	sla		e
    sbc		a,a
    ld		(hl),a
    inc		hl

	sla		e
    sbc		a,a
    ld		(hl),a
    inc		hl

	sla		e
    sbc		a,a
    ld		(hl),a

	; Set the byte counter to 8
	ld		b,8

	; Return
	ret