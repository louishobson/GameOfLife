; Include once
#ifndef MACROS_INCLUDE_ONCE
#define MACROS_INCLUDE_ONCE

; The load position of the program
#define START 60000

; The position of the custom interrupt
#define CUSTOM_INTERRUPT $e9e9
#define CUSTOM_INTERRUPT_BYTE $e9

; The position of the interrupt vector table
#define INTERRUPT_VTABLE $e800
#define INTERRUPT_VTABLE_UPPER $e8

; The position of the worlds.
; Each world consists of 24 rows of 4 bytes, making 96 bytes in total.
; There also needs to be padding of 4 zero bytes before and after each.
; Note that both addresses have their lower byte as 0.
#define WORLD1 62208
#define WORLD2 62464

; The position of the rule set.
; Rather than packing the rule set, we just store 18 booleans as bytes.
; We write true as 255 and false as 0.
; True means alive in the next generation, false means dead.
; The first 9 bytes define the rules for a living cell with 0 through 8 neighbors.
; The second 9 bytes define the same for a dead cell.
; Note that the lower byte of the address is 0.
#define RULES 62720
#define RULES_UPPER $f5

; The current timer for automatic generation switching.
; The fastest is 1, and off is 256 (equals 0).
#define AUTO_GEN_TIMER 62738

; The current position of the cursor in the edit rules menu.
#define	EDIT_RULES_CURSOR 62739

; Define the position of the character bitmaps in memory.
#define CHAR_BITMAPS $3c00
#define CHAR_BITMAPS_UPPER $3c

; Define the position of the pixel data in memory, and the length of the data.
#define PIXEL_DATA $4000
#define PIXEL_DATA_LENGTH $1800
#define PIXEL_DATA_LENGTH_UPPER $18

; Define the position of the attribute data in memory, and length of the data
#define ATTRIBUTE_DATA $5800
#define ATTRIBUTE_DATA_UPPER $58
#define ATTRIBUTE_DATA_LENGTH $0300
#define ATTRIBUTE_DATA_LENGTH_UPPER $03

; The keyboard's id
#define KEYBOARD_IN_ID $fe

; End of pragma once
#endif