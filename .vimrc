" dein.vim ref to http://qiita.com/delphinus35/items/00ff2c0ba972c6e41542
" プラグインが実際にインストールされるディレクトリ
let s:dein_dir = expand('~/.cache/dein')
" dein.vim 本体
let s:dein_repo_dir = s:dein_dir . '/repos/github.com/Shougo/dein.vim'

" dein.vim がなければ github から落としてくる
if &runtimepath !~# '/dein.vim'
  if !isdirectory(s:dein_repo_dir)
    execute '!git clone https://github.com/Shougo/dein.vim' s:dein_repo_dir
  endif
  execute 'set runtimepath^=' . fnamemodify(s:dein_repo_dir, ':p')
endif
" 設定のファイルを保存しているディレクトリ
let g:rc_dir = expand("~/.dotconfig/dotfiles/vim.d")
" 設定開始
" if dein#load_state(s:dein_dir)
  call dein#begin(s:dein_dir)

  " プラグインリストを収めた TOML ファイル
  let s:toml      = g:rc_dir . '/dein.toml'
  let s:lazy_toml = g:rc_dir . '/dein_lazy.toml'

  " TOML を読み込み、キャッシュしておく
  call dein#load_toml(s:toml,      {'lazy': 0})
  call dein#load_toml(s:lazy_toml, {'lazy': 1})

  " 設定終了
  call dein#end()
  " call dein#save_state()
" 1endif

" もし、未インストールものものがあったらインストール
if dein#check_install()
  call dein#install()
endif

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
hi CursorLine term=none cterm=none ctermbg=17 guibg=blue
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

" Ctrl-L で検索ハイライトを消す
nmap <C-l> <C-l>:nohlsearch<CR>

set tabstop=2      "画面上でタブ文字が占める幅
set shiftwidth=4   "自動インデントでずれる幅
set softtabstop=4  "連続した空白に対してタブキーやバックスペースキーでカーソルが動く幅
set autoindent     "改行時に前の行のインデントを継続する
set smartindent    "改行時に入力された行の末尾に合わせて次の行のインデントを増減する
set encoding=utf-8
set expandtab      "タブ入力を複数の空白入力に置き換える
set ignorecase     "検索時に大文字小文字の区別をなくす
set showmatch      "対応するカッコを強調表示する
" OSのクリップボードをレジスタ指定無しで Yank, Put 出来るようにする
set clipboard=unnamed,unnamedplus
set showtabline=2

" ------ For python -------
autocmd FileType python setl smartindent cinwords=if,elif,else,for,while,try,except,finally,def,class
    " 改行時自動インデントする宣言
let python_highlight_all =1 " Python用のシンタックスハイライトを全てONに

set paste " paste時にインデントがずれたりする問題を直す
au BufRead,BufNewFile /etc/nginx/* set ft=nginx " nginx conf syntax highlight

""""""""""""""""""""""""""""""
" 自動的に閉じ括弧を入力
""""""""""""""""""""""""""""""
imap { {}<LEFT>
imap [ []<LEFT>
imap ( ()<LEFT>
""""""""""""""""""""""""""""""
" Like Emacs
" ノーマルモード中にC-eを押すとカーソルを行末に移動し挿入モードとなる
inoremap <C-e> <Esc>$a
inoremap <C-a> <Esc>^a
noremap <C-e> <Esc>$a
noremap <C-a> <Esc>^a

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" vim-airline
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
let g:airline_powerline_fonts = 1
set cmdheight=1
set laststatus=2
