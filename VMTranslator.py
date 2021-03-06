#!/usr/local/bin/python2.7
import fileinput
import glob
import os
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

    def __init__(self, segment='constant', index='0'):
        self.code = self.cmd_push_asm
        self.segment = segment
        self.index = index
        self.indirect = 'M'
        if self.segment == 'local':
            self.segment = 'LCL'
        elif self.segment == 'argument':
            self.segment = 'ARG'
        elif self.segment == 'this':
            self.segment = 'THIS'
        elif self.segment == 'that':
            self.segment = 'THAT'
        elif self.segment == 'temp':
            self.indirect = 'A'
            self.segment = '5'
        elif self.segment == 'pointer':
            self.indirect = 'A'
            self.segment = '3'
        elif self.segment == 'static':
            self.segment = '15'
        elif self.segment == 'constant':
            self.code = self.cmd_push_asm_constant

    def generate(self):
        return self.code.replace('%s', self.segment).replace('%d', self.index).replace('%i', self.indirect)


class Cmd_pop:
    code = """    @{segment}     // segment
    D={a_or_m}
    @{index}     // index
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

    def __init__(self, segment='constant', index='0'):
        a_or_m = 'M'
        if segment == 'local':
            segment = 'LCL'
        elif segment == 'argument':
            segment = 'ARG'
        elif segment == 'this':
            segment = 'THIS'
        elif segment == 'that':
            segment = 'THAT'
        elif segment == 'temp':
            a_or_m = 'A'
            segment = '5'
        elif segment == 'pointer':
            a_or_m = 'A'
            segment = '3'
        elif segment == 'static':
            segment = '15'
        self.named_placeholders = {
            'segment': segment,
            'index': index,
            'a_or_m': a_or_m,
        }

    def generate(self):
        return Cmd_pop.code.format(**self.named_placeholders)


class Cmd_goto:
    def __init__(self, code, label="BRIAN_YOUR_CODE_HAS_A_MISTAKE"):
        self.code = code
        self.label = label

    def generate(self):
        return self.code.replace('%s', self.label)


class Cmd_function:
    # (f) // Declare a label for the function entry
    #     // repeat k times: k == number of local variables
    # PUSH 0
    push_0 = """    @SP
    D=A     // D is 0, we take advantage of the fact that @SP == 0
    A=M
    AM=D    // *SP = 0
    M=M+1   // SP++
"""

    def __init__(self, name="BRIAN_YOUR_CODE_HAS_A_MISTAKE", num_args=0):
        self.name = name
        self.args = num_args

    def generate(self):
        code = "(%s)\n".replace('%s', self.name)
        for arg in range(0, int(self.args)):
            code += self.push_0
        return code


class Cmd_return:
    # R13-R15 "These predefined symbols can be used for any purpose."
    code = """    // FRAME = LCL
    @LCL
    D=M
    @R13
    M=D     // FRAME (LCL) is in register 13
    // RET = *(FRAME-5)
    @5
    A=D-A
    D=M     // D is RET
    @R14
    M=D     // RET is in register 14
    // *ARG = pop()
    @SP
    M=M-1   // SP--
    A=M
    D=M
    @ARG
    A=M
    M=D
    // SP = ARG+1
    @ARG
    D=M+1
    @SP
    M=D
    // THAT = *(FRAME-1)
    @R13
    AM=M-1  // FRAME--
    D=M
    @THAT
    M=D
    // THIS = *(FRAME-2)
    @R13
    AM=M-1  // FRAME--
    D=M
    @THIS
    M=D
    // ARG = *(FRAME-3)
    @R13
    AM=M-1  // FRAME--
    D=M
    @ARG
    M=D
    // LCL = *(FRAME-4)
    @R13
    AM=M-1  // FRAME--
    D=M
    @LCL
    M=D
    // goto RET
    @R14
    A=M
    0;JMP
"""

    def __init__(self):
        return

    def generate(self):
        return Cmd_return.code


class Cmd_call:
    nonce = 0

    code = """    @{function_name}.{nonce}    // push return-address
    D=A
    @SP
    A=M
    M=D      // *(SP) = D
    @SP
    M=M+1    // SP++
    @LCL    // push LCL
    {push_on_stack}
    @ARG    // push ARG
    {push_on_stack}
    @THIS   // push THIS
    {push_on_stack}
    @THAT   // push THAT
    {push_on_stack}
    @SP     // ARG = SP-n-5
    D=M
    @{num_args}
    D=D-A
    @5
    D=D-A
    @ARG
    M=D
    @SP     // LCL = SP
    D=M
    @LCL
    M=D
    @{function_name}
    0;JMP
({function_name}.{nonce})
"""

    push_on_stack = """D=M
    @SP
    A=M
    M=D      // *(SP) = D
    @SP
    M=M+1    // SP++"""

    def __init__(self, function_name="BRIAN_YOUR_CODE_HAS_A_MISTAKE", num_args=0):
        self.function_name = function_name
        self.num_args = num_args
        self.named_placeholders = {
            'push_on_stack': Cmd_call.push_on_stack,
            'function_name': self.function_name,
            'num_args': self.num_args,
            'nonce': Cmd_call.nonce,
        }
        Cmd_call.nonce += 1

    def generate(self):
        return Cmd_call.code.format(**self.named_placeholders)


cmd_add = """    @SP
    M=M-1
    A=M
    D=M     // D is value at top of the stack
    @SP
    A=M-1   // Point to next highest on stack
    M=M+D   // Add that guy to D
"""

cmd_sub = """    @SP
    M=M-1
    A=M
    D=M     // D is value at top of the stack
    @SP
    A=M-1   // Point to next highest on stack
    M=M-D   // Sub D from that guy
"""

cmd_neg = """    @SP
    M=M-1
    A=M
    D=-M    // D is value at top of the stack
    M=D
    @SP
    M=M+1
"""

cmd_eq = """    @SP
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

cmd_lt = """    @SP
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

cmd_gt = """    @SP
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

cmd_and = """    @SP
    M=M-1
    A=M
    D=M     // D is value at top of the stack
    @SP
    A=M-1   // Point to next highest on stack
    M=D&M   // Add D to that guy
"""

cmd_or = """    @SP
    M=M-1
    A=M
    D=M     // D is value at top of the stack
    @SP
    A=M-1   // Point to next highest on stack
    M=D|M   // Add D to that guy
"""

cmd_not = """    @SP
    M=M-1
    A=M
    D=!M    // D is value at top of the stack
    M=D
    @SP
    M=M+1
"""

cmd_goto = """    @%s
    0;JMP
"""

cmd_if_goto = """    @SP
    @SP
    M=M-1
    A=M
    D=M     // D holds the value we've popped
    @%s
    D;JNE
"""


def parse(line):
    # strip comments
    no_comments = line.split('#', 1)[0]
    no_comments = no_comments.split('//', 1)[0]
    tokens = no_comments.split()
    return tokens


def writecode(asm_file, tokens):
    if not tokens:
        return
    asm_file.write('//')
    for token in tokens:
        asm_file.write(' ' + str(token))
    asm_file.write('\n')
    if tokens[0] == 'add':
        asm_file.write(Cmd_arithmetic(cmd_add).generate())
    elif tokens[0] == 'sub':
        asm_file.write(Cmd_arithmetic(cmd_sub).generate())
    elif tokens[0] == 'neg':
        asm_file.write(Cmd_arithmetic(cmd_neg).generate())
    elif tokens[0] == 'eq':
        asm_file.write(Cmd_arithmetic(cmd_eq).generate())
    elif tokens[0] == 'lt':
        asm_file.write(Cmd_arithmetic(cmd_lt).generate())
    elif tokens[0] == 'gt':
        asm_file.write(Cmd_arithmetic(cmd_gt).generate())
    elif tokens[0] == 'and':
        asm_file.write(Cmd_arithmetic(cmd_and).generate())
    elif tokens[0] == 'or':
        asm_file.write(Cmd_arithmetic(cmd_or).generate())
    elif tokens[0] == 'not':
        asm_file.write(Cmd_arithmetic(cmd_not).generate())
    elif tokens[0] == 'push':
        asm_file.write(Cmd_push(segment=tokens[1], index=tokens[2]).generate())
    elif tokens[0] == 'pop':
        asm_file.write(Cmd_pop(segment=tokens[1], index=tokens[2]).generate())
    elif tokens[0] == 'label':
        asm_file.write("(" + tokens[1] + ")\n")
    elif tokens[0] == 'goto':
        asm_file.write(Cmd_goto(cmd_goto, label=tokens[1]).generate())
    elif tokens[0] == 'if-goto':
        asm_file.write(Cmd_goto(cmd_if_goto, label=tokens[1]).generate())
    elif tokens[0] == 'function':
        asm_file.write(Cmd_function(name=tokens[1], num_args=tokens[2]).generate())
    elif tokens[0] == 'return':
        asm_file.write(Cmd_return().generate())
    elif tokens[0] == 'call':
        asm_file.write(Cmd_call(function_name=tokens[1], num_args=tokens[2]).generate())
    else:
        sys.exit(cmd_name + " I can't recognize these tokens: " + '[%s]' % ', '.join(map(str, tokens)))


def writeInit(asm_file):
    asm_file.write("""    @256
        D=A
        @SP
        M=D
    """)
    writecode(asm_file, parse('call Sys.init 0'))


def banner():
    asm_file.write("// Brian Cunnie's output for Nand to Tetris\n")
    asm_file.write(datetime.datetime.now().strftime("// Compiled: %Y-%m-%d %H:%M\n\n"))


def path_debug():
    sys.stderr.write('\ndirectory: ' + directory +
                     '\ninput_filenames' + str(input_filenames) +
                     '\noutput filename: ' + asm_filename + '\n')


cmd_name = sys.argv[0].split('/')[-1]
directory = os.environ['PWD']
input_filenames = glob.glob('*.vm')
asm_filename = os.path.join(directory, os.path.basename(os.environ['PWD']) + '.asm')
sys.stderr.write('\nsys.argv: ' + str(sys.argv))

if len(sys.argv) > 2:
    sys.exit(cmd_name + " error: pass me one arg, the name of the file to compile, or a directory, or no argument")

if len(sys.argv) == 2:
    file_or_directory = sys.argv[1]
    if os.path.isfile(file_or_directory):
        directory = os.path.dirname(file_or_directory)
        input_filenames = [file_or_directory]
        asm_filename = file_or_directory.replace('.vm', '.asm')
    elif os.path.isdir(file_or_directory):
        directory = file_or_directory.rstrip('/')
        input_filenames = glob.glob(os.path.join(directory, '*.vm'))
        asm_filename = os.path.join(directory, os.path.basename(directory) + '.asm')
    else:
        sys.exit(cmd_name + " error: " + file_or_directory + " isn't a file or directory!")

path_debug()
try:
    asm_file = open(asm_filename, "w")
except:
    sys.exit(cmd_name + " error. I couldn't open " + asm_filename + " for writing!")

banner()

# If there's only one input file, don't bother writing bootstrap code
if len(input_filenames) > 1:
    writeInit(asm_file)

try:
    for line in fileinput.input(input_filenames):
        writecode(asm_file, parse(line))
except:
    sys.exit(cmd_name + " error. I couldn't open " + str(input_filenames) + " for reading!")
