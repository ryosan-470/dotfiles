# environment settings
export PATH=/usr/local/bin:$HOME/bin:$PATH
export EDITOR="emacs -nw"
export PAGER=lv
export LANG=ja_JP.UTF-8
export LC_ALL=ja_JP.UTF-8

################################################################################
## Qiita: tmuxのウィンドウ名をsshでつないでいるときは接続先ホストにする
################################################################################
function ssh() {
    if [[ -n $(printenv TMUX) ]]
    then
        local window_name=$(tmux display -p '#{window_name}')
        tmux rename-window -- "$@[-1]" # zsh specified
        # tmux rename-window -- "${!#}" # for bash
        command ssh $@
        tmux rename-window $window_name
    else
        command ssh $@
    fi
}
