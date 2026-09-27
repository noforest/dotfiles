" ======================
" Vimrc inspired by Neovim
" ======================

" correction bug echap lent
set ttimeoutlen=10

" Set the leader key
let mapleader=" " 

" Syntax and colours
syntax on
" set termguicolors           " true colors, disabled for plain Vim 8
set background=dark
set t_Co=256
colorscheme default

" Mouse & clipboard
set mouse=a
set ttymouse=sgr
set clipboard=unnamedplus

" Indentation & tabs
set tabstop=4
set shiftwidth=4
set expandtab
set autoindent
set smartindent
set scrolloff=3

" Encodage
set encoding=utf-8
set fileencoding=utf-8
set fileencodings=utf-8,latin1

" Line numbers
" set number
" set relativenumber

" Subtler relative numbers
hi LineNr guifg=#606060 ctermfg=240
hi CursorLineNr guifg=#ffffff ctermfg=15

" Wrap & break
" Toggle wrap mode with feedback
nnoremap <leader>w :set wrap! \| set wrap?<CR>
set linebreak
set breakindent

" Spell (disable fr if the file is missing)
nnoremap <leader>us :set spell!<CR>
set spelllang=en_us,fr

" Recherche
set ignorecase
set smartcase

" Apparence
" set signcolumn=no
" set laststatus=3
" set noshowmode
set ruler
set showcmd

" Backspace
set backspace=indent,eol,start

" Split windows
set splitright
set splitbelow

" Shell
set shell=/bin/bash

" Clear the search on <Enter>
nnoremap <CR> :nohlsearch<CR>

" Open the file at the position where it was closed
augroup restore_cursor
  autocmd!
  autocmd BufReadPost * if line("'\"") > 0 && line("'\"") <= line("$") | exe "normal! g`\"" | endif
augroup END

" Netrw
let g:netrw_liststyle = 3

" Terminal colors consistency (tmux)
" if exists('$TMUX')
"   set t_ti=
"   set t_te=
"   set t_8f=\\<Esc>[38;2;%lu;%lu;%lum
"   set t_8b=\\<Esc>[48;2;%lu;%lu;%lum
" endif


" Centre the cursor line again after a Ctrl-d / Ctrl-u scroll
nnoremap <C-d> <C-d>zz
nnoremap <C-u> <C-u>zz
