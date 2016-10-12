ZSHD_PATH=$HOME/.dotconfig/dotfiles/zsh.d
# Common settings
# Path to your oh-my-zsh configuration.
ZSH=$HOME/.oh-my-zsh

# Set name of the theme to load.
# Look in ~/.oh-my-zsh/themes/
# Optionally, if you set this to "random", it'll load a random theme each
# time that oh-my-zsh is loaded.
# ZSH_THEME="ys"
# ZSH_THEME="agnoster"

# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

# Set to this to use case-sensitive completion
# CASE_SENSITIVE="true"

# Uncomment this to disable bi-weekly auto-update checks
# DISABLE_AUTO_UPDATE="true"

# Uncomment to change how often before auto-updates occur? (in days)
# export UPDATE_ZSH_DAYS=13

# Uncomment following line if you want to disable colors in ls
# DISABLE_LS_COLORS="true"

# Uncomment following line if you want to disable autosetting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment following line if you want to disable command autocorrection
# DISABLE_CORRECTION="true"
# Uncomment following line if you want red dots to be displayed while waiting for completion
# COMPLETION_WAITING_DOTS="true"

# Uncomment following line if you want to disable marking untracked files under
# VCS as dirty. This makes repository status check for large repositories much,
# much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

source $ZSH/oh-my-zsh.sh
source ~/.dotconfig/dotfiles/zsh.d/themes.zsh
########################################
# OS 別の設定

case `uname` in
    "Darwin")
        #For MacBook Air
        plugins=(git ruby cp pip brew osx python git-extras brew-cask vagrant docker go heroku nmap perl scala)
        alias update="brew -v update && brew -v upgrade --all"
        ;;
    "Linux")
        #For Linux General
        alias open='gnome-open'
        alias pbcopy='xsel --clipboard --input'
        alias pbpaste='xsel --clipboard --output'
        plugins=(git ruby bundler emoji-clock themes cp pip python git-extras autojump)
        local UPDATE_CMD=""
        if [ -e /etc/lsb-release ]; then
            # Ubuntu
            UPDATE_CMD="sudo apt-get update && sudo apt-get upgrade"
        elif [ -e /etc/arch-release ]; then
            # ArchLinux
            UPDATE_CMD="sudo pacman -Syu"
        elif [ -e /etc/redhat-release ]; then
            # CentOS
            UPDATE_CMD="sudo yum update";
        elif cat /etc/os-release | grep Raspbian >/dev/null 2>&1 ; then
            # Raspbian
            UPDATE_CMD="sudo apt-get update && sudo apt-get upgrade"
        else
            UPDATE_CMD="echo 'Not support your using distribution.'"
        fi
        alias update=${UPDATE_CMD}
        ;;
esac
# OS固有の設定を書くファイル(ignoreされている)
source $HOME/.local.zsh
bindkey -e # キーバインドをEmacs風にする
export GREP_OPTIONS='--binary-files=without-match'
# zsh customize
setopt auto_cd
function chpwd() { ls -F }
# history search
bindkey '^P' history-beginning-search-backward
bindkey '^N' history-beginning-search-forward
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
# インクリメンタルからの検索
bindkey "^R" history-incremental-search-backward
bindkey "^S" history-incremental-search-forward
# zsh 拡張glob
setopt extendedglob
# killコマンドを便利に
zstyle ':completion:*:processes' command "ps -u $USER -o pid,stat,%cpu,%mem,cputime,command"
# コマンドラインを任意のテキストエディタで編集する
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^xe' edit-command-line
# if .zshrc is newer than .zshrc.zwc, do zcompile
if [ ! -f ~/.zshrc.zwc -o ~/.zshrc -nt ~/.zshrc.zwc ];then
    zcompile ~/.zshrc
fi

############################################################################
##    Alias
############################################################################
alias e='emacs -nw'
alias ec='emacsclient -nw -a ""'
alias ecw='emacsclient -c'
alias kill-emacs="emacsclient -e '(kill-emacs)'"
alias v=vim
alias g=git
alias s='source ~/.zshrc'
alias t=tmux
alias tr='tmux source-file ~/.tmux.conf'
alias ta="tmux attach -t 0"
alias td="tmux detach"
alias tl="tmux ls"
alias gpl='git pull origin master'
alias gps='git push origin master'
alias gf='git fetch origin master'
alias gss='git status -s'
alias gc='git commit'
alias gcm='git commit -m'
alias gcv='git commit -v'
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
alias el2elc="emacs -batch -f batch-byte-compile"
# alias pip-update="pip list -o | awk '{ print $1 }' | xargs pip install -U"
# alias pip3-update="pip3 list -o | awk '{ print $1 }' | xargs pip3 install -U"
alias ru="ruby"
################################################
# Functions
################################################
################################################
# if you press enter key, do ls or git status
################################################
function do_enter() {
    if [ -n "$BUFFER" ]; then
        zle accept-line
        return 0
    fi
    echo
    ls
    # ls_abbrev
    if [ "$(git rev-parse --is-inside-work-tree 2> /dev/null)" = 'true' ]; then
        echo
        echo -e "\e[0;33m--- git status ---\e[0m"
        git status -sb
    fi
    zle reset-prompt
    return 0
}
zle -N do_enter
bindkey '^m' do_enter
################################################
# emacs-restart C-r e
################################################
function emacs-restart(){
    emacsclient -e '(kill-emacs)' && emacsclient -nw -a ""
}
zle -N emacs-restart
bindkey '^re' emacs-restart
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
################################################
# hoge.tar.gz を ./hoge.tar.gz で展開
################################################
function extract() {
    case $1 in
        *.tar.gz|*.tgz) tar xzvf $1 ;;
        *.tar.xz) tar Jxvf $1 ;;
        *.zip) unzip $1 ;;
        *.lzh) lha e $1 ;;
        *.tar.bz2|*.tbz) tar xjvf $1 ;;
        *.tar.Z) tar zxvf $1 ;;
        *.gz) gzip -dc $1 ;;
        *.bz2) bzip2 -dc $1 ;;
        *.Z) uncompress $1 ;;
        *.tar) tar xvf $1 ;;
        *.arj) unarj $1 ;;
        *.rar) unrar $1 ;;
        *.7z) 7z x $1 ;;         # require: p7zip p7zip-full
        *.cab) cabextract $1 ;;  # require: cabextract
        *.jar) java -jar $1 & ;; # Launch java app
    esac
}
alias -s {gz,tgz,zip,lzh,bz2,tbz,Z,tar,arj,xz,rar,7z,cab,jar}=extract
################################################
# rmtex
################################################
function rmtex() {
    NAME=`basename $1 .tex`
    rm $NAME.(aux|log|dvi)
    if [ $? -ne 0 ]; then
        echo "Failed to remove"
    else
        echo "Success!"
    fi
}
################################################
# copy to clipboard
################################################
function c2b() {
    TARGET=$1
    cat $TARGET | pbcopy
}
################################################
# zsh-syntax-highlighting
################################################
if [ -f $ZSHD_PATH/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
    source $ZSHD_PATH/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi
################################################
# git submodule deinit
################################################
function git-submodule-delete() {
    REPO=$1
    git submodule deinit $REPO
    git rm $REPO
}
alias "git submodule delete"=git-submodule-delete
################################################
# bd
################################################
if [ -f $ZSHD_PATH/zsh-bd/bd.zsh ]; then
    source $ZSHD_PATH/zsh-bd/bd.zsh
fi
# zaw
if [ -f $ZSHD_PATH/zaw/zaw.zsh ]; then
    autoload -Uz chpwd_recent_dirs cdr add-zsh-hook
    add-zsh-hook chpwd chpwd_recent_dirs
    zstyle ':chpwd:*' recent-dirs-max 500 # cdrの履歴を保存する個数
    zstyle ':chpwd:*' recent-dirs-default yes
    zstyle ':completion:*' recent-dirs-insert both
    zstyle ':filter-select:highlight' selected fg=black,bg=white,standout
    zstyle ':filter-select' case-insensitive yes
    source $ZSHD_PATH/zaw/zaw.zsh
    bindkey '^@' zaw-cdr
    bindkey '^R' zaw-history
    bindkey '^X^F' zaw-git-files
    bindkey '^X^B' zaw-git-branches
    bindkey '^X^P' zaw-process
    bindkey '^X^A' zaw-tmux
    bindkey '^X^H' zaw-history
fi

source ${ZSHD_PATH}/run.zsh
##################################################
# keydump (RSA key dumped using openssl)
##################################################
function keydump() {
    KEYFILE=$1
    CIPHER=$2
    # public keyを見たい場合はrsa -pubin オプションを使うらしい
    openssl ${CIPHER:='rsa'} -in ${KEYFILE:='id_rsa.pub'} -text -noout
}

# fpath
fpath=(/usr/local/share/zsh/site-functions $fpath)
autoload -U compinit; compinit

# gpg2
if which gpg-agent > /dev/null; then
    pgrep gpg-agent> /dev/null 2>&1 || eval $(gpg-agent --daemon --write-env-file ${HOME}/.gpg-agent-info)
    [ -f ${HOME}/.gpg-agent-info ] && source ${HOME}/.gpg-agent-info
    export GPG_AGENT_INFO
    export GPG_TTY=`tty`
fi
################################################
# peco
################################################
function peco-select-history() {
    local tac
    if which tac > /dev/null; then
        tac="tac"
    else
        tac="tail -r"
    fi
    BUFFER=$(\history -n 1 | \
                    eval $tac | \
                    peco --query "$LBUFFER")
    CURSOR=$#BUFFER
    zle clear-screen
}
zle -N peco-select-history
bindkey '^r' peco-select-history

function peco-cdr () {
    local selected_dir=$(cdr -l | awk '{ print $2 }' | peco)
    if [ -n "$selected_dir" ]; then
        BUFFER="cd ${selected_dir}"
        zle accept-line
    fi
    zle clear-screen
}
zle -N peco-cdr
bindkey '^@' peco-cdr
