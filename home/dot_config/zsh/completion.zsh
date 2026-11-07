# 補完系のコマンドを追加する
# Homebrew のデフォルトの ZSH のパスを読み込む
if (($+commands[brew])); then
  homebrew_zsh_completion_path=$(brew --prefix)/share/zsh/site-functions
  if [ -e ${homebrew_zsh_completion_path} ]; then
    fpath=($homebrew_zsh_completion_path $fpath)
  fi
fi

# 補完システムを手動で初期化（Zimの補完モジュールを無効にしたため）
autoload -Uz compinit
compinit -i

# op コマンドの補完を有効にする
# https://developer.1password.com/docs/cli/reference/commands/completion
# 遅延ローディング
if (($+commands[op])); then
  function _op() {
    unfunction "$0"
    eval "$(op completion zsh)"
    $0 "$@"
  }
  compdef _op op
fi

# Docker CLI の補完を有効にする
# 遅延ローディング
if (($+commands[docker])); then
  function _docker() {
    unfunction "$0"
    eval "$(docker completion zsh)"
    $0 "$@"
  }
  compdef _docker docker
fi

# GitHub CLI の補完を有効にする
# 遅延ローディング
if (($+commands[gh])); then
  function _gh() {
    unfunction "$0"
    eval "$(gh completion -s zsh)"
    $0 "$@"
  }
  compdef _gh gh
fi

# uv コマンドの補完を有効にする
# 遅延ローディング
if (($+commands[uv])); then
  function _uv() {
    unfunction "$0"
    eval "$(uv generate-shell-completion zsh)"
    $0 "$@"
  }
  compdef _uv uv
fi

# uvx コマンドの補完を有効にする
# 遅延ローディング
if (($+commands[uvx])); then
  function _uvx() {
    unfunction "$0"
    eval "$(uvx generate-shell-completion zsh)"
    $0 "$@"
  }
  compdef _uvx uvx
fi
