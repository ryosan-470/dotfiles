"" 色の設定
" シンタックスオン（色つける）
syntax on

" 色テーマの指定（おまかせ）
colorscheme darkblue

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
