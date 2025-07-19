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
