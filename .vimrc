"" Delete key が動かない問題対策
set backspace=indent,eol,start
"" 色の設定
set nohlsearch
set cursorline
syntax on
" Vimの色設定
colorscheme elflord 
" colorscheme koehler
"colorscheme molokai
" 背景透過
highlight Normal ctermbg=none
" 現在のカーソルの色をつける
set cursorline
hi Comment ctermfg=103
hi CursorLine term=none cterm=none ctermbg=17 guibg=236
" 検索したときのハイライトをつける
set hlsearch
" 行番号の表示
set number
" 折り返しオフ
set nowrap

"" 補完系（せっかくデフォであるのでいれておく）
" オムニ補完の設定（insertモードでCtrl+oで候補を出す、Ctrl+n Ctrl+pで選択、Ctrl+yで確定）
set omnifunc=pythoncomplete#Complete
set omnifunc=javascriptcomplete#CompleteJS
set omnifunc=htmlcomplete#CompleteTags
set omnifunc=csscomplete#CompleteCSS
set omnifunc=xmlcomplete#CompleteTags
set omnifunc=phpcomplete#CompletePHP

" ステータスラインの設定
set cmdheight=1
set laststatus=2
set statusline=%<%F\ %m%r%h%w%{'['.(&fenc!=''?&fenc:&enc).']['.&ff.']'}%=%l,\ [TYPE=%Y]\ [ASCII=\%03.3b]\ [HEX=\%02.2B]\ %c%V%8P

" Ctrl-L で検索ハイライトを消す
nmap <C-l> <C-l>:nohlsearch<CR>

set tabstop=2 "画面上でタブ文字が占める幅
set shiftwidth=2 "自動インデントでずれる幅
set softtabstop=2 "連続した空白に対してタブキーやバックスペースキーでカーソルが動く幅
set autoindent "改行時に前の行のインデントを継続する
set smartindent "改行時に入力された行の末尾に合わせて次の行のインデントを増減する
set encoding=utf-8
set expandtab "タブ入力を複数の空白入力に置き換える
set ignorecase "検索時に大文字小文字の区別をなくす
" OSのクリップボードをレジスタ指定無しで Yank, Put 出来るようにする
set clipboard=unnamed,unnamedplus
" Note: Skip initialization for vim-tiny or vim-small.
if !1 | finish | endif

if has('vim_starting')
   if &compatible
     set nocompatible               " Be iMproved
   endif

   " Required:
   set runtimepath+=~/.dotconfig/dotfiles/vim.d/bundle/neobundle.vim/
 endif

 " Required:
  call neobundle#begin(expand('~/.dotconfig/dotfiles/vim.d/bundle/'))

 " Let NeoBundle manage NeoBundle
 " Required:
  NeoBundleFetch 'Shougo/neobundle.vim'

 " My Bundles here:
 " Refer to |:NeoBundle-examples|.
 " Note: You don't set neobundle setting in .gvimrc!
	NeoBundle 'altercation/vim-colors-solarized'
	" Vim Powerline
	NeoBundle 'alpaca-tc/alpaca_powertabline'
	NeoBundle 'Lokaltog/powerline', { 'rtp' : 'powerline/bindings/vim'}
	NeoBundle 'Lokaltog/powerline-fontpatcher'
	
  " nginx syntax
  NeoBundle 'vim-scripts/nginx.vim'
  NeoBundle 'tomasr/molokai'
	call neobundle#end()

 " Required:
 filetype plugin indent on

" If there are uninstalled bundles found on startup,
 " this will conveniently prompt you to install them.
 NeoBundleCheck

syntax enable

" Powerline
set laststatus=2
set rtp+=~/.dotconfig/dotfiles/vim.d/bundle/powerline/powerline/bindings/vim
let g:Powerline_symbols = 'fancy'
set noshowmode

set paste " paste時にインデントがずれたりする問題を直す
au BufRead,BufNewFile /etc/nginx/* set ft=nginx " nginx conf syntax highlight

""""""""""""""""""""""""""""""
" 自動的に閉じ括弧を入力
""""""""""""""""""""""""""""""
imap { {}<LEFT>
imap [ []<LEFT>
imap ( ()<LEFT>
""""""""""""""""""""""""""""""
