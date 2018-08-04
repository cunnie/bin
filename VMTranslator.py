#!/usr/local/bin/python2.7
import sys

t_cmd = [
    'push',
    'pop',
    'add',
    'sub',
    'neg',
    'eq',
    'gt',
    'lt',
    'and',
    'or',
    'not'
]

t_segment = [
    'argument',
    'local',
    'static',
    'constant',
    'this',
    'that',
    'pointer',
    'temp',
]


def parse(line):
    # strip comments
    no_comments = line.split('#', 1)[0]
    no_comments = no_comments.split('//', 1)[0]
    tokens = no_comments.split()
    parsed_tokens = tokens
    if len(parsed_tokens) > 0:
        parsed_tokens[0] = t_cmd.index(tokens[0])
    if len(parsed_tokens) > 1:
        parsed_tokens[1] = t_segment.index(tokens[1])
    # parsed_tokens[2] is already set
    return parsed_tokens


def writecode(tokens):
    if not tokens:
        return
    asm_file.write('//')
    for token in tokens:
        asm_file.write(' ' + str(token))
    asm_file.write('\n')
    if t_cmd[tokens[0]] == 'add':
        asm_file.write('@SP\n')
        asm_file.write('M=M-1\n')
        asm_file.write('A=M\n')
        asm_file.write('D=M	// D is value at top of the stack\n')
        asm_file.write('@SP\n')
        asm_file.write('A=M-1	// Point to next highest on stack\n')
        asm_file.write('M=D+M	// Add D to that guy\n')
    if t_cmd[tokens[0]] == 'push':
        if t_segment[tokens[1]] == 'constant':
            asm_file.write('@' + tokens[2] + '\n')
            asm_file.write('D=A\n')
            asm_file.write('@SP\n')
            asm_file.write('A=M\n')
            asm_file.write('M=D\n')
            asm_file.write('@SP\n')
            asm_file.write('M=M+1\n')

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
