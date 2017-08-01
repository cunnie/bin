source ~/.exrc
set sw=2
set softtabstop=2
" apple has tabstop=4--wtf?
set tabstop=8
" ignore the ignorecase option if the user went to the trouble of
" entering uppercase characters.
set smartcase
" incremental search - shows what was found
set incsearch
" highlights what it found
set hlsearch
" show status line
set laststatus=2
"set statusline=%F%m%r%h%w\ [FORMAT=%{&ff}]\ [TYPE=%Y]\ [ASCII=\%03.3b]\ [HEX=\%02.2B]\ [LEN=%L]\ [POS=%l,%v][%p%%]
set statusline=%F%m%r%h%w\ [HEX=\%02.2B]\ [POS=%l,%v]\ %l/%L\ %p%%
syntax on
" overrides from the Pivotal .vimrc
set nonu nolist nocursorline noshowcmd wrap
"colorscheme default
set background=light
" For all text files set 'textwidth' to 78 characters.
au FileType text setlocal tw=70
" don't display past end of line
set virtualedit=
