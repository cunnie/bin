#!/usr/local/bin/python2.7

# This is for the Coursera Nand To Tetris course so I can
# easily determine line numbers when I'm debugging

import sys
import re

line_no = 0
blank_line_or_comment_or_label = re.compile(r"^\s*(//|$|\()")

for line in sys.stdin:
    sys.stdout.write(str(line_no) + '\t' + line)
    if blank_line_or_comment_or_label.match(line) is None:
        line_no += 1
