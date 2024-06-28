# 補完系のコマンドを追加する
# Homebrew のデフォルトの ZSH のパスを読み込む
if (($+commands[brew])); then
  homebrew_zsh_completion_path=$(brew --prefix)/share/zsh/site-functions
  if [ -e ${homebrew_zsh_completion_path} ]; then
    fpath=($homebrew_zsh_completion_path $fpath)
  fi
fi
