# TextConc.py
# This tool takes the name of an ascii-encoded text file as its first argument, the block name as its second, and the output tzx as its last.
# The string is finalized with a null character.

# Import sys
import sys

# Import the converter
sys.path.append ( "/home/louis/Downloads/zxbasic/zxbasic" )
from src.outfmt import TZX

# Create the dictionary of characters to codes
CharDict = {
	'A' : 0x41,
	'B' : 0x42,
	'C' : 0x43,
	'D' : 0x44,
	'E' : 0x45,
	'F' : 0x46,
	'G' : 0x47,
	'H' : 0x48,
	'I' : 0x49,
	'J' : 0x4a,
	'K' : 0x4b,
	'L' : 0x4c,
	'M' : 0x4d,
	'N' : 0x4e,
	'O' : 0x4f,
	'P' : 0x50,
	'Q' : 0x51,
	'R' : 0x52,
	'S' : 0x53,
	'T' : 0x54,
	'U' : 0x55,
	'V' : 0x56,
	'W' : 0x57,
	'X' : 0x58,
	'Y' : 0x59,
	'Z' : 0x5a,

	'a' : 0x61,
	'b' : 0x62,
	'c' : 0x63,
	'd' : 0x64,
	'e' : 0x65,
	'f' : 0x66,
	'g' : 0x67,
	'h' : 0x68,
	'i' : 0x69,
	'j' : 0x6a,
	'k' : 0x6b,
	'l' : 0x6c,
	'm' : 0x6d,
	'n' : 0x6e,
	'o' : 0x6f,
	'p' : 0x70,
	'q' : 0x71,
	'r' : 0x72,
	's' : 0x73,
	't' : 0x74,
	'u' : 0x75,
	'v' : 0x76,
	'w' : 0x77,
	'x' : 0x78,
	'y' : 0x79,
	'z' : 0x7a,

	'0' : 0x30,
	'1' : 0x31,
	'2' : 0x32,
	'3' : 0x33,
	'4' : 0x34,
	'5' : 0x35,
	'6' : 0x36,
	'7' : 0x37,
	'8' : 0x38,
	'9' : 0x39,

	'\n' : 0x0d,
	' '  : 0x20,
	':'  : 0x3a
}

# Open the file
f = open ( sys.argv [ 1 ], "r" )

# Create empty bytearray
xs = bytearray ()

# Convert the file to binary
while byte := f.read ( 1 ):
	xs.append ( CharDict [ byte ] )

# Close f
f.close ()

# Add a null byte
xs.append ( 0x00 )

# Create the tzx
t = TZX ()
t.save_code ( sys.argv [ 2 ], 0, xs )
t.dump ( sys.argv [ 3 ] )