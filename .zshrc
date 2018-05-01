# When there is NOT ~/.zplug, do to install
if [[ ! -d ~/.zplug ]]; then
    git clone https://github.com/zplug/zplug ~/.zplug
    source ~/.zplug/init.zsh && zplug update
fi
source ~/.zplug/init.zsh

ZSHD_PATH=$HOME/.dotconfig/dotfiles/zsh.d

autoload colors && colors
setopt prompt_subst

zplug 'zplug/zplug', hook-build:'zplug --self-manage'  # zplug under zplug
## Tools
zplug "plugins/git", from:oh-my-zsh
zplug "plugins/git-extras", from:oh-my-zsh
zplug "plugins/pip", from:oh-my-zsh
zplug "plugins/ssh-agent", from:oh-my-zsh
zplug "plugins/docker", from:oh-my-zsh, if:"which docker"
zplug "plugins/docker-compose", from:oh-my-zsh, if:"which docker-compose"
zplug "plugins/vagrant", from:oh-my-zsh, if:"which vagrant"
zplug "plugins/nmap", from:oh-my-zsh, if:"which nmap"
zplug "plugins/aws", from:oh-my-zsh, if:"which aws"
zplug "plugins/heroku", from:oh-my-zsh, if:"which heroku"
zplug "plugins/kubectl", from:oh-my-zsh, if:"which kubectl"
zplug "plugins/kube-ps1", from:oh-my-zsh, if:"which kubectl"
zplug "plugins/helm", from:oh-my-zsh, if:"which helm"

## OSX
zplug "plugins/osx", from:oh-my-zsh, if:"[[ `uname` == \"Darwin\" ]]"

## Utilities
zplug "plugins/common-aliases", from:oh-my-zsh

# lib周りの読み込み順序はかなり重要
zplug "lib/completion", from:oh-my-zsh
zplug "lib/functions", from:oh-my-zsh
zplug "lib/keybindings", from:oh-my-zsh
zplug "lib/history", from:oh-my-zsh
zplug "lib/misc", from:oh-my-zsh
zplug "zsh-users/zsh-completions"
# zplug "zsh-users/zaw"
zplug "zsh-users/zsh-autosuggestions"
# 読み込み順序を設定する
# 例: "zsh-syntax-highlighting" は compinit の前に読み込まれる必要がある
# （2 以上は compinit 後に読み込まれるようになる）
zplug "zsh-users/zsh-syntax-highlighting", defer:2
# substring-search はsyntax highlightingより後に呼び出す
zplug "zsh-users/zsh-history-substring-search", defer:2
zplug "b4b4r07/enhancd", use:init.sh  # ターミナルの移動をいい感じにしてくれる
# 事前に以下を読み込んでおく
[[ `zplug list | grep kube-ps1` ]] && source $ZPLUG_REPOS/robbyrussell/oh-my-zsh/plugins/kube-ps1/kube-ps1.zsh
# テーマファイルとして読み込む
zplug "ryosan-470/zsh-theme", as:theme

## THEME CONFIG
POWERLINE_HIDE_USER_NAME="true"
POWERLINE_SHORT_HOST_NAME="true"
POWERLINE_DISABLE_RPROMPT="true"
POWERLINE_PATH="short"
POWERLINE_DETECT_SSH="true"

# OS別の設定
case `uname` in
    "Darwin")
        alias update="brew -v update && brew -v upgrade"
        alias pbcopy="reattach-to-user-namespace pbcopy"
        ;;
    "Linux")
        #For Linux General
        alias open='gnome-open'
        alias pbcopy='xsel --clipboard --input'
        alias pbpaste='xsel --clipboard --output'
        alias ls='ls --color=auto'
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
        alias dstat-full='dstat -Tclmdrn'
        alias dstat-mem='dstat -Tclm'
        alias dstat-cpu='dstat -Tclr'
        alias dstat-net='dstat -Tclnd'
        alias dstat-disk='dstat -Tcldr'
        ;;
esac

case `uname -m` in
    "x86" | "x86_64")
        zplug "peco/peco", as:command, from:gh-r, frozen:1
        ;;
esac

bindkey -e # キーバインドをEmacs風にする
# zsh customize
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

# ssh-agent plugin https://github.com/robbyrussell/oh-my-zsh/tree/master/plugins/ssh-agent
zstyle :omz:plugins:ssh-agent agent-forwarding on
zstyle :omz:plugins:ssh-agent identities id_rsa id_ed25519
################################################
# Functions
################################################
################################################
# emacs-restart C-r e
################################################
function emacs-restart(){
    emacsclient -e '(kill-emacs)' && emacsclient -nw -a ""
}
zle -N emacs-restart
bindkey '^re' emacs-restart
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
# copy to clipboard
################################################
function c2b() {
    TARGET=$1
    cat $TARGET | pbcopy
}

if zplug check "zsh-users/zsh-history-substring-search"; then
    bindkey '^[[A' history-substring-search-up
    bindkey '^[[B' history-substring-search-down
fi

source ${ZSHD_PATH}/run.zsh

# gpg2
if which gpg-agent > /dev/null; then
    pgrep gpg-agent> /dev/null 2>&1 || eval $(gpg-agent --daemon --write-env-file ${HOME}/.gpg-agent-info)
    [ -f ${HOME}/.gpg-agent-info ] && source ${HOME}/.gpg-agent-info
    export GPG_AGENT_INFO
    export GPG_TTY=`tty`
fi

# load terraform autocomplete
if which terraform > /dev/null; then
    autoload -U +X bashcompinit && bashcompinit

    complete -o nospace -C $(which terraform) terraform
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

function peco-find-file() {
    if git rev-parse 2> /dev/null; then
        source_files=$(git ls-files)
    else
        source_files=$(find . -type f)
    fi
    selected_files=$(echo $source_files | peco --prompt "[find file]")

    BUFFER="${BUFFER}${echo $selected_files | tr '\n' ' '}"
    CURSOR=$#BUFFER
    zle redisplay
}
zle -N peco-find-file
bindkey '^f' peco-find-file

function peco-src () {
    local selected_dir=$(ghq list -p | peco --query "$LBUFFER")
    if [ -n "$selected_dir" ]; then
        BUFFER="cd ${selected_dir}"
        zle accept-line
    fi
    zle clear-screen
}
zle -N peco-src
bindkey '^]' peco-src

bindkey '^F^F' forward-word
bindkey '^B^B' backward-word

function urlencode() {
    echo $1 | nkf -WwMQ | sed -e 's/=/%/g'
}

function urldecode() {
    echo $1 | nkf --url-input
}

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

function dot() {
    ret=$PWD
    help_message=$(cat << DOT
The dot command is a controller my dotfiles based on CLI
There are common dot commands used in various situations:

update         Update your dotfiles from GitHub (e.g git fetch origin master)
help           Print this message
DOT
)
    case $1 in
        update) cd ~/.dotconfig/dotfiles > /dev/null;
                git pull origin master;
                cd $ret > /dev/null;;
        *) echo $help_message;;
    esac
}

function ipinfo() {
    domain=$1
    ip=$(resolveip -s ${domain})
    curl https://ipinfo.io/${ip}
}

function em() {
    emacsclient -n -e "(if (> (length (frame-list)) 1) 't)" 2>/dev/null | grep t &> /dev/null

    if [ "$?" -eq "1" ]; then
        emacsclient -a '' -nqc "$@" &> /dev/null
    else
        emacsclient -nq "$@" &> /dev/null
    fi
}
################################################
## zplug 周りの最終確認
################################################
# 未インストール項目をインストールする
if ! zplug check --verbose; then
    printf "Install? [y/N]: "
    if read -q; then
        echo; zplug install
    fi
fi

# コマンドをリンクして、PATH に追加し、プラグインは読み込む
zplug load --verbose

############################################################################
##    Alias
############################################################################
alias b=bundle
alias v=vim
alias g=git
alias s='source ~/.zshrc'
alias t=tmux
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
alias ru="ruby"
alias chrome="/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome"
alias chrome-canary="/Applications/Google\ Chrome\ Canary.app/Contents/MacOS/Google\ Chrome\ Canary"

################################################
# if you press enter key, do ls or git status
################################################
# ls --color が適用されるために後ろで読み込む
function do_enter() {
    if [ -n "$BUFFER" ]; then
        zle accept-line
        return 0
    fi
    echo
    ls --color=auto
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

# OS固有の設定を書くファイル(ignoreされている) zplug load後に必要
# これは最後に読み込むことにする (local.zsh側の方が上書きできる仕様)
source ~/.local.zsh
