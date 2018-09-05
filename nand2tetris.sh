#!/bin/bash
set -eu

pushd ~/Desktop/nand2tetris/projects/11/Seven
rm -f Main.vm; JackCompiler.py; vimdiff Main{,X}.vm
popd
pushd ~/Desktop/nand2tetris/projects/11/ConvertToBin/
rm -f Main.vm; JackCompiler.py; vimdiff Main{,X}.vm
popd
pushd ~/Desktop/nand2tetris/projects/11/Square/
rm -f Main.vm Square.vm SquareGame.vm; JackCompiler.py
vimdiff Main{,X}.vm
vimdiff Square{,X}.vm
vimdiff SquareGame{,X}.vm
popd
pushd ~/Desktop/nand2tetris/projects/11/Average/
rm -f Main.vm; JackCompiler.py; vimdiff Main{,X}.vm
popd
