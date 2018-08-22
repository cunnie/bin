#!/usr/local/bin/python2.7
import fileinput
import glob
import os
import re
import sys
import datetime


class JackAnalyzer:
    def __init__(self, source, dest):
        self.source = source
        self.dest = dest
        self.tokenizer = JackTokenizer()
        return

    def tokenize(self):
        self.dest.write('<tokens>\n')
        for line in self.source:
            self.dest.write(self.tokenizer.tokenize(line))
        self.dest.write('</tokens>\n')


class JackTokenizer:
    keywords = 'class', 'constructor', 'function', 'method', 'field', \
               'static', 'var', 'int', 'char', 'boolean', 'void', 'true', \
               'false', 'null', 'this', 'let', 'do', 'if', 'else', 'while', \
               'return'
    symbols = '{', '}', '(', ')', '[', ']', '.', ',', ';', '+', '-', '*', \
              '/', '&', ',', '<', '>', '=', '~'
    reSymbols = re.compile(r'([{\}()\[\],.;+\-*/&<>=~])')
    reIntegerConstant = re.compile(r'\d+')

    def __init__(self):
        return

    def tokenize(self, line):
        xml = ''
        bigFields = line.split()
        for bigField in bigFields:
            fields = JackTokenizer.reSymbols.split(bigField)
            for field in fields:
                # Lame coding alert: I shouldn't have empty strings
                # and I shouldn't skip them by using `pass`. This
                # code is double-lame, but I'll never fix it, sorry.
                if field == '':
                    pass
                elif field in JackTokenizer.keywords:
                    xml += '  <keyword>' + field + '</keyword>\n'
                elif field in JackTokenizer.symbols:
                    xml += '  <symbol>' + escapeSymbol(field) + '</symbol>\n'
                else:
                    xml += '  <identifier>' + field + '</identifier>\n'
        return (xml)


# Ensure XML-dangerous symbols are properly escaped
def escapeSymbol(symbol):
    return {
        '<': '&lt;',
        '>': '&gt;',
        '"': '&quot;',
        '&': '&amp;',
    }.get(symbol, symbol)


class CompilationEngine:
    def __init__(self):
        return


# Open the file & Analyze

# return a list of filenames to compile
def jackSourceFilenames():
    cmd_name = sys.argv[0].split('/')[-1]
    sourceFilenames = glob.glob('*.jack')  # initialize to all the .jack files in PWD
    sys.stderr.write('sys.argv: ' + str(sys.argv) + '\n')

    if len(sys.argv) > 2:
        sys.exit(cmd_name + " error: pass me one arg, the name of the file to compile, or a directory, or no argument")

    if len(sys.argv) == 2:
        file_or_directory = sys.argv[1]
        if os.path.isfile(file_or_directory):
            sourceFilenames = [file_or_directory]
        elif os.path.isdir(file_or_directory):
            directory = file_or_directory.rstrip('/')
            sourceFilenames = glob.glob(os.path.join(directory, '*.jack'))
        else:
            sys.exit(cmd_name + " error: " + file_or_directory + " isn't a file or directory!")
    return sourceFilenames


# main
cmd_name = sys.argv[0].split('/')[-1]
for sourceFileName in jackSourceFilenames():
    try:
        source = open(sourceFileName, "r")
    except:
        sys.exit(cmd_name + " error. I couldn't open " + str(sourceFileName) + " for reading!")
    sys.stderr.write(cmd_name + ": opened " + sourceFileName + " for reading.\n")
    destFileName = sourceFileName.replace('.jack', '.xml')
    try:
        dest = open(destFileName, "w")
    except:
        sys.exit(cmd_name + " error. I couldn't open " + str(sourceFileName) + " for reading!")
    sys.stderr.write(cmd_name + ": opened " + destFileName + " for writing.\n")

    analyzer = JackAnalyzer(source, dest)
    analyzer.tokenize()
