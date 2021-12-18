;
; Printing.asm
;
; Various functions for printing characters to the screen

; Define the position of the character bitmaps in memory.
#define CHAR_BITMAPS $3c00

; Define the position of the pixel data in memory, and the length of the data.
#define PIXEL_DATA $4000
#define PIXEL_DATA_LENGTH $1800
#define PIXEL_DATA_LENGTH_UPPER $18

; Define the position of the attribute data in memory, and length of the data
#define ATTRIBUTE_DATA $5800
#define ATTRIBUTE_DATA_LENGTH $0300
#define ATTRIBUTE_DATA_LENGTH_UPPER $03





; This function takes a character code to print stored in a.
; It sets hl to the address in memory of the position of the bitmap for that character.
; Modifies bc.
GET_BITMAP_LOCATION:

	; Load a into hl
	ld		h,0
	ld		l,a

	; Multiply hl by 8
	add		hl,hl
	add		hl,hl
	add		hl,hl

	; Add the offset to the character bitmaps to hl
	ld		bc,CHAR_BITMAPS
	add		hl,bc

	; Return
	ret





; This function calculates the beginning position of a character in screen pixel memory.
; d should be set to the y coordinate [0;23]
; e should be set to the x coordinate [0;31]
; See http://www.breakintoprogram.co.uk/computers/zx-spectrum/screen-memory-layout for the memory layout.
; We actually want 0 1 0 0 0 Y4 Y3 0 0 0   Y2 Y1 Y0 X4 ... X0
GET_PIXEL_LOCATION:

	; Get Y3,4,5 in position.
	ld		a,d
	and		%00000111
	rrca
	rrca
	rrca

	; Get all of X in position (only the bottom 5 bytes should be set anyway)
	or		e

	; Store our bottom byte in e
	ld		e,a

	; Load Y into a, and mask the required bits
	ld		a,d
	and 	%00011000

	; Set the front bit
	or		%01000000

	; Load into d and return
	ld		d,a
	RET





; This function calculates the position of a character in screen attribute memory.
; d should be set to the y coordinate [0;23]
; e should be set to the x coordinate [0;31]
; We need (y * 32) + x, that is
; 0 0 0 0 0 0 Y4 Y3  Y2 Y1 Y0 X4 ... X0
GET_ATTRIBUTE_LOCATION:

	; We can get Y4...Y0 in position by shifting.
	ld		a,d
	rrca
	rrca
	rrca

	; Load into d for later, then get only Y2...Y0
	ld		d,a
	and		%11100000

	; Add in X4...X0 and we are done for the lower byte
	or		e
	ld		e,a

	; Now finish off the top byte.
	; Also add in the offset to the start of attributes.
	ld		a,d
	and		%00000011
	or		%01011000
	ld		d,a

	; Return
	ret





; This function prints a string.
; The location in memory of the start of the string is hl.
; The coordinates on the screen is de (see GET_PIXEL_LOCATION).
PRINT_STRING:

	; Push de and call GET_PIXEL_LOCATION
	push	de
	call	START+GET_PIXEL_LOCATION

	; Loop over characters
	PRINT_STRING_CHAR_LOOP:

		; Get the character in a
		ld		a,(hl)

		; Return if the character is 0
		and		a
		jr 		nz,PRINT_STRING_NOT_NULL
		pop		de
		ret
		PRINT_STRING_NOT_NULL:

		; If there is a newline, jump back to the top
		cp		10
		jr		nz,PRINT_STRING_NOT_CR
		inc		hl
		pop		de
		inc		d
		ld		e,0
		jr		PRINT_STRING
		PRINT_STRING_NOT_CR:

		; Push hl and get the bitmap location
		push	hl
		call	START+GET_BITMAP_LOCATION

		; Loop over writing the character
		ld		b,8
		PRINT_STRING_WRITE_LOOP:

			; Copy over the byte
			ld		a,(hl)
			ld		(de),a

			; Get the next byte of the bitmap
			inc		hl

			; Get the location of the next pixel byte
			inc		d

			; Loop
			djnz	PRINT_STRING_WRITE_LOOP

		; Pop hl back and increment it
		pop		hl
		inc		hl

		; Increment the pixel location
		ld		a,d
		sub		8
		ld		d,a
		inc		e

		; Loop
		jr		PRINT_STRING_CHAR_LOOP






; This function fills the screen pixel data with the contents of a.
; hl and bc are modified.
FILL_PIXEL_DATA:

	; Set hl to PIXEL_DATA
	ld		hl,PIXEL_DATA

	; Clear the screen. Since there are $1800 bytes to write, we write 256 bytes $18 times.
	ld		c,PIXEL_DATA_LENGTH_UPPER
	FILL_PIXEL_DATA_OUTER_LOOP:
		ld		b,256
		FILL_PIXEL_DATA_INNER_LOOP:
			ld		(hl),a
			inc		hl
		djnz	FILL_PIXEL_DATA_INNER_LOOP
	dec		c
	jr		nz,FILL_PIXEL_DATA_OUTER_LOOP

	; Return
	ret





; This function fills the screen attribute data with the contents of a.
; hl and bc are modified.
FILL_ATTRIBUTE_DATA:

	; Set hl to ATTRIBUTE_DATA
	ld		hl,ATTRIBUTE_DATA

	; Clear the screen. Since there are $0300 bytes to write, we write 256 bytes 3 times.
	ld		c,ATTRIBUTE_DATA_LENGTH_UPPER
	FILL_ATTRIBUTE_DATA_OUTER_LOOP:
		ld		b,256
		FILL_ATTRIBUTE_DATA_INNER_LOOP:
			ld		(hl),a
			inc		hl
		djnz	FILL_ATTRIBUTE_DATA_INNER_LOOP
	dec		c
	jr		nz,FILL_ATTRIBUTE_DATA_OUTER_LOOP

	; Return
	ret