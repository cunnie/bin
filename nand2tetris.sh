#!/bin/bash
set -eu

pushd ~/Desktop/nand2tetris/projects/11/Seven
rm Main.vm; JackCompiler.py Main.jack; vimdiff Main{,X}.vm
popd
pushd ~/Desktop/nand2tetris/projects/11/ConvertToBin/
rm Main.vm; JackCompiler.py Main.jack; vimdiff Main{,X}.vm
popd
pushd ~/Desktop/nand2tetris/projects/11/Square/
rm Main.vm Squqre.vm SquareGame.vm
JackCompiler.py
vimdiff Main{,X}.vm
vimdiff Square{,X}.vm
vimdiff SquareGame{,X}.vm
popd
