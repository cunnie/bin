" show matching brackets as they are inserted
set showmatch
set ignorecase
set sw=4
" 2007-11-27 setting tabstop is bad form; use softabstop under vim instead.
" set ts=4
" set autoindent
set ai
" display cursor's line/column
set ruler
" display the command state
set showmode

map  T  k
map  S  j
map  Q   i
map  P   x
map  L   O
map  M   dd
map  K   D
map  J   DjdG$
map      {gq}j
map  x   :set fo=tcrq
map! A  ka
map! D  ha
map! C  la
map! B  ja
map! L  
map! Q  
map! R  
