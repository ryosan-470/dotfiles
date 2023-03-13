# environment settings
typeset -U path PATH
export BUILDKIT_PROGRESS=plain
export EDITOR=nano
export PAGER=less
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

export GOPATH=$HOME/code
export GOBIN=$GOPATH/bin
export PATH="$GOBIN:$PATH"
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
