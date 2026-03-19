# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a personal dotfiles repository for managing shell configurations, primarily for zsh, tmux, vim, and Karabiner on macOS and Linux systems. The repository follows a symlink-based deployment strategy where configuration files are linked from `~/.dotconfig/dotfiles` to the home directory.

## Common Commands

### Installation and Setup
- `curl -L https://raw.githubusercontent.com/ryosan-470/dotfiles/master/install.py | python` - Initial installation
- `python install.py all` - Download, deploy and initialize dotfiles
- `python install.py deploy` - Create symlinks to home directory
- `python install.py init` - Run initialization scripts
- `python install.py test` - Test that all symlinks exist
- `python install.py clean` - Remove all symlinks

### Daily Usage
- `dot` - Show help for dotfiles management
- `dot update` - Update dotfiles from GitHub (git pull origin master)
- `s` - Reload zsh configuration (source ~/.zshrc)

## Architecture

### Core Components

**Installation System** (`install.py`):
- Python-based installer that handles cloning, symlinking, and initialization
- Supports macOS and Linux platforms
- Creates symlinks for all dotfiles except excluded ones (.git, .github, etc.)
- Location: Repository clones to `~/.dotconfig/dotfiles`

**Shell Configuration** (`zsh.d/`):
- Modular zsh configuration split into logical files:
  - `alias.zsh` - Custom aliases (g=git, t=tmux, p=python3, etc.)
  - `command.zsh` - Custom functions including `dot()`, `extract()`, file utilities
  - `config.zsh` - Core zsh settings (history, completion, key bindings)
  - `completion.zsh` - Tab completion configurations
  - `os.zsh` - OS-specific settings
  - `zim.zsh` - Zim framework integration

**Dependency Management**:
- Uses Zim framework for zsh (`zimrc` configuration)
- Uses TPM (Tmux Plugin Manager) for tmux plugins
- Initialization scripts in `init/` directory handle setup

**Claude Code Configuration** (`claude/`):
- `claude/settings.json` - Claude Code global settings template, symlinked to `~/.claude/settings.json`
- `claude/CLAUDE.md` - Claude Code グローバル CLAUDE.md, symlinked to `~/.claude/CLAUDE.md`
- Note: `.claude/settings.local.json` is a separate project-level Claude Code config (permissions for this repo)

### 権限ポリシー(settings.json)

`claude/settings.json` の `permissions` でコマンドの許可/不許可を管理している。方針は以下の通り：

**Claude Code ツール**:
- **Allow(自動許可)**: `Glob`, `Grep`, `Read`, `WebSearch`(読み取り専用で副作用なし)
- **Allow(自動許可)**: `WebFetch` はドメイン指定で許可: `github.com`, `raw.githubusercontent.com`, `docs.anthropic.com`, `developer.mozilla.org`, `pkg.go.dev`
- **Deny(常に拒否)**: `Bash(find:*)` (専用ツール `Glob` を使うため)、`Bash(curl:*)`, `Bash(wget:*)` (任意のネットワークリクエスト防止)
- Note: `grep` は deny から除外済み。単体検索は専用ツール `Grep` を使い、パイプでの利用(`command | grep`)は都度確認で許可する方針

**gh CLI**:
- **Allow(自動許可)**: 閲覧・参照系コマンド(`view`, `list`, `status`, `diff`, `checks`, `search` など)
- **Ask(都度確認)**: `issue comment`, `pr create/edit/comment/review`
- **Deny(常に拒否)**: 破壊的・不可逆な操作(`delete`, `close`, `merge`, `archive`, `rename` など)、認証・鍵の操作(`auth`, `ssh-key`, `gpg-key`)、リポジトリ設定の変更(`secret`, `variable`)、`gh api`(任意のAPI呼び出しで他の制御をバイパスできるため)

**git**:
- **Allow(自動許可)**: 閲覧・参照系(`log`, `diff`, `show`, `status`, `branch`, `remote`, `tag`, `stash list`)
- **Ask(都度確認)**: `commit`, `push`
- **Deny(常に拒否)**: 破壊的・復元困難な操作(`push --force/-f`, `reset --hard`, `clean -fd`, `checkout -- .`, `rm -rf`)

**brew**:
- **Deny(全操作拒否)**: `brew:*` で全コマンドをブロック

**システム**:
- **Deny(常に拒否)**: `sudo`, `shutdown`(特権昇格・システム停止の防止)

**ファイル操作**:
- **Ask(都度確認)**: `rm`, `mv`(誤削除・誤移動の防止)
- **Deny(常に拒否)**: `rm -rf`(再帰的削除は絶対禁止)

**Customization System**:
- `~/.local.zsh` - User-specific zsh customizations
- `~/.gitconfig.local` - User-specific git configuration
- Files are created automatically during initialization

### Key Features

**Auto-tmux**: Automatically starts/attaches to tmux sessions when opening terminal (configured in `zsh.d/command.zsh:114-121`)

**Archive Extraction**: Universal `extract()` function with file association aliases for common archive formats

**Development Utilities**:
- `run()` function for compiling and executing C/C++/Java files
- `peco-src` integration with ghq for repository navigation (Ctrl+])
- GPG agent management

## Dependencies

Required commands: tmux, zsh, vim, git
Optional: peco, ghq, resolveip

The installer validates these dependencies before proceeding.

## Claude Interactions

### Language and Communication Guidelines
- `日本語でユーザーには回答するようにすること` - Always respond to users in Japanese