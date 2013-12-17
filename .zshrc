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
plugins=(git ruby bundler emoji-clock)

source $ZSH/oh-my-zsh.sh

# Customize to your needs...
########################################
# General Settings
# Default Editor
export EDITOR="emacs -nw"
# Default encording
export LANG=ja_JP.UTF-8

# OS 別の設定
case ${OSTYPE} in
    darwin13.0)
	#For MacBook Air
	export PATH=$PATH:${HOME}/bin
	alias emacsclient="/Applications/Emacs.app/Contents/MacOS/bin/emacsclient"
	alias vim="/usr/local/Cellar/vim/7.4.052/bin/vim"
	alias git="/usr/local/Cellar/git/1.8.4.3/bin/git"
	alias gcc="/usr/local/bin/gcc"
	;;
    darwin10.0)
	#For iMac of COINS 
	;;
    linux*)
	#For Linux General
	alias open='gnome-open'
	;;
esac

export GREP_OPTIONS='--binary-files=without-match'
# zsh customize
setopt auto_cd
function chpwd() { ls -F }
# '' を押すと上のディレクトリに移動する git reset --hard HEAD^ に競合
# function cdup() {
# echo
# cd ..
# zle reset-prompt
# }
# zle -N cdup
# bindkey '\' cdup
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

# load alias
source $HOME/.dotconfig/dotfiles/.zsh.d/alias.zsh

