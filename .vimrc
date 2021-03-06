set nocompatible                  " be iMproved
filetype off                      " required!

"set rtp+=~/.vim/bundle/vundle/
"call vundle#rc()
"let g:vundle_default_git_proto = 'git'

" let Vundle manage Vundle
" required!
"Bundle 'gmarik/vundle'

" My Bundles here:
"
" original repos on github
"Bundle 'altercation/vim-colors-solarized'
"Bundle 'Lokaltog/vim-powerline'
"Bundle 'nvie/vim-flake8'
"Bundle 'scrooloose/syntastic'

filetype plugin indent on         " required!

"not sure about these
syntax on   
set nofoldenable
let g:pymode_rope = 0

" Whitespace
set tabstop=4
set shiftwidth=4
set softtabstop=4
set expandtab

" Sanity ensues
set encoding=utf-8
set scrolloff=3
set autoindent
set showmode
set showcmd
set hidden
set wildmenu
set wildmode=list:longest
set visualbell
set cursorline
set ttyfast
set ruler
set backspace=indent,eol,start
set laststatus=2

" Next/Prev buffers/tabs
map <C-J> :bnext<CR>
map <C-K> :bprev<CR>
map <C-L> :tabn<CR>
map <C-H> :tabp<CR>

" Searching
set hlsearch
set incsearch
set ignorecase
set smartcase

"set mouse=a

" Solarized!
"set t_Co=256
"set background=dark
" let g:solarized_termcolors=256
"let g:solarized_contrast="high"
"let g:soloarized_visibility="high"
"colorscheme solarized

" Powerline
let g:Powerline_symbols='fancy'

" gvim
set guifont=Source\ Code\ Pro\ for\ Powerline\ 10

set nu
imap jj <Esc>
nnoremap ; :
