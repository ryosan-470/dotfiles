#
# alias.zsh
#
# @author Ryosuke Sato <tango@jtwp470.net>
#
#
alias e='emacs -nw'
alias ec='emacsclient -nw'
alias kill-emacs="emacsclient -e '(kill-emacs)'"
alias v=vim
alias g=git
alias s='source ~/.zshrc'
alias tr='tmux source-file ~/.tmux.conf'
alias gpl='git pull origin master'
alias gps='git push origin master'
alias gf='git fetch origin master'
alias j=java
alias jc=javac

# Functions
# Enter を押すと ls or git status
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
# emacs-restart C-e
function emacs-restart(){
    kill-emacs
    emacs --daemon
}
zle -N emacs-restart
bindkey '^e' emacs-restart

## tmux自動起動
# http://d.hatena.ne.jp/tyru/20100828/run_tmux_or_screen_at_shell_startup
is_screen_running() {
    # tscreen also uses this varariable.
    [ ! -z "$WINDOW" ]
}
is_tmux_runnning() {
    [ ! -z "$TMUX" ]
}
is_screen_or_tmux_running() {
    is_screen_running || is_tmux_runnning
}
shell_has_started_interactively() {
    [ ! -z "$PS1" ]
}
resolve_alias() {
    cmd="$1"
    while \
        whence "$cmd" >/dev/null 2>/dev/null \
        && [ "$(whence "$cmd")" != "$cmd" ]
    do
        cmd=$(whence "$cmd")
    done
    echo "$cmd"
}
if ! is_screen_or_tmux_running && shell_has_started_interactively; then
    for cmd in tmux tscreen screen; do
        if whence $cmd >/dev/null 2>/dev/null; then
            $(resolve_alias "$cmd")
            break
        fi
    done
fi
