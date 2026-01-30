# Git branch information for prompt
parse_git_branch() {
    local branch=$(git branch 2>/dev/null | grep '^*' | colrm 1 2)
    if [ -n "$branch" ]; then
        local status=""
        # Check for uncommitted changes
        if ! git diff --quiet 2>/dev/null || ! git diff --cached --quiet 2>/dev/null; then
            status="$"
        fi
        echo " on $branch [$status]"
    fi
}

# Prompt format matching zsh style
# First line: full path + git info
# Second line: $ prompt
export PS1='\[\e[1;36m\]\w\[\e[0m\]\[\e[1;35m\]$(parse_git_branch)\[\e[0m\]\n\[\e[1;36m\]% \[\e[0m\]'

# search through history with up/down arrows
bind '"\e[A": history-search-backward' 2>/dev/null
bind '"\e[B": history-search-forward' 2>/dev/null

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
shopt -s globstar

# load ~/.local.bash if it exists
[[ -f ~/.local.bash ]] && . ~/.local.bash

[[ "$TERM_PROGRAM" == "vscode" ]] && . "$(code --locate-shell-integration-path bash)"
