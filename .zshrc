ZSHD_PATH=$HOME/.dotconfig/dotfiles/zsh.d

source ${ZSHD_PATH}/zplug.zsh
source ${ZSHD_PATH}/os.zsh
source ${ZSHD_PATH}/command.zsh
source ${ZSHD_PATH}/config.zsh

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
