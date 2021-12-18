# TextConc.py
#
# This tool takes a binary file as its first argument, the block name as its second, and the output tzx as its last.
# The string is finalized with a null character.

# Import sys
import sys

# Import the converter
sys.path.append ( "/home/louis/Downloads/zxbasic/zxbasic" )
from src.outfmt import TZX

# Open the file
f = open ( sys.argv [ 1 ], "rb" )

# Create empty bytearray
xs = bytearray ()

# Convert the file to binary
while byte := f.read ( 1 ):
	xs.append ( int.from_bytes ( byte, 'big' ) )

# Close f
f.close ()

# Add a null byte
xs.append ( 0x00 )

# Create the tzx
t = TZX ()
t.save_code ( sys.argv [ 2 ], 0, xs )
t.dump ( sys.argv [ 3 ] )