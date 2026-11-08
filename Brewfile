# dotfiles が前提にするツール。macOS で `chezmoi apply` 時に brew bundle で入る
# (run_onchange_after_brew-bundle.sh.tmpl)。private は ~/.config/private/Brewfile に書く。
# ccgate は mise で管理するのでここに書かない。go / uv は現状この Brewfile で管理する。

tap "augani/dory"
tap "stablyai/orca"

# シェル / ターミナル
brew "zsh"
brew "bash"
brew "tmux"
brew "nano"
brew "peco"
brew "ghq"
brew "tig"

# GNU 系ツール (make は gmake として入る。他の g プレフィックス無し版は PATH 調整が必要)
brew "make"
brew "coreutils"
brew "findutils"
brew "gnu-sed"
brew "gnu-tar"
brew "grep"
brew "gawk"

# Git / GitHub
brew "git"
brew "gh"
cask "git-credential-manager"

# クラウド
brew "awscli"

# GPG (署名鍵)
brew "gnupg"

# dotfiles 管理 / ランタイム管理
brew "chezmoi"
brew "mise"

# 言語 / 開発ツール
brew "go"
brew "uv"

# コンテナ (ランタイムは cask "augani/dory/dory")
brew "docker"
brew "docker-compose"
brew "docker-buildx"
brew "docker-credential-helper"

# Claude Code と、その hooks から呼ばれるツール (ccgate は mise で管理)
cask "claude-code@latest"
brew "rtk"

# 1Password
cask "1password"
cask "1password-cli"

# GUI アプリ
cask "ghostty"
cask "karabiner-elements"
cask "scroll-reverser"
cask "augani/dory/dory"
cask "stablyai/orca/orca"
cask "bettertouchtool"
cask "raycast"
cask "codexbar"
cask "hot"

# コミュニケーション / エディタ / メディア
cask "google-chrome"
cask "slack"
cask "discord"
cask "zed"
cask "iina"

# フォント
cask "font-jetbrains-mono"

# Mac App Store (mas)
# LINE (id 539883307) は mas で管理しない: mas 7 は Spotlight の索引に依存するため。
brew "mas"
