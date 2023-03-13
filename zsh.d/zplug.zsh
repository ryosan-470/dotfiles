# When there is NOT ~/.zplug, do to install
if [[ ! -d ~/.zplug ]]; then
    git clone https://github.com/zplug/zplug ~/.zplug
    source ~/.zplug/init.zsh && zplug update
fi
source ~/.zplug/init.zsh

# zplug の設定まとめ
zplug 'zplug/zplug', hook-build:'zplug --self-manage'  # zplug under zplug
## Tools
zplug "plugins/asdf", from:oh-my-zsh, if:"which asdf"
zplug "plugins/aws", from:oh-my-zsh, if:"which aws"
zplug "plugins/brew", from:oh-my-zsh, if:"which brew"
zplug "plugins/git", from:oh-my-zsh
zplug "plugins/git-extras", from:oh-my-zsh
zplug "plugins/pip", from:oh-my-zsh
zplug "plugins/docker", from:oh-my-zsh, if:"which docker"
zplug "plugins/docker-compose", from:oh-my-zsh, if:"which docker-compose"
zplug "plugins/macos", from:oh-my-zsh, if:"[[ `uname` == \"Darwin\" ]]"

## Utilities
zplug "plugins/common-aliases", from:oh-my-zsh

# lib周りの読み込み順序はかなり重要
zplug "lib/completion", from:oh-my-zsh
zplug "lib/functions", from:oh-my-zsh
zplug "lib/keybindings", from:oh-my-zsh
zplug "lib/history", from:oh-my-zsh
zplug "lib/misc", from:oh-my-zsh
zplug "zsh-users/zsh-completions"
zplug "zsh-users/zsh-autosuggestions"
# 読み込み順序を設定する
# 例: "zsh-syntax-highlighting" は compinit の前に読み込まれる必要がある
# （2 以上は compinit 後に読み込まれるようになる）
zplug "zsh-users/zsh-syntax-highlighting", defer:2
# substring-search はsyntax highlightingより後に呼び出す
zplug "zsh-users/zsh-history-substring-search", defer:2
zplug "b4b4r07/enhancd", use:init.sh  # ターミナルの移動をいい感じにしてくれる
# テーマファイルとして読み込む
zplug "zimfw/asciiship", as:theme

# 未インストール項目をインストールする
if ! zplug check --verbose; then
    printf "Install? [y/N]: "
    if read -q; then
        echo; zplug install
    fi
fi

# コマンドをリンクして、PATH に追加し、プラグインは読み込む
zplug load --verbose
