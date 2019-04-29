#!/usr/bin/env python3
def love(a):
    print( "I love my {}".format(a))

def decorator_love(func):
    def inner_love(a):
        print( "I miss my dog, Cherie.")
        return func(a)
    return inner_love

new_func = decorator_love(love)

new_func("Kit")
