;
; Interface.asm
;
; Contains interface functions.
; Also the main entry point.

; Include the macros
#include "Macros.asm"





; Load some rules
ld		hl,RULES+1
ld		(hl),255
ld		hl,RULES+10
ld		(hl),255

ld		hl,COLOR_FLIP
ld		(hl),255





; This part enters the edit rules menu.
EDIT_RULES:

	; Clear the screen
	ld		a,0
	call	START+FILL_PIXEL_DATA
	ld		a,%00111000
	call	START+FILL_ATTRIBUTE_DATA

	; Write the menu text
	ld		hl,START+EDIT_RULES_TEXT
	ld		de,0
	call	START+PRINT_STRING

	; Show all rules
	call	START+EDIT_RULES_SHOW_COLOUR_FLIP
	call	START+EDIT_RULES_SHOW_RULES

	di
	halt





; Function to show the colour flip setting
EDIT_RULES_SHOW_COLOUR_FLIP:

	; Get the colour flip setting.
	; Assume the colour is flipped, and change if proved otherwise.
	ld		a,(COLOR_FLIP)
	and		a
	ld		hl,START+EDIT_RULES_TEXT_BLACK
	jr		nz,EDIT_RULES_SHOW_COLOUR_FLIP_IS_FLIPPED
	ld		hl,START+EDIT_RULES_TEXT_WHITE
	EDIT_RULES_SHOW_COLOUR_FLIP_IS_FLIPPED:

	; Load the screen position and write.
	ld		de,$0112
	call	START+PRINT_STRING

	; Return
	ret





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





; Include the next generation code
#include "NextGeneration.asm"

; Include Printing.asm
#include "Printing.asm"





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