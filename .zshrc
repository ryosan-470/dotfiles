ZSHD_PATH=$HOME/.dotconfig/dotfiles/zsh.d

source ${ZSHD_PATH}/zim.zsh
source ${ZSHD_PATH}/os.zsh
source ${ZSHD_PATH}/command.zsh
source ${ZSHD_PATH}/config.zsh
source ${ZSHD_PATH}/alias.zsh
source ${ZSHD_PATH}/completion.zsh
# OS固有の設定を書くファイル(ignoreされている) zplug load後に必要
# これは最後に読み込むことにする (local.zsh側の方が上書きできる仕様)
source ~/.local.zsh
