#!/usr/bin/python
import sys

if len(sys.argv) != 1
    sys.exit("Error I love muh dawg")
try:
    in_file = open(sys.argv[1], "r")
except:
    sys.exit("ERROR. Did you make a mistake in the spelling")
text = in_file.read()
print text
in_file.close()
