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
        self.tokenizer = JackTokenizer(source, dest)
        self.compilationEngine = CompilationEngine(self.tokenizer, dest)
        return


class JackTokenizer:
    keywords = 'class', 'constructor', 'function', 'method', 'field', \
               'static', 'var', 'int', 'char', 'boolean', 'void', 'true', \
               'false', 'null', 'this', 'let', 'do', 'if', 'else', 'while', \
               'return'
    symbols = '{', '}', '(', ')', '[', ']', '.', ',', ';', '+', '-', '*', \
              '/', '&', ',', '|', '<', '>', '=', '~'
    # split() note: "f capturing parentheses are used in pattern, then the text of all groups
    # in the pattern are also returned as part of the resulting list". We save the symbols
    # but purposefully lose the whitespace.
    reSymbols = re.compile(r'([{\}()\[\],.;+\-*/&|<>=~])|\s+')
    reIdentifier = re.compile(r'^[a-zA-Z]{1}[a-zA-Z0-9]*$')
    reIntegerConstant = re.compile(r'^\d+$')

    def __init__(self, source, dest):
        self.source = source
        self.dest = dest
        self.token = None
        self.tokens = self.readAllTokens()
        return

    def xml(self):
        self.dest.write('<tokens>\n')
        for token in self.tokens:
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
        inputStream = self.source.read()
        inputStream = re.sub(r'//.*$', '', inputStream, flags=re.MULTILINE)  # strip comments `//`
        inputStream = re.sub(r'/\*.*?\*/', '', inputStream, flags=re.MULTILINE | re.DOTALL)  # strip comments `/* */`
        while inputStream:
            inputStream = inputStream.lstrip()  # strip leading whitespace, if any
            if re.match(r'"', inputStream):
                _, field, inputStream = re.split(r'"', inputStream, 2)
                tokens.append(Token(Token.STRING_CONST, stringVal=field))
            else:
                # Hack alert: the split below will sometimes inject None and '' into the array
                # leaving it with 3 elements & throwing it off. We filter to remove those.
                # e.g. reSymbolsAndWhitespace.split('x {', 1) = ['x', None, '{']
                # matches = [x for x in JackTokenizer.reSymbols.split(inputStream, 1) if x is not None]
                matches = list(filter(None, JackTokenizer.reSymbols.split(inputStream, 1)))
                if len(matches) == 3:
                    field = matches[0]
                    inputStream = matches[1] + matches[2]
                elif len(matches) == 2:
                    field, inputStream = matches
                elif len(matches) == 0:
                    break
                else:
                    sys.stderr.write(str(len(matches)) + ' MATCHES ' + str(matches[:-1]) + '\n')
                    sys.stderr.write("input: " + inputStream + '\n')
                # Lame coding alert: I shouldn't have empty strings
                # and I shouldn't skip them by using `pass`. This
                # code is double-lame, but I'll never fix it, sorry.
                if field in JackTokenizer.keywords:
                    tokens.append(Token(Token.KEYWORD, keyWord=field))
                elif field in JackTokenizer.symbols:
                    tokens.append(Token(Token.SYMBOL, symbol=field))
                elif JackTokenizer.reIdentifier.match(field):
                    tokens.append(Token(Token.IDENTIFIER, identifier=field))
                elif JackTokenizer.reIntegerConstant.match(field):
                    tokens.append(Token(Token.INT_CONST, intVal=int(field)))
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
    def __init__(self, tokenizer, dest):
        self.dest = dest
        self.tokenizer = tokenizer

    def CompileClass(self):
        pass

    def CompileClassVarDec(self):
        pass

    def CompileSubroutine(self):
        pass

    def compileParameterList(self):
        pass

    def compileVarDec(self):
        pass

    def compileStatements(self):
        pass

    def compileDo(self):
        pass

    def compileLet(self):
        pass

    def compileWhile(self):
        pass

    def compileReturn(self):
        pass

    def compileIf(self):
        pass

    def CompileExpression(self):
        pass

    def CompileTerm(self):
        pass

    def CompileExpressionList(self):
        pass

    def xml(self):
        pass


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
    analyzer.tokenizer.xml()
