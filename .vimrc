" vim-only, neovim has its own config
set nocompatible
set background=dark
syntax enable
filetype plugin indent on

" color count is not rgb support, truecolor terminals commonly advertise 256
if exists('+termguicolors')
    if !empty($TMUX) && $DOTFILES_TMUX_COLORS =~# '^\%(truecolor\|256\|ansi\)$'
        let &termguicolors = $DOTFILES_TMUX_COLORS ==# 'truecolor'
    elseif $COLORTERM =~# '^\%(truecolor\|24bit\)$'
        set termguicolors
    elseif $TERM =~# '^\%(dumb\|linux\|screen\|vt\|cons\|ansi\)'
        set notermguicolors
    endif
endif

if (exists('+termguicolors') && &termguicolors) || &t_Co >= 256
    colorscheme catppuccin_mocha
endif

set showmode laststatus=2
set expandtab tabstop=4 softtabstop=4 shiftwidth=4
set autoindent
set virtualedit=all
set iskeyword+=_,$,@-@,%,#,-
set showmatch matchtime=3
set scrolloff=6
set hidden
set backspace=indent,eol,start
set incsearch hlsearch ignorecase smartcase
set splitbelow splitright
set noerrorbells novisualbell
if exists('+belloff')
    set belloff=all
endif

" display-wrap prose
function! s:ProseWrap() abort
    let prose = index(['text', 'markdown', 'rst', 'asciidoc', 'gitcommit', 'mail'], &filetype) >= 0
    let &l:linebreak = prose
    let &l:breakindent = prose
    if prose
        setlocal wrap
    endif
endfunction

augroup dotfiles_wrapping
    autocmd!
    autocmd FileType,BufWinEnter * call s:ProseWrap()
augroup END
if !has('nvim')
    set t_vb=
endif
