#!/usr/local/bin/python2.7
import sys


class Cmd_arithmetic:

    def __init__(self, code):
        self.code = code
        self.counter = -1

    def generate(self):
        self.counter += 1
        return self.code.replace('%d', str(self.counter))


class Cmd_push:
    def __init__(self):
        self.segment = 'constant'
        self.index = '0'
        self.indirect = 'M'

    def generate(self):
        self.code = cmd_push_asm
        if self.segment == 'local':
            self.segment = 'LCL'
        if self.segment == 'argument':
            self.segment = 'ARG'
        if self.segment == 'this':
            self.segment = 'THIS'
        if self.segment == 'that':
            self.segment = 'THAT'
        if self.segment == 'temp':
            self.indirect = 'A'
            self.segment = '5'
        if self.segment == 'pointer':
            self.indirect = 'A'
            self.segment = '13'
        if self.segment == 'constant':
            self.code = cmd_push_asm_constant
        return self.code.replace('%s', self.segment).replace('%d', self.index).replace('%i', self.indirect)


class Cmd_pop:
    def __init__(self, code):
        self.code = code
        self.segment = 'constant'
        self.index = '0'
        self.indirect = 'M'

    def generate(self):
        if self.segment == 'local':
            self.segment = 'LCL'
        if self.segment == 'argument':
            self.segment = 'ARG'
        if self.segment == 'this':
            self.segment = 'THIS'
        if self.segment == 'that':
            self.segment = 'THAT'
        if self.segment == 'temp':
            self.indirect = 'A'
            self.segment = '5'
        if self.segment == 'pointer':
            self.indirect = 'A'
            self.segment = '13'
        return self.code.replace('%s', self.segment).replace('%d', self.index).replace('%i', self.indirect)


cmd_add = Cmd_arithmetic(
    """    @SP
    M=M-1
    A=M
    D=M     // D is value at top of the stack
    @SP
    A=M-1   // Point to next highest on stack
    M=M+D   // Add that guy to D
"""
)

cmd_sub = Cmd_arithmetic(
    """    @SP
    M=M-1
    A=M
    D=M     // D is value at top of the stack
    @SP
    A=M-1   // Point to next highest on stack
    M=M-D   // Sub D from that guy
"""
)

cmd_neg = Cmd_arithmetic(
    """    @SP
    M=M-1
    A=M
    D=-M    // D is value at top of the stack
    M=D
    @SP
    M=M+1
"""
)

cmd_eq = Cmd_arithmetic(
    """    @SP
    M=M-1
    A=M
    D=M        // D is value at top of the stack
    @SP
    A=M-1      // Point to next highest on stack
    D=M-D      // Sub D from that guy
    @EQ_TRUE_%d
    D;JEQ
(EQ_FALSE_%d)   // NOT eq, set D to false (0)
    @0
    D=A
    @EQ_DONE_%d
    0;JMP
(EQ_TRUE_%d)    // eq, set D to true (-1)
    D=D-1      // D is 0, set D to true (-1)
(EQ_DONE_%d)
    @SP
    M=M-1
    A=M
    M=D
    @SP
    M=M+1
"""
)

cmd_lt = Cmd_arithmetic(
    """    @SP
    M=M-1
    A=M
    D=M        // D is value at top of the stack
    @SP
    A=M-1      // Point to next highest on stack
    D=M-D      // Sub D from that guy
    @LT_TRUE_%d
    D;JLT
(LT_FALSE_%d)   // NOT lt, set D to false (0)
    @0
    D=A
    @LT_DONE_%d
    0;JMP
(LT_TRUE_%d)    // lt, set D to true (-1)
    @0
    D=A-1      // set D to true (-1)
(LT_DONE_%d)
    @SP
    M=M-1
    A=M
    M=D
    @SP
    M=M+1
"""
)

cmd_gt = Cmd_arithmetic(
    """    @SP
    M=M-1
    A=M
    D=M        // D is value at top of the stack
    @SP
    A=M-1      // Point to next highest on stack
    D=M-D      // Sub D from that guy
    @GT_TRUE_%d
    D;JGT
(GT_FALSE_%d)   // NOT gt, set D to false (0)
    @0
    D=A
    @GT_DONE_%d
    0;JMP
(GT_TRUE_%d)    // gt, set D to true (-1)
    @0
    D=A-1      // set D to true (-1)
(GT_DONE_%d)
    @SP
    M=M-1
    A=M
    M=D
    @SP
    M=M+1
"""
)

cmd_and = Cmd_arithmetic(
    """    @SP
    M=M-1
    A=M
    D=M     // D is value at top of the stack
    @SP
    A=M-1   // Point to next highest on stack
    M=D&M   // Add D to that guy
"""
)

cmd_or = Cmd_arithmetic(
    """    @SP
    M=M-1
    A=M
    D=M     // D is value at top of the stack
    @SP
    A=M-1   // Point to next highest on stack
    M=D|M   // Add D to that guy
"""
)

cmd_not = Cmd_arithmetic(
    """    @SP
    M=M-1
    A=M
    D=!M    // D is value at top of the stack
    M=D
    @SP
    M=M+1
"""
)

cmd_push_asm = """    @%s     // segment
    D=%i
    @%d     // index
    A=D+A   // D holds the address to pull from
    D=M     // D holds the value we're gonna push onto SP
    @SP
    A=M
    M=D
    @SP     // increment SP
    M=M+1
"""

cmd_push_asm_constant = """    @%d
    D=A
    @SP
    A=M
    M=D
    @SP     // increment SP
    M=M+1
"""

cmd_pop = Cmd_pop(
    """    @%s     // segment
    D=%i
    @%d     // index
    D=D+A   // D holds the address to which to pop
    @SP
    A=M
    M=D     // top of the stack has the address to which to pop
    @SP
    A=M-1
    D=M     // D holds the value we're going to pop
    @SP
    A=M
    A=M     // climbing the indirections
    M=D     // Done!
    @SP     // decrement SP
    M=M-1
"""
)


def parse(line):
    # strip comments
    no_comments = line.split('#', 1)[0]
    no_comments = no_comments.split('//', 1)[0]
    tokens = no_comments.split()
    return tokens


def writecode(tokens):
    if not tokens:
        return
    asm_file.write('//')
    for token in tokens:
        asm_file.write(' ' + str(token))
    asm_file.write('\n')
    if tokens[0] == 'add':
        asm_file.write(cmd_add.generate())
    if tokens[0] == 'sub':
        asm_file.write(cmd_sub.generate())
    if tokens[0] == 'neg':
        asm_file.write(cmd_neg.generate())
    if tokens[0] == 'eq':
        asm_file.write(cmd_eq.generate())
    if tokens[0] == 'lt':
        asm_file.write(cmd_lt.generate())
    if tokens[0] == 'gt':
        asm_file.write(cmd_gt.generate())
    if tokens[0] == 'and':
        asm_file.write(cmd_and.generate())
    if tokens[0] == 'or':
        asm_file.write(cmd_or.generate())
    if tokens[0] == 'not':
        asm_file.write(cmd_not.generate())
    if tokens[0] == 'push':
        cmd_push = Cmd_push()
        cmd_push.segment = tokens[1]
        cmd_push.index = tokens[2]
        asm_file.write(cmd_push.generate())
    if tokens[0] == 'pop':
        cmd_pop.segment = tokens[1]
        cmd_pop.index = tokens[2]
        asm_file.write(cmd_pop.generate())


def banner():
    asm_file.write("//\n// Brian Cunnie's output for Nand to Tetris\n//\n")


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

banner()
for line in intermediate_code:
    x = parse(line)
    writecode(x)