" https://vim.fandom.com/wiki/Example_vimrc

if has ('filetype')
  filetype indent plugin on
endif

if has ('syntax')
  syntax on
endif

set hidden
set wildmenu
set showcmd
set hlsearch
set ignorecase
set smartcase
set backspace=indent,eol,start
set autoindent
set nostartofline
set ruler
set laststatus=2
set confirm
set visualbell
set t_vb=

"if has ('mouse')
"  set mouse=a
"endif

set cmdheight=2
set number
set notimeout ttimeout ttimeoutlen=200
set pastetoggle=<F11>

set shiftwidth=2
set tabstop=2
set expandtab

