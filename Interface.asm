;
; Interface.asm
;
; Contains interface functions.
; Also the main entry point.

; Include the macros
#include "Macros.asm"





; This is the entry code.
ENTRY_CODE:

	; Load the empty interrupt
	call	START+SETUP_EMPTY_INTERRUPT

	; Set ix to be WORLD1 and iy to be WORLD2
	ld		ix,WORLD1
	ld		iy,WORLD2

	; Set the edit rules cursor to 0
	ld		hl,EDIT_RULES_CURSOR
	ld		(hl),0

	; Set the edit world cursor to 0
	ld		hl,0
	ld		(EDIT_WORLD_CURSOR),hl

    ; Set the automatic timer to off
    ld		hl,AUTO_GEN_TIMER
    ld		(hl),0

	; Jump to editing rules (automatically)





; This part enters the edit rules menu.
EDIT_RULES:

	; Clear the screen
	ld		a,0
	call	START+FILL_PIXEL_DATA
	ld		a,%01111000
	call	START+FILL_ATTRIBUTE_DATA

	; Write the menu text
	ld		hl,START+EDIT_RULES_TEXT
	ld		de,0
	call	START+PRINT_STRING

; Initialize the read loop.
; hl stores the address in memory of the cursor position.
; bc stores the address in memory of the current rule being modified.
EDIT_RULES_INIT_LOOP:

	; Show all rules
	call	START+EDIT_RULES_SHOW_RULES

	; Set hl to the cursor location
    ld		hl,EDIT_RULES_CURSOR

	; Show the cursor
	ld		a,%10111000
	call	START+EDIT_RULES_SHOW_CURSOR

    ; Set bc to the address of the current rule
    ld		b,RULES_UPPER
    ld		c,(hl)

; Start the read loop
EDIT_RULES_READ_LOOP:

	; Look for an enter or L key
	EDIT_RULES_READ_LOOP_ENTER_OR_L:

		; Get the keypresses
		ld		a,%01000000
		ld		d,%00000011
		call	START+GET_KEYBOARD_INPUT

		; Test for enter
		EDIT_RULES_READ_LOOP_ENTER:
			bit		0,a
			jr		z,EDIT_RULES_READ_LOOP_L

			; Change the setting
			ld		a,(bc)
			cpl
			ld		(bc),a

			; Loop around
			jr		EDIT_RULES_INIT_LOOP

		; Test for L
        EDIT_RULES_READ_LOOP_L:
        	bit		1,a
        	jr		z,EDIT_RULES_READ_LOOP_P

        	; Remove the cursor
			ld		a,%01111000
			call	START+EDIT_RULES_SHOW_CURSOR

			; Increment the cursor. If it exceeded 18, set it to 0
			inc		(hl)
			ld		a,(hl)
			cp		18
			jr		nz,EDIT_RULES_INIT_LOOP
			ld		(hl),0
			jr		EDIT_RULES_INIT_LOOP

	; Look for P key
	EDIT_RULES_READ_LOOP_P:

		; Get the keypresses
		ld		a,%00100000
		ld		d,%00000001
		call	START+GET_KEYBOARD_INPUT

		; Look for a P
		and		a
		jr		z,EDIT_RULES_READ_LOOP_W_OR_E

		; Remove the cursor
		ld		a,%01111000
		call	START+EDIT_RULES_SHOW_CURSOR

		; Decrement the cursor. If it decreased below 0, set it to 17.
		dec		(hl)
		jp		p,START+EDIT_RULES_INIT_LOOP
		ld		(hl),17
		jr		EDIT_RULES_INIT_LOOP

	; Look for a W or E key
	EDIT_RULES_READ_LOOP_W_OR_E:

		; Get the keypresses
		ld		a,%00000100
		ld		d,%00000110
		call	START+GET_KEYBOARD_INPUT

		; Test for an E
		EDIT_RULES_READ_LOOP_E:
			bit		2,a
			jr		z,EDIT_RULES_READ_LOOP_W

			; Jump to world edit mode
			jr		EDIT_WORLD

		; Test for a W
		EDIT_RULES_READ_LOOP_W:
			bit		1,a
			jr		z,EDIT_RULES_READ_LOOP

			; Jump to the generation loop
			jp		START+GENERATION_LOOP






; Function to show the next generation settings
EDIT_RULES_SHOW_RULES:

	; Load the rules address into hl
	ld		hl,RULES

	; Set up the initial writing position.
	; The column is always 20, and the row varies starting as 3.
	ld		d,3
	ld		e,20

	; Loop over showing the rules
	ld		b,18
	EDIT_RULES_SHOW_RULES_LOOP:

		; Push cb, de and hl
		push 	bc
		push	de
		push	hl

		; Load the rule into a
        ld		a,(hl)

		; Assume the rule is dead, and change if proved otherwise.
		and		a
		ld		hl,START+EDIT_RULES_TEXT_DEAD
		jr		z,EDIT_RULES_SHOW_RULES_DEAD
		ld		hl,START+EDIT_RULES_TEXT_LIVE
		EDIT_RULES_SHOW_RULES_DEAD:

		; Print the rule
		call	START+PRINT_STRING

		; Pop bc, de and hl
		pop		hl
		pop		de
		pop		bc

		; Increment hl and d, then loop
		inc		hl
		inc 	d
		djnz	EDIT_RULES_SHOW_RULES_LOOP

	; Return
	ret





; This function draws the cursor in the edit rules menu.
; a should be set to the cursor attribute.
; Expects hl to be set to the address of the cursor.
; de is modified.
EDIT_RULES_SHOW_CURSOR:

	; Preserve a
	push	af

	; Get the current rule being modified, then the cursor position.
	ld		a,(hl)
	add		a,3
	ld		d,a
	ld		e,20

	; Color the cursor.
	pop		af
	ld		b,4
	call	START+PARTIAL_FILL_ATTRIBUTE_DATA

	; Return
	ret





; The edit world menu
EDIT_WORLD

	; Clear the pixel data
    ld		a,0
    call	START+FILL_PIXEL_DATA

	; Display the world
    call	START+DISPLAY_WORLD

; Initialize the read loop.
EDIT_WORLD_INIT_LOOP:

	; Toggle the cursor
	call	START+EDIT_WORLD_TOGGLE_CURSOR

; Start the read loop
EDIT_WORLD_READ_LOOP:

	; Load the cursor location into hl
    ld		hl,EDIT_WORLD_CURSOR

	; Look for an enter or L key
	EDIT_WORLD_READ_LOOP_ENTER_OR_L:

		; Get the keypresses
		ld		a,%01000000
		ld		d,%00000011
		call	START+GET_KEYBOARD_INPUT

		; Test for enter
		EDIT_WORLD_READ_LOOP_ENTER:
			bit		0,a
			jr		z,EDIT_WORLD_READ_LOOP_L

			; Toggle the world aliveness
			call	START+EDIT_WORLD_TOGGLE_WORLD

			; Loop
			jr		EDIT_WORLD_READ_LOOP

		; Test for L
		EDIT_WORLD_READ_LOOP_L:
			bit		1,a
			jr		z,EDIT_WORLD_READ_LOOP_P

			; Toggle the cursor
			call	START+EDIT_WORLD_TOGGLE_CURSOR

			; Move the cursor down. Remember to wrap and loop.
			inc		hl
			inc		(hl)
			ld		a,(hl)
			cp		24
			jp		m,START+EDIT_WORLD_INIT_LOOP
			ld		(hl),0
			jr		EDIT_WORLD_INIT_LOOP

	; Look for P key
	EDIT_WORLD_READ_LOOP_P:

		; Get the keypresses
		ld		a,%00100000
		ld		d,%00000001
		call	START+GET_KEYBOARD_INPUT

		; Look for a P
		and		a
		jr		z,EDIT_WORLD_READ_LOOP_Z_OR_X

		; Toggle the cursor
		call	START+EDIT_WORLD_TOGGLE_CURSOR

		; Move the cursor up. Remember to wrap and loop.
		inc		hl
		dec		(hl)
		jp		p,START+EDIT_WORLD_INIT_LOOP
		ld		(hl),23
		jr		EDIT_WORLD_INIT_LOOP

	; Look for a Z or X key
	EDIT_WORLD_READ_LOOP_Z_OR_X:

		; Get the keypresses
		ld		a,%00000001
		ld		d,%00000110
		call	START+GET_KEYBOARD_INPUT

		; Look for a Z
		EDIT_WORLD_READ_LOOP_Z
			bit		1,a
			jr		z,EDIT_WORLD_READ_LOOP_X

			; Toggle the cursor
            call	START+EDIT_WORLD_TOGGLE_CURSOR

			; Move the cursor left. Remember to wrap.
			ld		a,(hl)
			dec		a
			and		%00011111
			ld		(hl),a

			; Loop
			jr		EDIT_WORLD_INIT_LOOP

		; Look for an X
		EDIT_WORLD_READ_LOOP_X
			bit		2,a
			jr		z,EDIT_WORLD_READ_LOOP_W_OR_R

			; Toggle the cursor
			call	START+EDIT_WORLD_TOGGLE_CURSOR

			; Move the cursor right. Remember to wrap.
			ld		a,(hl)
			inc		a
			and		%00011111
			ld		(hl),a

			; Loop
			jr		EDIT_WORLD_INIT_LOOP

	; Look for a W or R key
	EDIT_WORLD_READ_LOOP_W_OR_R:

		; Get the keypresses
		ld		a,%00000100
		ld		d,%00001010
		call	START+GET_KEYBOARD_INPUT

		; Test for an R
		EDIT_WORLD_READ_LOOP_R:
			bit		3,a
			jr		z,EDIT_WORLD_READ_LOOP_W

			; Jump to world edit mode
			jp		START+EDIT_WORLD

		; Test for a W
		EDIT_WORLD_READ_LOOP_W:
			bit		1,a
			jr		z,EDIT_WORLD_READ_LOOP

			; Jump to the generation loop
			jr		GENERATION_LOOP






; A function to toggle the cursor at the current position.
; Modifies de.
EDIT_WORLD_TOGGLE_CURSOR:

	; Load the cursor and translate it to an attribute location
	ld		de,(EDIT_WORLD_CURSOR)
	call	START+GET_ATTRIBUTE_LOCATION

	; Load the attribute into the accumulator, set the cursor, then replace the attribute
	ld		a,(de)
	xor		%00000001
	or		%10000000
	ld		(de),a

	; Reload the cursor but this time translate it to a world position.

	; Return
	ret







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






; A function to toggle the world aliveness at the current cursor position.
; Also toggles the screen attribute
; Modifies de.
EDIT_WORLD_TOGGLE_WORLD:

	; Load the cursor and toggle the screen attribute.
	ld		de,(EDIT_WORLD_CURSOR)
    call	START+GET_ATTRIBUTE_LOCATION
    ld		a,(de)
    xor		%01111111
    ld		(de),a

    ; Load the cursor again, and toggle the aliveness in memory.
    ld		de,(EDIT_WORLD_CURSOR)
    call	START+GET_WORLD_BYTE_LOCATION
    xor		(hl)
    ld		(hl),a

    ; Return
    ret





; This part is the rendering loop.
; You can set a timer to automatically produce new generations at a particular frequency, or step through them manually.
GENERATION_LOOP:

	; Clear the pixel data
	ld		a,0
	call	START+FILL_PIXEL_DATA

; Initialize the key read loop.
; hl holds the address of the auto gen timer.
; bc holds the timer, which is reset on loop initialization.
; In particular, b is set to the timer value, and c to 0, so the timer length is effectively multiplied by 256.
GENERATION_LOOP_INIT_LOOP:

	; Display the world
	call	START+DISPLAY_WORLD

	; Load the timer
	ld		hl,AUTO_GEN_TIMER
	ld		b,(hl)
	ld		c,0

; Loop while reading the keyboard
GENERATION_LOOP_READ_LOOP:

	; Look for an enter key
	GENERATION_LOOP_READ_LOOP_ENTER:

		; Get the keypresses
		ld		a,%01000000
		ld		d,%00000001
		call	START+GET_KEYBOARD_INPUT

		; Test for the key
		and		a
		jr		z,GENERATION_LOOP_READ_LOOP_E_R_T

		; Generate the next world and loop
		call	START+NEXT_GENERATION
		jr		GENERATION_LOOP_INIT_LOOP

	; Look for an E or R or T key
	GENERATION_LOOP_READ_LOOP_E_R_T:

		; Get the keypresses
		ld		a,%00000100
		ld		d,%00011100
		call	START+GET_KEYBOARD_INPUT

		; Test for an E
		GENERATION_LOOP_READ_LOOP_E:
			bit		2,a
			jr		z,GENERATION_LOOP_READ_LOOP_R

			; Reset the timer and jump to editing the world
			ld		(hl),0
			jp		START+EDIT_WORLD

		; Test for an R
		GENERATION_LOOP_READ_LOOP_R:
			bit		3,a
			jr		z,GENERATION_LOOP_READ_LOOP_T

			; Reset the timer and jump to editing the rules
			ld		(hl),0
			jp		START+EDIT_RULES

		; Test for a T
		GENERATION_LOOP_READ_LOOP_T:
			bit		4,a
			jr		z,GENERATION_LOOP_READ_LOOP_B

			; Reset the timer and loop
			ld		(hl),0
			jr		GENERATION_LOOP_INIT_LOOP

	; Look for a B key
	GENERATION_LOOP_READ_LOOP_B:

		; Get the keypresses
		ld		a,%10000000
		ld		d,%00010000
		call	START+GET_KEYBOARD_INPUT

		; Test for a B
		bit		4,a
		jr		z,GENERATION_LOOP_READ_LOOP_NUMBERS

		; Found a B, so rollback to the previous generation.
		; Swap ix and iy and set the timer to 0.
		; Then go back to the start of the generation loop.
		push	ix
		push	iy
		pop		ix
		pop		iy
		ld		(hl),0
		jr		GENERATION_LOOP_INIT_LOOP

	; Look for numbers
	GENERATION_LOOP_READ_LOOP_NUMBERS:

		; Get the keypresses
		ld		a,%00001000
		ld		d,%00011111
		call	START+GET_KEYBOARD_INPUT

		; If no numbers are being pressed, jump
		and		a
		jr		z,GENERATION_LOOP_READ_LOOP_NO_KEYS

		; Else set the timer to the number being pressed and loop.
		ld		(hl),a
		jr		GENERATION_LOOP_INIT_LOOP

	; No keys found
	GENERATION_LOOP_READ_LOOP_NO_KEYS:

		; If the timer is already 0, the timer is off so loop around
		ld		a,b
		and		a
		jr		z,GENERATION_LOOP_READ_LOOP

		; Otherwise decrement the timer and automatically jump to generation if the timer is 0
		dec		bc
		ld		a,b
		and		a
		jp		nz,START+GENERATION_LOOP_READ_LOOP

		; Otherwise produce the next generation and return to getting keys
		call	START+NEXT_GENERATION
		jp		START+GENERATION_LOOP_INIT_LOOP





; This function reloads a world onto the screen.
; The world pointed to by ix is loaded.
DISPLAY_WORLD:

	; Wait for the frame to write
	halt

	; Set hl to the position of the first screen attribute
    ld		hl,ATTRIBUTE_DATA

	; Loop through all bytes to display the world.
	; Set b to count through the bytes.
	ld		b,96
	DISPLAY_WORLD_LOOP:

		; Load the next byte into e and complement it.
		ld		a,(ix+0)
		cpl
		ld		e,a

		; Iterate over the bits in e and set the attributes
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

; Include IO.asm
#include "IO.asm"





; Text for the edit rules menu
EDIT_RULES_TEXT:
	incbin	"GameOfLifeEditRulesText.txt"
	defb	0

EDIT_RULES_TEXT_BLACK:
	defb	"Black",0

EDIT_RULES_TEXT_WHITE:
	defb	"White",0

EDIT_RULES_TEXT_LIVE:
	defb	"Live",0

EDIT_RULES_TEXT_DEAD:
	defb	"Dead",0