#!/usr/local/bin/python2.7
import sys
import datetime


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

    def generate(self):
        self.code = cmd_push_asm
        self.indirect = 'M'
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
            self.segment = '3'
        if self.segment == 'static':
            self.segment = '15'
        if self.segment == 'constant':
            self.code = cmd_push_asm_constant
        return self.code.replace('%s', self.segment).replace('%d', self.index).replace('%i', self.indirect)


class Cmd_pop:
    def __init__(self, code):
        self.code = code
        self.segment = 'constant'
        self.index = '0'

    def generate(self):
        self.indirect = 'M'
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
            self.segment = '3'
        if self.segment == 'static':
            self.segment = '15'
        return self.code.replace('%s', self.segment).replace('%d', self.index).replace('%i', self.indirect)


class Cmd_goto:
    def __init__(self, code):
        self.code = code
        self.label = "BRIAN_YOUR_CODE_HAS_A_MISTAKE"

    def generate(self):
        return self.code.replace('%s', self.label)


class Cmd_function:
    def __init__(self, code):
        self.code = code
        self.name = "BRIAN_YOUR_CODE_HAS_A_MISTAKE"
        self.args = []

    def generate(self):
        return self.code


class Cmd_return:
    def __init__(self, code):
        self.code = code

    def generate(self):
        return self.code


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

cmd_goto = Cmd_goto(
    """    @%s
    0;JMP
"""
)

cmd_if_goto = Cmd_goto(
    """    @SP
    @SP
    M=M-1
    A=M
    D=M     // D holds the value we've popped
    @%s
    D;JNE
"""
)

cmd_function = Cmd_function(
    """    @SP
"""
)

cmd_return = Cmd_return(
    """    @SP
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
    elif tokens[0] == 'sub':
        asm_file.write(cmd_sub.generate())
    elif tokens[0] == 'neg':
        asm_file.write(cmd_neg.generate())
    elif tokens[0] == 'eq':
        asm_file.write(cmd_eq.generate())
    elif tokens[0] == 'lt':
        asm_file.write(cmd_lt.generate())
    elif tokens[0] == 'gt':
        asm_file.write(cmd_gt.generate())
    elif tokens[0] == 'and':
        asm_file.write(cmd_and.generate())
    elif tokens[0] == 'or':
        asm_file.write(cmd_or.generate())
    elif tokens[0] == 'not':
        asm_file.write(cmd_not.generate())
    elif tokens[0] == 'push':
        cmd_push = Cmd_push()
        cmd_push.segment = tokens[1]
        cmd_push.index = tokens[2]
        asm_file.write(cmd_push.generate())
    elif tokens[0] == 'pop':
        cmd_pop.segment = tokens[1]
        cmd_pop.index = tokens[2]
        asm_file.write(cmd_pop.generate())
    elif tokens[0] == 'label':
        asm_file.write("(" + tokens[1] + ")\n")
    elif tokens[0] == 'goto':
        cmd_goto.label = tokens[1]
        asm_file.write(cmd_goto.generate())
    elif tokens[0] == 'if-goto':
        cmd_if_goto.label = tokens[1]
        asm_file.write(cmd_if_goto.generate())
    elif tokens[0] == 'function':
        cmd_function.name = tokens[1]
        cmd_function.args = tokens[2:]
        asm_file.write(cmd_function.generate())
    elif tokens[0] == 'return':
        asm_file.write(cmd_return.generate())
    else:
        sys.exit(cmd_name + " I can't recognize these tokens: " + '[%s]' % ', '.join(map(str, tokens)))


def banner():
    asm_file.write("// Brian Cunnie's output for Nand to Tetris\n")
    asm_file.write(datetime.datetime.now().strftime("// Compiled: %Y-%m-%d %H:%M\n\n"))


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
