#!/usr/local/bin/python2.7
import sys


def parse(line):
    return(line)

def writecode(parsed_data):
    print parsed_data

cmd_name = sys.argv[0].split('/')[-1]

if len(sys.argv) != 2:
    sys.exit(cmd_name + " error: pass me one arg, the name of the file to compile")

intermediate_filename = sys.argv[1]

try:
    intermediate_code = open(intermediate_filename, "r")
except:
    sys.exit(cmd_name + " error. I couldn't open " + intermediate_filename + " for reading!")

asm_filename = intermediate_filename.replace('.vm', '.asm')

if intermediate_filename == asm_filename:
    asm_filename += ".asm"

try:
    asm_code = open(asm_filename, "w")
except:
    sys.exit(cmd_name + " error. I couldn't open " + asm_filename + " for writing!")

for line in intermediate_code:
    x = parse(line)
    writecode(x)
