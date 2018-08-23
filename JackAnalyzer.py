#!/usr/local/bin/python2.7
import fileinput
import glob
import os
import re
import sys
import datetime


class JackAnalyzer:
    def __init__(self, source, dest):
        self.dest = dest
        self.tokenizer = JackTokenizer(source)
        return

    def xml(self):
        self.dest.write('<tokens>\n')
        for token in self.tokenizer.tokens:
            if token.type == Token.KEYWORD:
                self.dest.write('<keyword> ' + token.keyWord + ' </keyword>')
            elif token.type == Token.SYMBOL:
                self.dest.write('<symbol> ' + escapeSymbol(token.symbol) + ' </symbol>')
            elif token.type == Token.IDENTIFIER:
                self.dest.write('<identifier> ' + token.identifier + ' </identifier>')
            elif token.type == Token.INT_CONST:
                self.dest.write('<integerConstant> ' + str(token.intVal) + ' </integerConstant>')
            elif token.type == Token.STRING_CONST:
                self.dest.write('<stringConstant> ' + token.stringVal + ' </stringConstant>')
            else:
                sys.stderr.write("I know not this token: \"" + token.type + "\"\n")
                sys.exit(3)
            self.dest.write('\n')
        self.dest.write('</tokens>\n')


class JackTokenizer:
    keywords = 'class', 'constructor', 'function', 'method', 'field', \
               'static', 'var', 'int', 'char', 'boolean', 'void', 'true', \
               'false', 'null', 'this', 'let', 'do', 'if', 'else', 'while', \
               'return'
    symbols = '{', '}', '(', ')', '[', ']', '.', ',', ';', '+', '-', '*', \
              '/', '&', ',', '<', '>', '=', '~'
    reSymbols = re.compile(r'([{\}()\[\],.;+\-*/&<>=~])')
    reIdentifier = re.compile(r'^[a-zA-Z]{1}[a-zA-Z0-9]*$')
    reIntegerConstant = re.compile(r'^\d+$')
    reStringConstant = re.compile(r'^".*"$')

    def __init__(self, source):
        self.source = source
        self.token = None
        self.tokens = self.readAllTokens()
        return

    def hasMoreTokens(self):
        if len(self.tokens) > 0:
            return True
        else:
            return False

    def advance(self):
        self.token = self.tokens.pop(0)

    def tokenType(self):
        return self.token.type

    def symbol(self):
        return self.token.symbol

    def identifier(self):
        return self.token.identifier

    def intVal(self):
        return self.token.intVal

    def stringVal(self):
        return self.token.stringVal

    def readAllTokens(self):
        tokens = []
        input = self.source.read()
        input = re.sub(r'//.*$', '', input, flags=re.MULTILINE)  # strip comments `//`
        input = re.sub(r'/\*.*?\*/', '', input, flags=re.MULTILINE)  # strip comments `/* */`
        bigFields = input.split()
        for bigField in bigFields:
            fields = JackTokenizer.reSymbols.split(bigField)
            for field in fields:
                # sys.stderr.write("field: \"" + field + "\"\n")
                # Lame coding alert: I shouldn't have empty strings
                # and I shouldn't skip them by using `pass`. This
                # code is double-lame, but I'll never fix it, sorry.
                if field == '':
                    pass
                elif field in JackTokenizer.keywords:
                    tokens.append(Token(Token.KEYWORD, keyWord=field))  # += '  <keyword>' + field + '</keyword>\n'
                elif field in JackTokenizer.symbols:
                    tokens.append(
                        Token(Token.SYMBOL, symbol=field))  # xml += '  <symbol>' + escapeSymbol(field) + '</symbol>\n'
                elif JackTokenizer.reIdentifier.match(field):
                    tokens.append(Token(Token.IDENTIFIER, identifier=field))
                elif JackTokenizer.reIntegerConstant.match(field):
                    tokens.append(Token(Token.INT_CONST, intVal=int(
                        field)))  # xml += '  <integerConstant>' + escapeSymbol(field) + '</integerConstant>\n'
                elif JackTokenizer.reStringConstant.match(field):
                    tokens.append(Token(Token.STRING_CONST, stringVal=re.sub(r'^"?(.*?)"?$', r'\1',
                                                                             field)))  # xml += '  <identifier>' + re.sub(r'^"?(.*?)"?$', r'\1', field) + '</identifier>\n'
                else:
                    sys.stderr.write("I can't figure out this field: \"" + field + "\"!")
                    sys.exit(1)
        return (tokens)


# Ensure XML-dangerous symbols are properly escaped
def escapeSymbol(symbol):
    return {
        '<': '&lt;',
        '>': '&gt;',
        '"': '&quot;',
        '&': '&amp;',
    }.get(symbol, symbol)


class Token:
    def __init__(self, type, keyWord=None, symbol=None, identifier=None, intVal=None, stringVal=None):
        self.type = type
        self.keyWord = keyWord
        self.symbol = symbol
        self.symbol = symbol
        self.identifier = identifier
        self.intVal = intVal
        self.stringVal = stringVal

    # Token Types
    KEYWORD = 1
    SYMBOL = 2
    IDENTIFIER = 3
    INT_CONST = 4
    STRING_CONST = 5

    # Key Words (for Token Type KEYWORD)
    CLASS = 10
    METHOD = 11
    FUNCTION = 12
    CONSTRUCTOR = 13
    INT = 14
    BOOLEAN = 15
    CHAR = 16
    VOID = 17
    VAR = 18
    STATIC = 19
    FIELD = 20
    LET = 21
    DO = 22
    IF = 23
    ELSE = 24
    WHILE = 25
    RETURN = 26
    TRUE = 27
    FALSE = 28
    NULL = 29
    THIS = 30


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
    destFileName = sourceFileName.replace('.jack', 'TT.xml')
    try:
        dest = open(destFileName, "w")
    except:
        sys.exit(cmd_name + " error. I couldn't open " + str(sourceFileName) + " for reading!")
    sys.stderr.write(cmd_name + ": opened " + destFileName + " for writing.\n")

    analyzer = JackAnalyzer(source, dest)
    analyzer.xml()
