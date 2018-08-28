#!/usr/local/bin/python2.7
import glob
import os
import re
import sys


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

    ops = '+', '-', '*', '/', '&', '|', '<', '>', '='
    unaryOp = '-', '~'
    KeywordConstant = 'true', 'false', 'null', 'this'

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
        self.indent = ''
        return

    def xml(self):
        self.dest.write('<tokens>\n')
        for token in self.tokens:
            if token.type == Token.KEYWORD:
                self.dest.write('<keyword> ' + token.keyword + ' </keyword>')
            elif token.type == Token.SYMBOL:
                self.dest.write('<symbol> ' + escapeSymbol(token.symbol) + ' </symbol>\n')
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
                    tokens.append(Token(Token.KEYWORD, keyword=field))
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
    def __init__(self, type, keyword=None, symbol=None, identifier=None, intVal=None, stringVal=None):
        self.type = type
        self.keyword = keyword
        self.symbol = symbol
        self.identifier = identifier
        self.intVal = intVal
        self.stringVal = stringVal

    def __repr__(self):
        if self is None:
            return "Token{None}"
        elif self.type == Token.KEYWORD:
            return "Token{keyword: " + self.keyword + "}"
        elif self.type == Token.SYMBOL:
            return "Token(symbol: \"" + self.symbol + "\"}"
        elif self.type == Token.IDENTIFIER:
            return "Token{identifier: " + self.identifier + "}"
        elif self.type == Token.INT_CONST:
            return "Token{int_const: " + self.intVal + "}"
        elif self.type == Token.STRING_CONST:
            return "Token{string_const: \"" + self.stringVal + "\"}"
        else:
            return "Token{weird: strange}"

    # Token Types
    KEYWORD = 1
    SYMBOL = 2
    IDENTIFIER = 3
    INT_CONST = 4
    STRING_CONST = 5

    # Key Words (for Token Type KEYWORD)
    CLASS = "class"
    METHOD = "method"
    FUNCTION = "function"
    CONSTRUCTOR = "constructor"
    INT = "int"
    BOOLEAN = "boolean"
    CHAR = "char"
    VOID = "void"
    VAR = "var"
    STATIC = "static"
    FIELD = "field"
    LET = "let"
    DO = "do"
    IF = "if"
    ELSE = "else"
    WHILE = "while"
    RETURN = "return"
    TRUE = "true"
    FALSE = "false"
    NULL = "null"
    THIS = "this"


class CompilationEngine:

    def __init__(self, tokenizer, dest):
        self.dest = dest
        self.tokenizer = tokenizer
        token = self.tokenizer.token
        if token != None:
            unexpectedToken(token)
        self.indent = ''
        self.tags = []
        while (self.tokenizer.hasMoreTokens()):
            self.tokenizer.advance()
            token = self.tokenizer.token
            if token.type == Token.KEYWORD and token.keyword == Token.CLASS:
                self.CompileClass()
            else:
                unexpectedToken(token)

    def emit(self, token):
        self.dest.write(self.indent)
        if token is None:
            sys.exit('Unexpected null token!\n')
        elif token.type == Token.KEYWORD:
            self.dest.write("<keyword> " + token.keyword + " </keyword>\n")
        elif token.type == Token.SYMBOL:
            self.dest.write("<symbol> " + escapeSymbol(token.symbol) + " </symbol>\n")
        elif token.type == Token.IDENTIFIER:
            self.dest.write("<identifier> " + token.identifier + " </identifier>\n")
        elif token.type == Token.INT_CONST:
            self.dest.write("<integerConstant> " + str(token.intVal) + " </integerConstant>\n")
        elif token.type == Token.STRING_CONST:
            self.dest.write("<stringConstant> " + token.stringVal + " </stringConstant>\n")
        else:
            sys.exit('Unexpected token:' + str(token))

    # tag is typically "<class>" or something along those lines
    def push(self, tag):
        self.dest.write(self.indent)
        self.dest.write(tag + '\n')  # e.g. "class"
        self.indent += '  '
        self.tags.append(tag)

    def pop(self):
        tag = self.tags.pop()
        self.indent = self.indent[2:]
        self.dest.write(self.indent)
        self.dest.write(tag.replace('<', '</') + '\n')

    def CompileClass(self):
        self.push('<class>')
        self.emit(self.tokenizer.token)
        self.tokenizer.advance()
        token = self.tokenizer.token
        if token.type != Token.IDENTIFIER:
            unexpectedToken(token)
        self.emit(token)
        self.tokenizer.advance()
        token = self.tokenizer.token
        if token.type != Token.SYMBOL or token.symbol != '{':
            unexpectedToken(token)
        self.emit(token)

        self.tokenizer.advance()
        token = self.tokenizer.token
        while not (token.type == token.SYMBOL and token.symbol == '}'):
            if token.type == token.KEYWORD:
                if token.keyword == token.STATIC or token.keyword == token.FIELD:
                    self.CompileClassVarDec()
                elif token.keyword == token.CONSTRUCTOR or token.keyword == token.FUNCTION or token.keyword == token.METHOD:
                    self.CompileSubroutine()
                else:
                    unexpectedToken(token)
            else:
                unexpectedToken(token)
            self.tokenizer.advance()
            token = self.tokenizer.token
        self.emit(token)
        self.pop()

    def CompileClassVarDec(self):
        self.push('<classVarDec>')
        token = self.tokenizer.token
        self.emit(token)
        self.tokenizer.advance()
        token = self.tokenizer.token
        if token.type == token.KEYWORD and (
                (token.keyword == token.INT) or
                (token.keyword == token.CHAR) or
                (token.keyword == token.BOOLEAN)):
            self.emit(token)
        elif token.type == token.IDENTIFIER:
            self.emit(token)
        else:
            unexpectedToken(token)
        self.tokenizer.advance()
        token = self.tokenizer.token
        if token.type == token.IDENTIFIER:
            self.emit(token)
        else:
            unexpectedToken(token)
        self.tokenizer.advance()
        token = self.tokenizer.token
        while token.type == Token.SYMBOL and token.symbol == ",":
            self.emit(token)
            self.tokenizer.advance()
            token = self.tokenizer.token
            if token.type == token.IDENTIFIER:
                self.emit(token)
            else:
                unexpectedToken(token)
            self.tokenizer.advance()
            token = self.tokenizer.token
        if token.type == Token.SYMBOL and token.symbol == ";":
            self.emit(token)
        else:
            unexpectedToken(token)
        self.pop()

    def CompileSubroutine(self):
        self.push('<subroutineDec>')
        self.emit(self.tokenizer.token)
        self.tokenizer.advance()
        token = self.tokenizer.token
        if token.type == token.KEYWORD and (
                (token.keyword == token.VOID) or
                (token.keyword == token.INT) or
                (token.keyword == token.CHAR) or
                (token.keyword == token.BOOLEAN)):
            self.emit(token)
        elif token.type == token.IDENTIFIER:
            self.emit(token)
        else:
            unexpectedToken(token)
        self.tokenizer.advance()
        token = self.tokenizer.token
        if token.type == token.IDENTIFIER:
            self.emit(token)
        else:
            unexpectedToken(token)
        self.tokenizer.advance()
        token = self.tokenizer.token
        if token.type == token.SYMBOL and token.symbol == '(':
            self.emit(token)
        else:
            unexpectedToken(token)
        self.tokenizer.advance()
        token = self.tokenizer.token
        self.compileParameterList()
        token = self.tokenizer.token  # token has advanced!
        if token.type == token.SYMBOL and token.symbol == ')':
            self.emit(token)
        else:
            unexpectedToken(token)
        self.tokenizer.advance()
        token = self.tokenizer.token
        # subroutine body
        if token.type == token.SYMBOL and token.symbol == '{':
            self.compileSubroutineBody()
            token = self.tokenizer.token  # token has advanced!
        else:
            unexpectedToken(token)
        self.pop()

    def compileSubroutineBody(self):
        self.push("<subroutineBody>")
        self.emit(self.tokenizer.token)
        self.tokenizer.advance()
        token = self.tokenizer.token
        while not (token.type == Token.SYMBOL and token.symbol == '}'):
            if token.type == Token.KEYWORD and token.keyword == Token.VAR:
                self.compileVarDec()
            else:
                self.compileStatements()
            token = self.tokenizer.token  # token has advanced!
        self.emit(token)
        self.pop()

    def compileParameterList(self):
        self.push("<parameterList>")
        token = self.tokenizer.token
        if not (token.type == token.SYMBOL and token.symbol == ')'):
            token = self.tokenizer.token
            if token.type == token.KEYWORD and (
                    (token.keyword == token.INT) or (token.keyword == token.CHAR) or (token.keyword == token.BOOLEAN)):
                self.emit(token)
            elif token.type == token.IDENTIFIER:
                self.emit(token)
            else:
                unexpectedToken(token)
            self.tokenizer.advance()
            token = self.tokenizer.token
            if token.type == token.IDENTIFIER:
                self.emit(token)
            else:
                unexpectedToken(token)
            self.tokenizer.advance()
            token = self.tokenizer.token
            while token.type == Token.SYMBOL and token.symbol == ",":
                self.emit(token)
                self.tokenizer.advance()
                token = self.tokenizer.token
                if token.type == token.KEYWORD and (
                        (token.keyword == token.INT) or
                        (token.keyword == token.CHAR) or
                        (token.keyword == token.BOOLEAN)):
                    self.emit(token)
                elif token.type == token.IDENTIFIER:
                    self.emit(token)
                else:
                    unexpectedToken(token)
                self.tokenizer.advance()
                token = self.tokenizer.token
                if token.type == token.IDENTIFIER:
                    self.emit(token)
                else:
                    unexpectedToken(token)
                self.tokenizer.advance()
                token = self.tokenizer.token
        self.pop()

    def compileVarDec(self):
        self.push("<varDec>")
        token = self.tokenizer.token
        if token.keyword != Token.VAR:
            unexpectedToken(token)
        self.emit(token)
        self.tokenizer.advance()
        token = self.tokenizer.token
        if token.type == token.KEYWORD and (
                (token.keyword == token.INT) or
                (token.keyword == token.CHAR) or
                (token.keyword == token.BOOLEAN)):
            self.emit(token)
        elif token.type == token.IDENTIFIER:
            self.emit(token)
        else:
            unexpectedToken(token)
        self.tokenizer.advance()
        token = self.tokenizer.token
        if token.type == token.IDENTIFIER:
            self.emit(token)
        else:
            unexpectedToken(token)
        self.tokenizer.advance()
        token = self.tokenizer.token
        while token.type == Token.SYMBOL and token.symbol == ",":
            self.emit(token)
            self.tokenizer.advance()
            token = self.tokenizer.token
            if token.type == token.KEYWORD and (
                    (token.keyword == token.INT) or
                    (token.keyword == token.CHAR) or
                    (token.keyword == token.BOOLEAN)):
                self.emit(token)
            elif token.type == token.IDENTIFIER:
                self.emit(token)
            else:
                unexpectedToken(token)
            self.tokenizer.advance()
            token = self.tokenizer.token
            if token.type == token.IDENTIFIER:
                self.emit(token)
            else:
                unexpectedToken(token)
            self.tokenizer.advance()
            token = self.tokenizer.token
        if token.symbol != ';':
            unexpectedToken(token)
        self.emit(token)
        self.tokenizer.advance()
        self.pop()

    def compileStatements(self):
        self.push("<statements>")
        token = self.tokenizer.token
        while not (token.type == Token.SYMBOL and token.symbol == "}"):
            if token.type == Token.KEYWORD and token.keyword == Token.LET:
                self.compileLet()
            elif token.type == Token.KEYWORD and token.keyword == Token.IF:
                self.compileIf()
            elif token.type == Token.KEYWORD and token.keyword == Token.WHILE:
                self.compileWhile()
            elif token.type == Token.KEYWORD and token.keyword == Token.DO:
                self.compileDo()
            elif token.type == Token.KEYWORD and token.keyword == Token.RETURN:
                self.compileReturn()
            else:
                unexpectedToken(token)
            self.tokenizer.advance()
            token = self.tokenizer.token
        self.pop()

    def compileLet(self):
        self.push("<letStatement>")
        self.emit(self.tokenizer.token)
        self.tokenizer.advance()
        token = self.tokenizer.token
        if token.type == Token.IDENTIFIER:
            self.emit(token)
        else:
            unexpectedToken(token)
        self.tokenizer.advance()
        token = self.tokenizer.token
        if token.type == Token.SYMBOL and token.symbol == '=':
            self.emit(token)
        else:
            unexpectedToken(token)
        self.tokenizer.advance()
        token = self.tokenizer.token
        self.CompileExpression()
        token = self.tokenizer.token
        if not (token.type == Token.SYMBOL and token.symbol == ';'):
            unexpectedToken(token)
        self.emit(token)
        self.pop()

    def compileIf(self):
        self.push("<ifStatement>")
        self.emit(self.tokenizer.token)
        self.tokenizer.advance()
        token = self.tokenizer.token
        if not (token.type == Token.SYMBOL and token.symbol == '('):
            unexpectedToken(token)
        self.emit(token)
        self.tokenizer.advance()
        self.CompileExpression()
        token = self.tokenizer.token  # token has advanced!
        if not (token.type == Token.SYMBOL and token.symbol == ')'):
            unexpectedToken(token)
        self.emit(token)
        self.tokenizer.advance()
        token = self.tokenizer.token
        if not (token.type == Token.SYMBOL and token.symbol == '{'):
            unexpectedToken(token)
        self.emit(token)
        self.tokenizer.advance()
        self.compileStatements()
        token = self.tokenizer.token  # token has advanced!
        if not (token.type == Token.SYMBOL and token.symbol == '}'):
            unexpectedToken(token)
        self.emit(token)
        self.tokenizer.advance()
        token = self.tokenizer.token  # token has advanced!
        if token.type == Token.KEYWORD and token.keyword == Token.ELSE:
            self.tokenizer.advance()
            token = self.tokenizer.token
            if not (token.type == Token.SYMBOL and token.symbol == '{'):
                unexpectedToken(token)
            self.emit(token)
            self.tokenizer.advance()
            self.compileStatements()
        else:
            # shove that token back onto the stack!
            self.tokenizer.tokens.insert(0, token)
        self.pop()

    def compileWhile(self):
        self.push("<whileStatement>")
        self.emit(self.tokenizer.token)  # while
        self.tokenizer.advance()
        token = self.tokenizer.token
        if not (token.type == Token.SYMBOL and token.symbol == '('):
            unexpectedToken(token)
        self.emit(token)
        self.tokenizer.advance()
        self.CompileExpression()
        token = self.tokenizer.token  # token has advanced!
        if not (token.type == Token.SYMBOL and token.symbol == ')'):
            unexpectedToken(token)
        self.emit(token)
        self.tokenizer.advance()
        token = self.tokenizer.token
        if not (token.type == Token.SYMBOL and token.symbol == '{'):
            unexpectedToken(token)
        self.emit(token)
        self.tokenizer.advance()
        self.compileStatements()
        token = self.tokenizer.token  # token has advanced!
        if not (token.type == Token.SYMBOL and token.symbol == '}'):
            unexpectedToken(token)
        self.emit(token)
        self.tokenizer.advance()
        token = self.tokenizer.token  # token has advanced!
        if token.type == Token.KEYWORD and token.keyword == Token.ELSE:
            self.tokenizer.advance()
            token = self.tokenizer.token
            if not (token.type == Token.SYMBOL and token.symbol == '{'):
                unexpectedToken(token)
            self.emit(token)
            self.tokenizer.advance()
            self.compileStatements()
        else:
            # shove that token back onto the stack!
            self.tokenizer.tokens.insert(0, token)
        self.pop()

    def compileDo(self):
        self.push("<doStatement>")
        self.emit(self.tokenizer.token)
        self.tokenizer.advance()
        token = self.tokenizer.token
        if token.type == Token.IDENTIFIER:
            self.emit(token)
        else:
            unexpectedToken(token)
        self.tokenizer.advance()
        token = self.tokenizer.token
        if token.type == Token.SYMBOL and token.symbol == '.':
            self.emit(token)
            self.tokenizer.advance()
            token = self.tokenizer.token
            if token.type == Token.IDENTIFIER:
                self.emit(token)
            else:
                unexpectedToken(token)
            self.tokenizer.advance()
            token = self.tokenizer.token
        if token.type == Token.SYMBOL and token.symbol == '(':
            self.emit(token)
        else:
            unexpectedToken(token)
        self.tokenizer.advance()
        token = self.tokenizer.token
        self.CompileExpressionList()
        token = self.tokenizer.token
        if not (token.type == Token.SYMBOL and token.symbol == ')'):
            unexpectedToken(token)
        self.emit(token)
        self.tokenizer.advance()
        token = self.tokenizer.token
        if not (token.type == Token.SYMBOL):
            unexpectedToken(token)
        self.emit(token)
        self.pop()

    def compileReturn(self):
        self.push("<returnStatement>")
        self.emit(self.tokenizer.token)
        self.tokenizer.advance()
        token = self.tokenizer.token
        if not (token.type == Token.SYMBOL and token.symbol == ';'):
            self.CompileExpression()
        token = self.tokenizer.token  # token has been advanced
        if token.type == Token.SYMBOL and token.symbol == ';':
            self.emit(token)
        else:
            unexpectedToken(token)
        self.pop()

    def CompileExpression(self):
        self.push("<expression>")
        self.CompileTerm()
        token = self.tokenizer.token  # token has advanced
        while token.type == Token.SYMBOL and token.symbol in JackTokenizer.ops:
            self.emit(token)
            self.tokenizer.advance()
            self.CompileTerm()
            token = self.tokenizer.token  # token has advanced
        self.pop()

    def CompileTerm(self):
        self.push("<term>")
        token = self.tokenizer.token
        # FIXME: complete this
        while not (token.type == Token.SYMBOL and token.symbol != '('):
            if token.type == Token.INT_CONST:
                self.emit(token)
            elif token.type == Token.STRING_CONST:
                self.emit(token)
            elif token.type == Token.KEYWORD and token.keyword in JackTokenizer.KeywordConstant:
                self.emit(token)
            elif token.type == Token.IDENTIFIER:
                self.emit(token)
                self.tokenizer.advance()
                token = self.tokenizer.token
                # check if x.y ( expressionlist )
                if token.type == Token.SYMBOL and token.symbol == '.':
                    self.emit(token)
                    self.tokenizer.advance()
                    token = self.tokenizer.token
                    if not (token.type == Token.IDENTIFIER):
                        unexpectedToken(token)
                    self.emit(token)
                    self.tokenizer.advance()
                    token = self.tokenizer.token
                    if not (token.type == Token.SYMBOL and token.symbol == '('):
                        unexpectedToken(token)
                    self.emit(token)
                    self.tokenizer.advance()
                    self.CompileExpressionList()
                    token = self.tokenizer.token  # token has advanced
                    if not (token.type == Token.SYMBOL and token.symbol == ')'):
                        unexpectedToken(token)
                    self.emit(token)
                else:
                    # shove the token back on the stack
                    self.tokenizer.tokens.insert(0, token)
            elif token.type == Token.SYMBOL and token.symbol == '(':
                self.emit(token)
                self.tokenizer.advance()
                self.CompileExpression()
                token = self.tokenizer.token  # token has advanced!
                if not (token.type == Token.SYMBOL and token.symbol == ')'):
                    unexpectedToken(token)
                self.emit(token)
            elif token.type == Token.SYMBOL and token.symbol in JackTokenizer.unaryOp:
                self.emit(token)
                self.tokenizer.advance()
                self.CompileTerm()
            else:
                unexpectedToken(token)
            self.tokenizer.advance()
            token = self.tokenizer.token
        self.pop()

    def CompileExpressionList(self):
        self.push("<expressionList>")
        token = self.tokenizer.token
        while not (token.type == Token.SYMBOL and token.symbol == ')'):
            self.CompileExpression()
            token = self.tokenizer.token  # token has advanced!

            if token.type == Token.SYMBOL and token.symbol == ',':
                self.emit(token)
                self.tokenizer.advance()
                token = self.tokenizer.token
        self.pop()


def unexpectedToken(token):
    sys.stderr.write("Unexpected token: " + str(token) + "!\n")
    sys.stderr.write(token)  # force a stacktrace
    sys.exit(5)


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
