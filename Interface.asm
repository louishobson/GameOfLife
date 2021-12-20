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

	; Set color flipping to on
	ld		hl,COLOR_FLIP
    ld		(hl),255

    ; Set the automatic timer to off
    ld		hl,AUTO_GEN_TIMER
    ld		(hl),0

	; Load some rules
    ld		hl,RULES+1
    ld		(hl),255
    inc		hl
    ld		(hl),255
    ld		hl,RULES+10
    ld		(hl),255
    inc		hl
    ld		(hl),255

    ; Load some world values
    ld		(ix+0),%10000000
    ld		(ix+3),%00000001
    ld		(ix+92),%10000000
    ld		(ix+95),%00000001

	; Jump to the generation loop
	jp		START+GENERATION_LOOP







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

	; Show all rules
	call	START+EDIT_RULES_SHOW_RULES

	ld		b,4
	ld		de,$0413
	ld		a,%00111000
	call	START+PARTIAL_FILL_ATTRIBUTE_DATA

	; Halt... for now...
	di
	halt





; Function to show the next generation settings
EDIT_RULES_SHOW_RULES:

	; Load the rules address into hl and push it.
	ld		hl,RULES
	push	hl

	; Set up the initial writing position.
	; The column is always $13, and the row varies.
	; bc will point to memory storing the correct row.
	; Also push bc
	ld		bc,START+EDIT_RULES_ROW_POSITIONS+1
	push	bc
	ld		e,$13

	; Loop over showing the rules
	EDIT_RULES_SHOW_RULES_LOOP:

		; Pop back bc and hl
		pop		bc
		pop		hl

		; Load the next row to write to.
		; If it is 0, then we are done, otherwise increment bc and store the row number in d
		ld		a,(bc)
		and		a
		ret		z
		inc		bc
		ld		d,a

		; Load the rule into a then increment hl
		ld		a,(hl)
		inc		hl

		; Push hl and bc back to the stack
		push	hl
		push	bc

		; Assume the rule is dead, and change if proved otherwise.
		and		a
		ld		hl,START+EDIT_RULES_TEXT_DEAD
		jr		z,EDIT_RULES_SHOW_RULES_DEAD
		ld		hl,START+EDIT_RULES_TEXT_LIVE
		EDIT_RULES_SHOW_RULES_DEAD:

		; Print the rule then repeat the loop
		call	START+PRINT_STRING
		jr		EDIT_RULES_SHOW_RULES_LOOP





; This part is the rendering loop.
; You can set a timer to automatically produce new generations at a particular frequency, or step through them manually.
GENERATION_LOOP:

	; Display the world
	call	START+DISPLAY_WORLD

	; Initialize the key read loop
	GENERATION_LOOP_INIT_LOOP:

		; Load the timer
		ld		a,(AUTO_GEN_TIMER)
		ld		d,a
		ld		e,0

	; Loop while reading the keyboard
	GENERATION_LOOP_READ_LOOP:

		; Look for an enter key
		GENERATION_LOOP_READ_LOOP_ENTER:

			; Get the keypresses
			ld		a,%01000000
			ld		b,%00000001
			call	START+GET_KEYBOARD_INPUT

			; Jump to generation if the enter is being pressed
			and		a
			jp		nz,START+GENERATION_LOOP_NEXT_GEN

		; Look for an E or R or T key
		GENERATION_LOOP_READ_LOOP_E_R_T:

			; Get the keypresses
			ld		a,%00000100
			ld		b,%00011100
			call	START+GET_KEYBOARD_INPUT

			; Test for an E
			GENERATION_LOOP_READ_LOOP_E:
				bit		2,a
				jr		z,GENERATION_LOOP_READ_LOOP_R

				; Jump to world edit mode...

			; Test for an R
			GENERATION_LOOP_READ_LOOP_R:
				bit		3,a
				jr		z,GENERATION_LOOP_READ_LOOP_T

				; Jump to editing the rules
				jp		START+EDIT_RULES

			; Test for a T
			GENERATION_LOOP_READ_LOOP_T:
				bit		4,a
				jr		z,GENERATION_LOOP_READ_LOOP_B_N_M

				; Reset the timer and loop
				ld		hl,AUTO_GEN_TIMER
				ld		(hl),0
				jp		START+GENERATION_LOOP_INIT_LOOP

		; Look for a B, N or M key
		GENERATION_LOOP_READ_LOOP_B_N_M:

			; Get the keypresses
			ld		a,%10000000
			ld		b,%00011100
			call	START+GET_KEYBOARD_INPUT

			; Test for a B
			GENERATION_LOOP_READ_LOOP_B:
				bit		4,a
				jr		z,GENERATION_LOOP_READ_LOOP_N

				; Found a B, so rollback to the previous generation.
				; Swap ix and iy and set the timer to 0.
				; Then go back to the start of the generation loop.
				push	ix
				push	iy
				pop		ix
				pop		iy
				ld		hl,AUTO_GEN_TIMER
				ld		(hl),0
				jr		GENERATION_LOOP

			; Test for a N
			GENERATION_LOOP_READ_LOOP_N:
				bit		3,a
				jr		z,GENERATION_LOOP_READ_LOOP_M

				; Found an n, so clear the screen and jump to editing...

            ; Test for a M
			GENERATION_LOOP_READ_LOOP_M:
                bit		2,a
				jr		z,GENERATION_LOOP_READ_LOOP_NUMBERS

				; Swap colours
				ld		a,(COLOR_FLIP)
				cpl
				ld		(COLOR_FLIP),a

				; Re-render
				call	START+DISPLAY_WORLD

		; Look for numbers
		GENERATION_LOOP_READ_LOOP_NUMBERS:

			; Get the keypresses
			ld		a,%00001000
            ld		b,%00011111
            call	START+GET_KEYBOARD_INPUT

			; If no numbers are being pressed, jump
			and		a
			jr		z,GENERATION_LOOP_READ_LOOP_NO_KEYS

			; Else set the timer to the number being pressed and loop.
			ld		(AUTO_GEN_TIMER),a
			jp		START+GENERATION_LOOP_INIT_LOOP

		; No keys found
		GENERATION_LOOP_READ_LOOP_NO_KEYS:

			; If the timer is already 0, the timer is off so loop around
			ld		a,d
			and		a
			jp		z,START+GENERATION_LOOP_READ_LOOP

			; Otherwise decrement the timer and automatically jump to generation if the timer is 0
			dec		de
			ld		a,d
			and		a
			jp		nz,START+GENERATION_LOOP_READ_LOOP

	; Produce the next generation
	GENERATION_LOOP_NEXT_GEN:

		; Produce the next generation
		call	START+NEXT_GENERATION

		; Loop back to getting keys
		jp		START+GENERATION_LOOP





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

		; Load the next byte into e.
		; Possibly apply colour flipping.
		ld		e,(ix+0)
		ld		a,(COLOR_FLIP)
		xor		e
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

EDIT_RULES_ROW_POSITIONS:
	defb	0,4,5,6,7,8,9,10,11,12,15,16,17,18,19,20,21,22,23,0