#!/usr/local/bin/python2.7
import datetime
import glob
import os
import re
import sys
import traceback


class JackAnalyzer:
    def __init__(self, tokenizer, dest):
        self.dest = dest
        self.tokenizer = tokenizer
        return


class Jack:
    keywords = 'class', 'constructor', 'function', 'method', 'field', \
               'static', 'var', 'int', 'char', 'boolean', 'void', 'true', \
               'false', 'null', 'this', 'let', 'do', 'if', 'else', 'while', \
               'return'
    symbols = '{', '}', '(', ')', '[', ']', '.', ',', ';', '+', '-', '*', \
              '/', '&', ',', '|', '<', '>', '=', '~'
    ops = '+', '-', '*', '/', '&', '|', '<', '>', '='
    unaryOp = '-', '~'
    keywordConstant = 'true', 'false', 'null', 'this'

    # Identifier "kinds" for SymbolTable
    # The following 3 must NOT be recorded in the SymbolTable
    CLASS = 17
    SUBROUTINE = 18
    # The following 4 must be recorded in the SymbolTable
    STATIC = 19
    FIELD = 20
    ARG = 21
    VAR = 22

    @staticmethod
    def kind_of(kind):
        return {
            Jack.CLASS: 'class',
            Jack.SUBROUTINE: 'subroutine',
            Jack.STATIC: 'static',
            Jack.FIELD: 'field',
            Jack.ARG: 'arg',
            Jack.VAR: 'var'
        }.get(kind, None)

    def __init__(self):
        # an empty init to satify lint
        pass


class JackTokenizer:
    # split() note: "if capturing parentheses are used in pattern, then the text of all groups
    # in the pattern are also returned as part of the resulting list". We save the symbols
    # but purposefully lose the whitespace.
    reSymbols = re.compile(r'([{\}()\[\],.;+\-*/&|<>=~])|\s+')
    reIdentifier = re.compile(r'^[a-zA-Z][a-zA-Z0-9]*$')
    reIntegerConstant = re.compile(r'^\d+$')

    def __init__(self, source):
        self.source = source
        self.token = None
        self.tokens = self.read_all_tokens()
        self.indent = ''
        self.token_index = -1
        return

    def has_more_tokens(self):
        if self.token_index < len(self.tokens) - 1:
            return True
        else:
            return False

    def advance(self):
        self.token_index += 1
        i = self.token_index
        if i >= len(self.tokens):
            sys.exit('Out of tokens!')
        self.token = self.tokens[i]
        return self.token

    def retreat(self):
        self.token_index -= 1
        i = self.token_index
        if i < 0:
            sys.exit('Negative tokens!')
        self.token = self.tokens[i]

    def token_type(self):
        return self.token.type

    def symbol(self):
        return self.token.symbol

    def identifier(self):
        return self.token.identifier

    def int_val(self):
        return self.token.int_val

    def string_val(self):
        return self.token.string_val

    def read_all_tokens(self):
        tokens = []
        input_stream = self.source.read()
        input_stream = re.sub(r'//.*$', '', input_stream, flags=re.MULTILINE)  # strip comments `//`
        input_stream = re.sub(r'/\*.*?\*/', '', input_stream, flags=re.MULTILINE | re.DOTALL)  # strip comments `/* */`
        while input_stream:
            input_stream = input_stream.lstrip()  # strip leading whitespace, if any
            if re.match(r'"', input_stream):
                _, field, input_stream = re.split(r'"', input_stream, 2)
                tokens.append(Token(Token.STRING_CONST, string_val=field))
            else:
                field = ''
                # Hack alert: the split below will sometimes inject None and '' into the array
                # leaving it with 3 elements & throwing it off. We filter to remove those.
                # e.g. reSymbolsAndWhitespace.split('x {', 1) = ['x', None, '{']
                # matches = [x for x in JackTokenizer.reSymbols.split(input_stream, 1) if x is not None]
                matches = list(filter(None, JackTokenizer.reSymbols.split(input_stream, 1)))
                if len(matches) == 3:
                    field = matches[0]
                    input_stream = matches[1] + matches[2]
                elif len(matches) == 2:
                    field, input_stream = matches
                elif len(matches) == 0:
                    break
                else:
                    sys.stderr.write(str(len(matches)) + ' MATCHES ' + str(matches[:-1]) + '\n')
                    sys.stderr.write("input: " + input_stream + '\n')
                # Lame coding alert: I shouldn't have empty strings
                # and I shouldn't skip them by using `pass`. This
                # code is double-lame, but I'll never fix it, sorry.
                if field in Jack.keywords:
                    tokens.append(Token(Token.KEYWORD, keyword=field))
                elif field in Jack.symbols:
                    tokens.append(Token(Token.SYMBOL, symbol=field))
                elif JackTokenizer.reIdentifier.match(field):
                    tokens.append(Token(Token.IDENTIFIER, identifier=field))
                elif JackTokenizer.reIntegerConstant.match(field):
                    tokens.append(Token(Token.INT_CONST, int_val=int(field)))
                else:
                    sys.stderr.write("I can't figure out this field: \"" + field + "\"!")
                    sys.exit(1)

        return tokens


# Ensure XML-dangerous symbols are properly escaped
def escape_symbol(symbol):
    return {
        '<': '&lt;',
        '>': '&gt;',
        '"': '&quot;',
        '&': '&amp;',
    }.get(symbol, symbol)


class Token:
    def __init__(self, token_type, keyword=None, symbol=None, identifier=None, int_val=None, string_val=None):
        self.type = token_type
        self.keyword = keyword
        self.symbol = symbol
        self.identifier = identifier
        self.intVal = int_val
        self.stringVal = string_val

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
            return "Token{int_const: " + str(self.intVal) + "}"
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


# Ending tokens: the subroutine should leave the token pointing to the
# next one but not have emitted it
# for example, let_statement() 'let varName = expression ;'
# the let_statment is responsible for emitting ';' and advancing the token
# to whatever comes next
class CompilationEngine:

    def __init__(self, tokenizer, symbol_table, vm_writer, dest_vm, dest_xml):
        self.tokenizer = tokenizer
        self.symbol_table = symbol_table
        self.vm_writer = vm_writer
        self.dest_vm = dest_vm
        self.dest_xml = dest_xml
        self.indent = ''
        self.class_name = None
        self.function_name = None
        self.tags = []
        self.while_exp = 0
        self.if_true = 0

    def emit(self, token):
        self.dest_xml.write(self.indent)
        if token is None:
            sys.exit('Unexpected null token!\n')
        elif token.type == Token.KEYWORD:
            self.dest_xml.write("<keyword> " + token.keyword + " </keyword>\n")
        elif token.type == Token.SYMBOL:
            self.dest_xml.write("<symbol> " + escape_symbol(token.symbol) + " </symbol>\n")
        elif token.type == Token.IDENTIFIER:
            self.dest_xml.write("<identifier> " + token.identifier + " </identifier>\n")
        elif token.type == Token.INT_CONST:
            self.dest_xml.write("<integerConstant> " + str(token.intVal) + " </integerConstant>\n")
        elif token.type == Token.STRING_CONST:
            self.dest_xml.write("<stringConstant> " + token.stringVal + " </stringConstant>\n")
        else:
            sys.exit('Unexpected token:' + str(token))

    # tag is typically "<class>" or something along those lines
    def push(self, tag):
        self.dest_xml.write(self.indent + tag + '\n')
        self.indent += '  '
        self.tags.append(tag)

    def pop(self):
        tag = self.tags.pop()
        self.indent = self.indent[2:]
        self.dest_xml.write(self.indent + tag.replace('<', '</') + '\n')

    def compile_class(self):
        self.push('<class>')
        self.emit(self.tokenizer.token)
        token = self.tokenizer.advance()

        if token.type != Token.IDENTIFIER:
            unexpected_token(token)
        self.emit(token)
        self.class_name = token.identifier
        token = self.tokenizer.advance()
        if token.type != Token.SYMBOL or token.symbol != '{':
            unexpected_token(token)
        self.emit(token)

        token = self.tokenizer.advance()
        while not (token.type == Token.SYMBOL and token.symbol == '}'):
            if token.type == Token.KEYWORD:
                if token.keyword == Token.STATIC or token.keyword == Token.FIELD:
                    self.compile_class_var_dec()
                elif token.keyword == Token.CONSTRUCTOR or \
                        token.keyword == Token.FUNCTION or \
                        token.keyword == Token.METHOD:
                    self.compile_subroutine()
                else:
                    unexpected_token(token)
            else:
                unexpected_token(token)
            token = self.tokenizer.advance()
        self.emit(token)
        self.pop()

    def compile_class_var_dec(self):
        self.push('<classVarDec>')
        token = self.tokenizer.token
        self.emit(token)
        token_kind = token.keyword
        token_type = None  # placate linter
        token = self.tokenizer.advance()
        if token.type == Token.KEYWORD and (
                (token.keyword == Token.INT) or
                (token.keyword == Token.CHAR) or
                (token.keyword == Token.BOOLEAN)):
            self.emit(token)
            token_type = token.keyword
        elif token.type == Token.IDENTIFIER:
            self.emit(token)
            token_type = token.identifier
        else:
            unexpected_token(token)
        token = self.tokenizer.advance()
        if token.type == Token.IDENTIFIER:
            self.emit(token)
            self.symbol_table.define(
                name=token.identifier,
                kind=token_kind,
                token_type=token_type)
        else:
            unexpected_token(token)
        token = self.tokenizer.advance()
        while token.type == Token.SYMBOL and token.symbol == ",":
            self.emit(token)
            token = self.tokenizer.advance()
            if token.type == Token.IDENTIFIER:
                self.emit(token)
                self.symbol_table.define(
                    name=token.identifier,
                    kind=token_kind,
                    token_type=token_type)
                token = self.tokenizer.advance()
            else:
                unexpected_token(token)
        if token.type == Token.SYMBOL and token.symbol == ";":
            self.emit(token)
        else:
            unexpected_token(token)
        self.pop()

    def compile_subroutine(self):
        # reset the loop counters, not important, but makes
        # this compiler's output match the canonical's
        self.if_true = 0
        self.while_exp = 0
        self.push('<subroutineDec>')
        self.emit(self.tokenizer.token)
        token = self.tokenizer.advance()
        self.symbol_table.start_subroutine()
        if token.type == Token.KEYWORD and (
                (token.keyword == Token.VOID) or
                (token.keyword == Token.INT) or
                (token.keyword == Token.CHAR) or
                (token.keyword == Token.BOOLEAN)):
            self.emit(token)
        elif token.type == Token.IDENTIFIER:
            self.emit(token)
        else:
            unexpected_token(token)
        token = self.tokenizer.advance()
        if token.type == Token.IDENTIFIER:
            self.emit(token)
        else:
            unexpected_token(token)
        self.function_name = token.identifier
        token = self.tokenizer.advance()
        if token.type == Token.SYMBOL and token.symbol == '(':
            self.emit(token)
        else:
            unexpected_token(token)
        self.tokenizer.advance()
        self.compile_parameter_list()
        token = self.tokenizer.token  # token has advanced!
        if token.type == Token.SYMBOL and token.symbol == ')':
            self.emit(token)
        else:
            unexpected_token(token)
        token = self.tokenizer.advance()
        # subroutine body
        if token.type == Token.SYMBOL and token.symbol == '{':
            self.compile_subroutine_body()
            _ = self.tokenizer.token  # token has advanced!
        else:
            unexpected_token(token)
        self.pop()

    def compile_subroutine_body(self):
        self.push("<subroutineBody>")
        self.emit(self.tokenizer.token)
        token = self.tokenizer.advance()
        while not (token.type == Token.SYMBOL and token.symbol == '}'):
            if token.type == Token.KEYWORD and token.keyword == Token.VAR:
                self.compile_var_dec()
            else:
                self.vm_writer.write_function(
                    self.class_name + '.' + self.function_name,
                    self.symbol_table.var_count(Jack.VAR)
                )
                self.compile_statements()
            token = self.tokenizer.token  # token has advanced!
        self.emit(token)
        self.pop()

    def compile_parameter_list(self):
        self.push("<parameterList>")
        token = self.tokenizer.token
        token_type = None  # placate linter
        if not (token.type == Token.SYMBOL and token.symbol == ')'):
            if token.type == Token.KEYWORD and (
                    (token.keyword == Token.INT) or
                    (token.keyword == Token.CHAR) or
                    (token.keyword == Token.BOOLEAN)):
                self.emit(token)
                token_type = token.keyword
            elif token.type == Token.IDENTIFIER:
                token_type = token.identifier
                self.emit(token)
            else:
                unexpected_token(token)
            token = self.tokenizer.advance()
            if token.type == Token.IDENTIFIER:
                self.symbol_table.define(
                    name=token.identifier,
                    kind=Jack.ARG,
                    token_type=token_type)
                self.emit(token)
            else:
                unexpected_token(token)
            token = self.tokenizer.advance()
            while token.type == Token.SYMBOL and token.symbol == ",":
                self.emit(token)
                token = self.tokenizer.advance()
                if token.type == Token.KEYWORD and (
                        (token.keyword == Token.INT) or
                        (token.keyword == Token.CHAR) or
                        (token.keyword == Token.BOOLEAN)):
                    self.emit(token)
                    token_type = token.keyword
                elif token.type == Token.IDENTIFIER:
                    token_type = token.identifier
                    self.emit(token)
                else:
                    unexpected_token(token)
                token = self.tokenizer.advance()
                if token.type == Token.IDENTIFIER:
                    self.emit(token)
                    self.symbol_table.define(
                        name=token.identifier,
                        kind=Jack.ARG,
                        token_type=token_type)
                else:
                    unexpected_token(token)
                token = self.tokenizer.advance()
        self.pop()

    def compile_var_dec(self):
        self.push("<varDec>")
        token = self.tokenizer.token
        if token.keyword != Token.VAR:
            unexpected_token(token)
        self.emit(token)
        # every symbol will be a "kind" of "VAR" in this method
        token_kind = Jack.VAR
        token_type = None  # placate linter
        token = self.tokenizer.advance()
        if token.type == Token.KEYWORD and (
                (token.keyword == Token.INT) or
                (token.keyword == Token.CHAR) or
                (token.keyword == Token.BOOLEAN)):
            self.emit(token)
            token_type = token.keyword
        elif token.type == Token.IDENTIFIER:
            # if we're not a builtin type, then we're a class type
            token_type = token.identifier
            self.emit(token)
        else:
            unexpected_token(token)
        token = self.tokenizer.advance()
        if token.type == Token.IDENTIFIER:
            self.emit(token)
            self.symbol_table.define(
                name=token.identifier,
                kind=token_kind,
                token_type=token_type)
        else:
            unexpected_token(token)
        token = self.tokenizer.advance()
        while token.type == Token.SYMBOL and token.symbol == ",":
            self.emit(token)
            token = self.tokenizer.advance()
            if token.type == Token.IDENTIFIER:
                self.emit(token)
                self.symbol_table.define(
                    name=token.identifier,
                    kind=token_kind,
                    token_type=token_type)
                token = self.tokenizer.advance()
            else:
                unexpected_token(token)
        if token.symbol != ';':
            unexpected_token(token)
        self.emit(token)
        _ = self.tokenizer.advance()
        self.pop()

    def compile_statements(self):
        self.push("<statements>")
        token = self.tokenizer.token
        while not (token.type == Token.SYMBOL and token.symbol == "}"):
            if token.type == Token.KEYWORD and token.keyword == Token.LET:
                token = self.compile_let()
            elif token.type == Token.KEYWORD and token.keyword == Token.IF:
                token = self.compile_if()
            elif token.type == Token.KEYWORD and token.keyword == Token.WHILE:
                token = self.compile_while()
            elif token.type == Token.KEYWORD and token.keyword == Token.DO:
                token = self.compile_do()
            elif token.type == Token.KEYWORD and token.keyword == Token.RETURN:
                token = self.compile_return()
            else:
                unexpected_token(token)
        self.pop()

    def compile_let(self):
        self.push("<letStatement>")
        self.emit(self.tokenizer.token)
        token = self.tokenizer.advance()
        lhs = None  # placate linter
        if token.type == Token.IDENTIFIER:
            self.emit(token)
            lhs = token.identifier  # lhs = left-hand side = assignee
            token = self.tokenizer.advance()
        else:
            unexpected_token(token)
        if token.type == Token.SYMBOL and token.symbol == '[':
            # FIXME I'll need to do arrays at some point
            token = self.paren_expression_paren(left='[', right=']')
        if token.type == Token.SYMBOL and token.symbol == '=':
            self.emit(token)
            _ = self.tokenizer.advance()
        else:
            unexpected_token(token)
        self.compile_expression()
        token = self.tokenizer.token  # token has advanced
        if not (token.type == Token.SYMBOL and token.symbol == ';'):
            unexpected_token(token)
        self.emit(token)
        s = self.symbol_table
        self.vm_writer.write_pop(s.kind_to_segment(s.kind_of(lhs)), s.index_of(lhs))
        self.pop()
        return self.tokenizer.advance()

    def compile_if(self):
        self.push("<ifStatement>")
        # store our index & increment index for next while
        iter = self.if_true
        self.if_true += 1
        self.emit(self.tokenizer.token)
        _ = self.tokenizer.advance()
        _ = self.paren_expression_paren()
        self.vm_writer.write_if('IF_TRUE{}'.format(iter))
        self.vm_writer.write_goto('IF_FALSE{}'.format(iter))
        self.vm_writer.write_label('IF_TRUE{}'.format(iter))
        token = self.brace_statements_brace()
        self.vm_writer.write_goto('IF_END{}'.format(iter))
        self.vm_writer.write_label('IF_FALSE{}'.format(iter))
        if token.type == Token.KEYWORD and token.keyword == Token.ELSE:
            self.emit(token)
            _ = self.tokenizer.advance()
            _ = self.brace_statements_brace()
        self.vm_writer.write_label('IF_END{}'.format(iter))
        self.pop()
        return self.tokenizer.token

    def compile_while(self):
        self.push("<whileStatement>")
        # store our index & increment index for next while
        iter = self.while_exp
        self.while_exp += 1
        self.vm_writer.write_label('WHILE_EXP{}'.format(iter))
        self.emit(self.tokenizer.token)  # while
        _ = self.tokenizer.advance()
        _ = self.paren_expression_paren()
        self.vm_writer.write_arithmetic('not')
        self.vm_writer.write_if('WHILE_END{}'.format(iter))
        _ = self.brace_statements_brace()
        self.vm_writer.write_goto('WHILE_EXP{}'.format(iter))
        self.vm_writer.write_label('WHILE_END{}'.format(iter))
        self.pop()
        return self.tokenizer.token

    def compile_do(self):
        self.push("<doStatement>")
        self.emit(self.tokenizer.token)
        token = self.tokenizer.advance()
        if token.type == Token.IDENTIFIER:
            self.emit(token)
        else:
            unexpected_token(token)
        call_name = token.identifier
        _ = self.tokenizer.advance()
        token = self.subroutine_call(call_name)
        self.vm_writer.write_pop('temp', 0)  # pop return value to Never Never Land
        if not (token.type == Token.SYMBOL and token.symbol == ';'):
            unexpected_token(token)
        self.emit(token)
        self.pop()
        return self.tokenizer.advance()

    def compile_return(self):
        self.push("<returnStatement>")
        self.emit(self.tokenizer.token)
        token = self.tokenizer.advance()
        if not (token.type == Token.SYMBOL and token.symbol == ';'):
            token = self.compile_expression()
        else:
            # if we're doing a bare return, return 0
            self.vm_writer.write_push('constant', 0)
        if token.type == Token.SYMBOL and token.symbol == ';':
            self.emit(token)
        else:
            unexpected_token(token)
        self.vm_writer.write_return()
        self.pop()
        return self.tokenizer.advance()

    def compile_expression(self):
        self.push("<expression>")
        self.compile_term()
        token = self.tokenizer.token
        while token.type == Token.SYMBOL and token.symbol in Jack.ops:
            op = token.symbol
            self.emit(token)
            _ = self.tokenizer.advance()
            self.compile_term()
            self.vm_writer.write_arithmetic(
                {
                    '+': 'add',
                    '-': 'sub',
                    '*': 'call Math.multiply 2',
                    '/': 'call Math.divide 2',
                    '&': 'and',
                    '|': 'or',
                    '<': 'lt',
                    '>': 'gt',
                    '=': 'eq',
                }[op])
            token = self.tokenizer.token  # token has advanced
        self.pop()
        return self.tokenizer.token

    def compile_term(self):
        self.push("<term>")
        token = self.tokenizer.token
        if token.type == Token.INT_CONST:
            self.emit(token)
            self.vm_writer.write_push("constant", token.intVal)
            _ = self.tokenizer.advance()
        elif token.type == Token.STRING_CONST:
            self.emit(token)
            self.vm_writer.write_push("constant", token.stringVal)
            _ = self.tokenizer.advance()
        elif token.type == Token.KEYWORD and token.keyword in Jack.keywordConstant:
            if token.keyword == 'true':
                self.vm_writer.write_push("constant", 0)
                # p 235 says to use 'neg' but their compiler uses 'not'
                self.vm_writer.write_arithmetic('not')
            elif token.keyword == 'null' or token.keyword == 'false':
                self.vm_writer.write_push("constant", 0)
            elif token.keyword == 'this':
                traceback.print_stack()
                sys.exit(5)
            else:
                unexpected_token(token)
            self.emit(token)
            _ = self.tokenizer.advance()
        elif token.type == Token.IDENTIFIER:
            self.emit(token)
            call_or_variable_name = token.identifier
            token = self.tokenizer.advance()
            # Is this a subroutine_call? Yes if the next token
            # is '(' or '.'
            if token.type == Token.SYMBOL and \
                    (token.symbol == '(' or token.symbol == '.'):
                self.subroutine_call(call_or_variable_name)
            elif token.type == Token.SYMBOL and token.symbol == '[':
                # FIXME deal with arrays
                _ = self.paren_expression_paren(left='[', right=']')
            else:  # it's a variable -- push it!
                s = self.symbol_table
                self.vm_writer.write_push(
                    s.kind_to_segment(s.kind_of(call_or_variable_name)),
                    s.index_of(call_or_variable_name))
        elif token.type == Token.SYMBOL and token.symbol == '(':
            _ = self.paren_expression_paren()
        elif token.type == Token.SYMBOL and token.symbol == '-':
            self.emit(token)
            _ = self.tokenizer.advance()
            self.compile_term()
            self.vm_writer.write_arithmetic('neg')
        elif token.type == Token.SYMBOL and token.symbol == '~':
            self.emit(token)
            _ = self.tokenizer.advance()
            self.compile_term()
            self.vm_writer.write_arithmetic('not')
        else:
            unexpected_token(token)
        self.pop()

    def subroutine_call(self, call_name):
        # the subroutine (identifier) has already been emitted; the current token is either '(' or '.'
        token = self.tokenizer.token
        n_args = 0
        if token.symbol == '(':
            pass
        elif token.symbol == '.':
            self.emit(token)
            token = self.tokenizer.advance()
            if token.type != Token.IDENTIFIER:
                unexpected_token(token)
            self.emit(token)
            if self.is_method(object_or_class=call_name):
                s = self.symbol_table
                # we need to push the first argument, myself
                # e.g. 'game'
                self.vm_writer.write_push(
                    s.kind_to_segment(s.kind_of(call_name)),
                    s.index_of(call_name))
                # we're calling a method, not a function, so we need
                # to get the class name from the symbol table
                # e.g. SquareGame.run
                call_name = s.type_of(call_name) + '.' + token.identifier
                # ...and also we need to increment the number of args
                # to account for the implied object arg (first one)
                n_args = 1
            else:
                # if we're here, we're calling a function in another class
                # e.g. `Output.printInt()`
                call_name = call_name + '.' + token.identifier
            _ = self.tokenizer.advance()
        else:
            unexpected_token(token)
        n_args += self.paren_expression_list_paren()
        self.vm_writer.write_call(call_name, n_args)
        return self.tokenizer.token

    # Are we a method or a function? This determines how we call
    # it (methods are called with an extra, "invisible" variable
    # which is the object). If the "call" name is in the
    # symbol table (e.g 'game'), then it's a method, otherwise the "call"
    # name is a class (e.g. 'SquareGame'), and classes aren't in the symbol table
    def is_method(self, object_or_class):
        if self.symbol_table.index_of(object_or_class) is not None:
            # it's an object, not a classname, so it's a method
            return True
        else:
            return False

    def paren_expression_list_paren(self):
        # the current token is '(' and hasn't been emitted
        token = self.tokenizer.token
        self.emit(token)
        if token.symbol != '(':
            unexpected_token(token)
        _ = self.tokenizer.advance()
        n_args = self.compile_expression_list()
        token = self.tokenizer.token  # token has advanced!
        if token.symbol == ')':
            self.emit(token)
            _ = self.tokenizer.advance()
        else:
            unexpected_token(token)
        # ')' has been emitted and the current token is the one after
        return n_args

    def paren_expression_paren(self, left='(', right=')'):
        # the current token is '(' (or "left") and hasn't been emitted
        token = self.tokenizer.token
        self.emit(token)
        if token.symbol != left:
            unexpected_token(token)
        _ = self.tokenizer.advance()
        self.compile_expression()
        token = self.tokenizer.token  # token has advanced!
        if token.symbol == right:
            self.emit(token)
            _ = self.tokenizer.advance()
        else:
            unexpected_token(token)
        # ')' (or "right") has been emitted and the current token is the one after
        return self.tokenizer.token

    def brace_statements_brace(self):
        # the current token is '{' and hasn't been emitted
        token = self.tokenizer.token
        if not (token.type == Token.SYMBOL and token.symbol == '{'):
            unexpected_token(token)
        self.emit(token)
        _ = self.tokenizer.advance()
        self.compile_statements()
        token = self.tokenizer.token  # token has advanced!
        if not (token.type == Token.SYMBOL and token.symbol == '}'):
            unexpected_token(token)
        self.emit(token)
        return self.tokenizer.advance()
        # '}' has been emitted and the current token is the one after

    def compile_expression_list(self):
        self.push("<expressionList>")
        n_args = 0  # number of arguments in expression list
        token = self.tokenizer.token
        while not (token.type == Token.SYMBOL and token.symbol == ')'):
            self.compile_expression()
            n_args += 1
            token = self.tokenizer.token  # token has advanced!

            if token.type == Token.SYMBOL and token.symbol == ',':
                self.emit(token)
                token = self.tokenizer.advance()
        self.pop()
        return n_args


class SymbolTable:
    # The symbol table is two tables made to look like one;
    # It works like this: The symbol table for the classes
    # occupy indices 0 - (length of symbol for classes - 1)
    # and the symbol table for subroutines occupy the indices
    # (length of symbol table) - (length of both tables - 1)
    def __init__(self):
        self.class_symbols = []
        self.subroutine_symbols = []
        self.current_class = None

    def __repr__(self):
        rc = '[\n'
        for symbol in self.class_symbols:
            rc += '  {{ name: "{}", token_type: {}, kind: {} }},\n'.format(
                symbol['name'], symbol['token_type'], symbol['kind'])
        for symbol in self.subroutine_symbols:
            rc += '  {{ name: {}, token_type: {}, kind: {} }},\n'.format(
                symbol['name'], symbol['token_type'], symbol['kind'])
        rc += ']\n'
        return rc

    @staticmethod
    def kind_to_segment(kind):
        if kind is not None:
            return {
                Jack.STATIC: 'static',
                Jack.FIELD: 'field',
                Jack.ARG: 'argument',
                Jack.VAR: 'local',
            }[kind]

    def start_subroutine(self):
        # Starts a new subroutine scope (i.e., resets the subroutine's symbol table)
        self.subroutine_symbols = []

    def define(self, name, kind, token_type):
        # Defines a new identifier of a given name, token_type, and kind
        # and assigns it a running index. STATIC and FIELD identifiers
        # have a class scope, while ARG and VAR identifiers have a subroutine scope
        # returns index of symbol
        if name is None:
            traceback.print_stack()
        if kind == Jack.CLASS or kind == Jack.SUBROUTINE:
            return  # these aren't recorded in the SymbolTable
        elif kind == Jack.STATIC or kind == Jack.FIELD:
            self.class_symbols.append({'name': name, 'token_type': token_type, 'kind': kind})
            return len(self.class_symbols) - 1
        elif kind == Jack.ARG or kind == Jack.VAR:
            self.subroutine_symbols.append({'name': name, 'token_type': token_type, 'kind': kind})
            return len(self.class_symbols + self.subroutine_symbols) - 1
        else:
            sys.stderr.write("Invalid identifier kind: \"{}\"\n".format(kind))
            traceback.print_stack()
            sys.exit(5)

    def var_count(self, kind):
        #  Returns the number of variables of the given kind already defined in the current scope
        return len(list(filter(
            lambda x: x['kind'] == kind,
            (self.class_symbols + self.subroutine_symbols)
        )))

    def kind_of(self, name):
        # Returns the kind of the named identifier in the current scope.
        # If the identifier is unknown in the current scope, returns NONE
        # STATIC, FIELD, ARG, VAR, NONE
        symbol = self.find_my_symbol(name)
        if symbol is not None:
            return symbol['kind']

    def type_of(self, name):
        # Returns the type of the named identifier in the current scope
        symbol = self.find_my_symbol(name)
        if symbol is not None:
            return symbol['token_type']

    def find_my_symbol(self, name):
        for symbol in self.subroutine_symbols:
            if symbol['name'] == name:
                return symbol
        for symbol in self.class_symbols:
            if symbol['name'] == name:
                return symbol

    def index_of(self, name):
        kind = self.kind_of(name)
        kind_list = list(filter(
            lambda x: x['kind'] == kind,
            (self.class_symbols + self.subroutine_symbols)
        ))
        for i, symbol in enumerate(kind_list):
            if symbol['name'] == name:
                return i


class VMWriter:
    def __init__(self, dest):
        self.dest = dest
        self.functions = []
        pass

    def write_push(self, segment, index):
        # Writes a VM push command
        # Segment (CONST, ARG, LOCAL, STATIC, THIS, THAT, POINTER, TEMP)
        # Index (int)
        self.dest.write("push {} {}\n".format(segment, index))

    def write_pop(self, segment, index):
        # Writes a VM pop command
        # Segment (CONST, ARG, LOCAL, STATIC, THIS, THAT, POINTER, TEMP)
        # Index (int)
        self.dest.write("pop {} {}\n".format(segment, index))

    def write_arithmetic(self, command):
        # Writes a VM arithmetic command
        # command (ADD, SUB, NEG, EQ, GT, LT, AND, OR, NOT
        self.dest.write("{}\n".format(command))

    def write_label(self, label):
        # Writes a VM `label` command
        self.dest.write("label {}\n".format(label))

    def write_goto(self, label):
        # Writes a VM `goto` command
        self.dest.write("goto {}\n".format(label))

    def write_if(self, label):
        # Writes a VM `If-goto` command
        self.dest.write("if-goto {}\n".format(label))

    def write_call(self, name, n_args):
        # Writes a VM `call` command
        self.dest.write("call {} {}\n".format(name, str(n_args)))

    def write_function(self, name, n_locals):
        # Writes a VM `function` command
        if name not in self.functions:
            self.functions.append(name)
            self.dest.write("function {} {}\n".format(name, str(n_locals)))

    def write_return(self):
        # Writes a VM `return` command
        self.dest.write("return\n")

    def close(self):
        # Closes the output file
        self.dest.close()


class JackCompiler:
    def __init__(self, source, dest_vm, dest_xml):
        self.source = source
        self.dest_vm = dest_vm
        self.dest_xml = dest_xml
        self.tokenizer = JackTokenizer(source)
        self.symbol_table = SymbolTable()
        self.vm_writer = VMWriter(dest_vm)
        self.compilation_engine = CompilationEngine(tokenizer=self.tokenizer,
                                                    symbol_table=self.symbol_table,
                                                    vm_writer=self.vm_writer,
                                                    dest_vm=dest_vm,
                                                    dest_xml=dest_xml)

        token = self.tokenizer.token
        if token is not None:  # first token should always be None
            unexpected_token(token)
        self.indent = ''
        self.tags = []
        while self.tokenizer.has_more_tokens():
            token = self.tokenizer.advance()
            if token.type == Token.KEYWORD and token.keyword == Token.CLASS:
                self.compilation_engine.compile_class()
            else:
                unexpected_token(token)


def unexpected_token(token):
    sys.stderr.write("Unexpected token: " + str(token) + "!\n")
    traceback.print_stack()
    sys.exit(5)


# return a list of filenames to compile
def jack_source_filenames():
    cmd_name = sys.argv[0].split('/')[-1]
    source_filenames = glob.glob('*.jack')  # initialize to all the .jack files in PWD
    sys.stderr.write('sys.argv: ' + str(sys.argv) + '\n')

    if len(sys.argv) > 2:
        sys.exit(cmd_name + " error: pass me one arg, the name of the file to compile, or a directory, or no argument")

    if len(sys.argv) == 2:
        file_or_directory = sys.argv[1]
        if os.path.isfile(file_or_directory):
            source_filenames = [file_or_directory]
        elif os.path.isdir(file_or_directory):
            directory = file_or_directory.rstrip('/')
            source_filenames = glob.glob(os.path.join(directory, '*.jack'))
        else:
            sys.exit(cmd_name + " error: " + file_or_directory + " isn't a file or directory!")
    return source_filenames


def banner():
    return "// Brian Cunnie's output for Nand to Tetris\n" + \
           datetime.datetime.now().strftime("// Compiled: %Y-%m-%d %H:%M\n\n")


# main
def main():
    cmd_name = sys.argv[0].split('/')[-1]
    for source_filename in jack_source_filenames():
        try:
            source = open(source_filename, "r")
        except IOError as e:
            sys.exit(cmd_name + " error. I couldn't open " + str(source_filename) + " for reading: " + e.strerror)
        sys.stderr.write(cmd_name + ": opened " + source_filename + " for reading.\n")
        dest_xml_filename = source_filename.replace('.jack', '.xml')
        try:
            dest_xml = open(dest_xml_filename, "w")
        except IOError as e:
            sys.exit(cmd_name + " error. I couldn't open " + str(source_filename) + " for reading: " + e.strerror)
        sys.stderr.write(cmd_name + ": opened " + dest_xml_filename + " for writing.\n")
        dest_vm_filename = source_filename.replace('.jack', '.vm')
        try:
            dest_vm = open(dest_vm_filename, "w")
            dest_vm.write(banner())
        except IOError as e:
            sys.exit(cmd_name + " error. I couldn't open " + str(source_filename) + " for reading: " + e.strerror)
        sys.stderr.write(cmd_name + ": opened " + dest_vm_filename + " for writing.\n")

        _ = JackCompiler(source, dest_vm, dest_xml)


if __name__ == "__main__":
    main()
