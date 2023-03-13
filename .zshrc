ZSHD_PATH=$HOME/.dotconfig/dotfiles/zsh.d

source ${ZSHD_PATH}/zplug.zsh
source ${ZSHD_PATH}/os.zsh
source ${ZSHD_PATH}/command.zsh

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


################################################
## tmux自動起動
################################################
if [ "$TMUX" = "" ]; then
    tmux attach;

    # detachしてない場合
    if [ $? ]; then
        tmux;
    fi
fi
export GREP_OPTIONS='--color=auto --binary-files=without-match'
alias grep="grep $GREP_OPTIONS"
unset GREP_OPTIONS


############################################################################
## Alias
############################################################################
alias g=git
alias s='source ~/.zshrc'
alias t=tmux
alias gss='git status -s'
alias j=java
alias jc=javac
alias ll='ls -lh'
alias p=python3
alias p2=python2
alias p3=python3
alias ipy=ipython
alias ipy2=ipython2
alias ipy3=ipython3
alias fds='du -h -d 1'
alias gpp=g++
alias ls='ls --color=auto'

# OS固有の設定を書くファイル(ignoreされている) zplug load後に必要
# これは最後に読み込むことにする (local.zsh側の方が上書きできる仕様)
source ~/.local.zsh
