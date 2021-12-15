; The load position of the program
#define START 62000

; The position of the worlds
; Each world consists of 24 rows of 4 bytes, making 96 bytes in total
; There also needs to be padding of 4 zero bytes before and after each
; Therefore if we can set the worlds 100 bytes apart, so that they share some padding
#define WORLD1 63000
#define WORLD2 63100

; We will choose ix to point to the world we are reading from, and iy to the world we are writing to

ld ix,WORLD1
ld iy,WORLD2
ld (ix+0),%11000111
ld (ix+3),%00000011
ld (ix+32+2),%00000001
ld (ix+48+3),%00000010
ld (ix+95),%00000001
ld (ix+92),%10000000

; The position of the rule set
; Rather than packing the rule set, we just store 18 booleans as bytes.
; True means alive in the next generation, false means dead.
; The first 9 bytes define the rules for a living cell with 0 through 8 neighbors.
; The second 9 bytes define the same for a dead cell.
#define RULES 63200
ld hl,RULES
;ld (hl),1
ld	bc,9
add	hl,bc
ld (hl),1


; The position of screen attributes
#define SCREEN $5800

; Disable interrupts
di



; This part sets up the program for running the simulation
RUN_STARTUP:

	; Set b to 9 so we can count bits
	ld		b,9

	; Set c to 96 so we can count columns and rows
	ld 		c,96

	; Set e to 0 so we can accumulate the next byte of the new world
	ld 		e,0

	; Swap the registers
	exx

	; Load in the top, middle and bottom rows
	ld		b,(ix - 4)
	ld		d,(ix + 0)
	ld		h,(ix + 4)

	; Zero the accumulating registers
	ld		c,0
	ld		e,0
	ld		l,0





; This part of the program accumulates neighbors.
ACCUM:

	ACCUM_TOP:

		; Test the top row and jump to the middle row if the bit is unset
		sla		b
		jr		nc,ACCUM_MID

		; Acumulate neighbors
		inc		c
		inc		e
		inc		l

	ACCUM_MID:

		; Test the middle row and jump to the bottom row if the bit is unset
		sla		d
		jr		nc,ACCUM_BOT

		; Acumulate neighbors. Don't increment e: a cell is not its own neighbor
		inc		c
		inc		l

		; Increase e by 9 if it is alive
		ld		a,e
		add		a,9
		ld		e,a

	ACCUM_BOT:

		; Test the bottom row and jump to the end if the bit is unset
		sla		h
		jr		nc,ACCUM_FIN

		; Acumulate neighbors.
		inc		c
		inc		e
		inc		l

	ACCUM_FIN:

		; Push all of our accumulators onto the stack
		push   	hl
		push	de
		push 	bc

		; Now we jump to the update section (automatically since it is the next section in code )




; This part updates the next world in memory
UPDATE:

	; Swap to update registers
	exx

	; We always want to write the c accumulator to e
	pop		hl
	call	START+UPDATE_NEXT_GEN

	; If b is now 1, then we have finished the column.
	; If b is now 0, then we write e to memory (and set b to 8 implicitly).
	ld		a,b
	cp		1
	jr		z,UPDATE_NEW_COLUMN
	call	m,START+WRITE_NEXT_GEN

	; Swap to accum registers
    exx

	; Get whether b, d and h are now all 0
	ld		a,0
	or		b
	or		d
	or		h

	; Swap to update registers
    exx

    ; If a is non-zero, then there are still bytes to process, so update the same column
    jr		nz,UPDATE_SAME_COLUMN

	; We have entered a new column
	UPDATE_NEW_COLUMN:

		; We may also have a new row.
		; We can detect this if the decremented c is a multiple of 4.
		; Increase b if there is a new row.
		dec 	c
		ld		a,c
        and 	%11
		jr		nz,UPDATE_NEW_COLUMN_UPDATE_BEGIN
		inc 	b

		; Begin updating
		UPDATE_NEW_COLUMN_UPDATE_BEGIN:

		; Update e if b != 1
		pop		hl
		call	START+UPDATE_NEXT_GEN_IF_B_GT_1

		; Update l if b != 1.
		; Although we have not had the chance to add 9 to l if it's alive,
		; we know that l is dead since otherwise it would not be being written now.
		pop		hl
		call	START+UPDATE_NEXT_GEN_IF_B_GT_1

		; Fill the rest of e
		call	START+UPDATE_FILL_NEXT_GEN

		; Increment ix and iy
		inc		ix
		inc		iy

		; Get whether this is a new row
		ld		a,c
        and 	%11

        ; Swap to accum registers
        exx

        ; Update the top, middle and bottom bytes
		ld		b,(ix - 4)
		ld 		d,(ix + 0)
		ld 		h,(ix + 4)

        ; If there is no new row, jump to accumulation
        jp		nz,START+ACCUM

        ; We are now done with this byte, so write it.
        ; Set b back to 9, then resume accumulating.
        ; Switch to update registers to call the function.
        exx
        call	START+WRITE_NEXT_GEN
        inc		b

		; If this is the end of the last row,stop
        ld		a,c
        and		a
        ei
        STOP:
        jr		z,STOP
		di

    	; Otherwise switch to accum registers and jump to accumulation
        exx
        jp		nz,START+ACCUM

	; We are still working on the current column
	UPDATE_SAME_COLUMN:

		; Pop the e and l accumulators
		pop		hl
		pop		hl

		; Swap to accum registers and return to accumulating
        exx
        jp		START+ACCUM




; Same as the function below, but returns immediately if b = 1
UPDATE_NEXT_GEN_IF_B_GT_1:

	; Return if b = 1
	ld		a,b
	dec		a
	ret		z

; This part takes a number of neighbors, and updates e accordingly.
; The number of neighbors must be stored in l.
; The accumulators will be shifted along one step.
; The function will modify hl.
UPDATE_NEXT_GEN:

	; Push bc (we need more registers to work with)
	push	bc

	; Load l into bc
	ld		b,0
	ld		c,l

	; Get the position in memory of the rule (RULES plus bc)
	ld		hl,RULES
	add		hl,bc

	; Load the rule into the accumulator
	ld		a,(hl)

	; Pop back into bc
	pop		bc

	; Decrement b
	dec		b

	; Shift accumulator registers
	exx
	ld		c,e
	ld		e,l
	ld		l,0
	exx

	; Depending on the rule, split
	and		a
	jr		z,UPDATE_NEXT_GEN_DEAD

	; The cell is alive in the next generation
	UPDATE_NEXT_GEN_ALIVE:

	; Shift e left, filling in a one, then return
   	sll		e
   	ret

	; The cell is dead in the next generation
	UPDATE_NEXT_GEN_DEAD:

	; Shift e left, filling in a zero, then return
	sla		e
	ret



; This part assumes that all remaining cells in the column are dead and have no neighbors.
; While b != 1, e will be updated with the no neighbors rule.
; The function will modify hl.
UPDATE_FILL_NEXT_GEN:

	; Load the rule into the accumulator
	ld		hl,RULES
	ld		a,(hl)

	; Depending on the rule, split
	and		a
	jr		z,UPDATE_ALL_NEXT_GEN_DEAD

	; The cell is alive in the next generation
	UPDATE_ALL_NEXT_GEN_ALIVE:

	; Shift e left until b = 1, filling in a one each time.
	; Actually shift left until b = 0, then shift right at the end (with carry).
	sll		e
	djnz	UPDATE_ALL_NEXT_GEN_ALIVE
	rr		e
	ld		b,1
	ret

	; The cell is dead in the next generation
	UPDATE_ALL_NEXT_GEN_DEAD:

	; Shift e left until b = 1, filling in a zero each time.
	; Actually shift left until b = 0, then shift right at the end (with carry).
	sla		e
	djnz	UPDATE_ALL_NEXT_GEN_DEAD
	rr		e
	ld		b,1
	ret



; This part saves a byte back to the world, and also writes to the screen
; The byte is taken from e, and written to (iy-1)
; Has the byproduct of setting b to 8
WRITE_NEXT_GEN:

	; Push bc (we need more registers to work with)
    push	bc

	; Write e to memory
	ld		(iy - 1),e

	; Load 95 into a, and subtract c.
	; This gives us the offset from the start of screen attributes in memory divided by 8.
	; Therefore we need to multiply it by 8.
	; But first we must move it into hl.
	ld		a,95
	sub		c
	ld		h,0
	ld		l,a
	add		hl,hl
	add		hl,hl
	add		hl,hl
	ld		bc,SCREEN
	add		hl,bc

	; Iterate over the bits in e and set the attributes
	ld		b,8
	WRITE_NEXT_GEN_LOOP:
	sla		e
	jr		c,WRITE_NEXT_GEN_LOOP_ALIVE
	ld		(hl),%00010000
	jr		WRITE_NEXT_GEN_LOOP_END
	WRITE_NEXT_GEN_LOOP_ALIVE:
	ld		(hl),%00100000
	WRITE_NEXT_GEN_LOOP_END:
	inc 	hl
    djnz	WRITE_NEXT_GEN_LOOP

	; Pop bc back
	pop		bc

	; Set b to 8
    ld		b,8

	; Return
	ret










