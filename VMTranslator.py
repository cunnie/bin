#!/usr/local/bin/python2.7
import sys


class Cmd_arithmetic:
    def __init__(self, code):
        self.code = code

    def generate(self):
        return self.code


class Cmd_push:
    def __init__(self, code):
        self.code = code
        self.segment = 'constant'
        self.index = 0

    def generate(self):
        code = self.code
        if self.segment == 'constant':
            code = '@' + str(self.index) + '\n' + self.code
        return code


cmd_add = Cmd_arithmetic(
    """@SP
M=M-1
A=M
D=M	// D is value at top of the stack
@SP
A=M-1	// Point to next highest on stack
M=D+M  // Add D to that guy
"""
)

cmd_push = Cmd_push(
    """D=A
@SP
A=M
M=D
@SP
M=M+1
"""
)


def parse(line):
    # strip comments
    no_comments = line.split('#', 1)[0]
    no_comments = no_comments.split('//', 1)[0]
    tokens = no_comments.split()
    return (tokens)


def writecode(tokens):
    if not tokens:
        return
    asm_file.write('//')
    for token in tokens:
        asm_file.write(' ' + str(token))
    asm_file.write('\n')
    if tokens[0] == 'add':
        asm_file.write(cmd_add.generate())
    if tokens[0] == 'push':
        cmd_push.segment = tokens[1]
        cmd_push.index = tokens[2]
        asm_file.write(cmd_push.generate())


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
    asm_file = open(asm_filename, "w")
except:
    sys.exit(cmd_name + " error. I couldn't open " + asm_filename + " for writing!")

for line in intermediate_code:
    x = parse(line)
    writecode(x)
