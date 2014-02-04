# Common settings
# Path to your oh-my-zsh configuration.
ZSH=$HOME/.oh-my-zsh

# Set name of the theme to load.
# Look in ~/.oh-my-zsh/themes/
# Optionally, if you set this to "random", it'll load a random theme each
# time that oh-my-zsh is loaded.
ZSH_THEME="ys"
#ZSH_THEME="agnoster"

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

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# theme コマンドで実際にテーマを指定できる
plugins=(git ruby bundler emoji-clock themes)

source $ZSH/oh-my-zsh.sh

########################################
# OS 別の設定
case ${OSTYPE} in
    darwin13.0)
	#For MacBook Air
	;;
    darwin10.0)
	#For iMac of COINS 
	;;
    linux*)
	#For Linux General
	alias open='gnome-open'
	alias pbcopy='xsel --clipboard --input'
	alias pbpaste='xsel --clipboard --output'
	;;
esac

export GREP_OPTIONS='--binary-files=without-match'
# zsh customize
setopt auto_cd
function chpwd() { ls -F }
# # '' を押すと上のディレクトリに移動する git reset --hard HEAD^ に競合
# function cdup() {
# echo
# cd ..
# zle reset-prompt
# }
# zle -N cdup
# bindkey '\^' cdup
# zaw setting
# search history key bind ''})''})'C-h'
bindkey '^h' zaw-history
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
# zaw
source $HOME/.dotconfig/zaw/zaw.zsh

# if .zshrc is newer than .zshrc.zwc, do zcompile
if [ ~/.zshrc -nt ~/.zshrc.zwc ]; then
   zcompile ~/.zshrc
fi

############################################################################
##    Alias
############################################################################
alias e='emacs -nw'
alias ec='emacsclient -nw -a ""'
alias kill-emacs="emacsclient -e '(kill-emacs)'"
alias v=vim
alias g=git
alias s='source ~/.zshrc'
alias t=tmux
alias tr='tmux source-file ~/.tmux.conf'
alias gpl='git pull origin master'
alias gps='git push origin master'
alias gf='git fetch origin master'
alias j=java
alias jc=javac
alias ll='ls -lh'
alias p2=python
alias p=python3
alias ip=ipython
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
# emacs-restart C-e
################################################
function emacs-restart(){
    kill-emacs
    emacs --daemon
}
zle -N emacs-restart
bindkey '^e' emacs-restart

################################################
## tmux自動起動
################################################
[[ -z "$TMUX" && ! -z "$PS1" ]] && tmux
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
    esac
}
alias -s {gz,tgz,zip,lzh,bz2,tbz,Z,tar,arj,xz}=extract
