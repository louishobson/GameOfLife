;
; Copyright (C) 2021 Louis Hobson <louis-hobson@hotmail.co.uk>. All Rights Reserved.
;
; Distributed under MIT licence as a part of a cellular automaton project.
; For details, see: https://github.com/louishobson/GameOfLife/blob/master/LICENSE
;
; World.asm
;
; Contains functions for interfacing with the current world(s).



; Include macros
#include "Macros.asm"





; A function to get the world byte location from cursor coordinates stored in de.
; The world location is stored in hl, and the a is set to the bitmask for the correct bit of the world byte.
GET_WORLD_BYTE_LOCATION:

	; Set hl to ix
	push	ix
	pop		hl

	; We want (upper of ix)  0 Y4 Y3 Y2 Y1 Y0 X4 X3.
	; Sort out the Ys first. Store them in l.
	ld		a,d
	rlca
	rlca
	ld		l,a

	; Copy X0-X2 into d temporarily.
	ld		a,e
	and		%00000111
	ld		d,a

	; Shift X right and or it with the Ys and we are done.
    ; Copy the result into l.
	ld		a,e
	and		%11111000
	rrca
	rrca
	rrca
	or		l
	ld		l,a

	; Now we produce the mask.
	; While decrementing d is non-negative, rotate a right.
	ld		a,%00000001
	GET_WORLD_BYTE_LOCATION_MASK_LOOP:
		rrca
		dec		d
		jp		p,START+GET_WORLD_BYTE_LOCATION_MASK_LOOP

	; Return
	ret





; A function to fill the current world, pointed to by ix.
; Fills each byte with the contents of a.
; Modifies hl and b
FILL_WORLD:

	; Set hl to the current world position.
	push	ix
	pop		hl

	; Write into the world
	ld		b,96
	FILL_WORLD_LOOP:
		ld		(hl),a
		inc		hl
		djnz	FILL_WORLD_LOOP

	; Return
	ret





; This function reloads a world onto the screen.
; The world pointed to by ix is loaded.
; Modifies bc and hl.
DISPLAY_WORLD:

	; Wait for the frame to write
	halt

	; Set hl to the position of the first screen attribute
    ld		hl,ATTRIBUTE_DATA

	; Loop through all bytes to display the world.
	; Set b to count through the bytes.
	ld		b,96
	DISPLAY_WORLD_LOOP:

		; Load the next byte into c and complement it.
		ld		a,(ix+0)
		cpl
		ld		c,a

		; Iterate over the bits in c and set the attributes
		sla		c
		sbc		a,a
		ld		(hl),a
		inc		hl

		sla		c
		sbc		a,a
		ld		(hl),a
		inc		hl

		sla		c
		sbc		a,a
		ld		(hl),a
		inc		hl

		sla		c
		sbc		a,a
		ld		(hl),a
		inc		hl

		sla		c
		sbc		a,a
		ld		(hl),a
		inc		hl

		sla		c
		sbc		a,a
		ld		(hl),a
		inc		hl

		sla		c
		sbc		a,a
		ld		(hl),a
		inc		hl

		sla		c
		sbc		a,a
		ld		(hl),a
		inc		hl

		; Increment ix
		inc 	ix

		; Now loop to the next byte of the world
		djnz	DISPLAY_WORLD_LOOP

	; Reset ix
	ld		bc,65536-96
	add		ix,bc

	; Return
	ret





; Include the next generation code
#include "NextGeneration.asm"