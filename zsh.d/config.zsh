autoload colors && colors

bindkey -e # キーバインドをEmacs風にする
# zsh customize
# プロンプトにカレントブランチを表示する
setopt prompt_subst
setopt auto_cd
function chpwd() { ls --color=auto }
# historyの共有
setopt share_history
# ヒストリに追加されるコマンド行が古いものと同じなら古いものを削除
setopt hist_ignore_all_dups
# スペースで始まるコマンド行はヒストリリストから削除
setopt hist_ignore_space
# ヒストリを呼び出してから実行する間に一旦編集可能
setopt hist_verify
# 余分な空白は詰めて記録
setopt hist_reduce_blanks
# 古いコマンドと同じものは無視
setopt hist_save_no_dups
# historyコマンドは履歴に登録しない
setopt hist_no_store
# 補完時にヒストリを自動的に展開
setopt hist_expand
# 履歴をインクリメンタルに追加
setopt inc_append_history
# zsh 拡張glob
setopt extendedglob
# killコマンドを便利に
zstyle ':completion:*:processes' command "ps -u $USER -o pid,stat,%cpu,%mem,cputime,command"
# case insensitive
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
# コマンドラインを任意のテキストエディタで編集する
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^xe' edit-command-line
