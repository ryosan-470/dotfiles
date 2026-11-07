# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a personal dotfiles repository for managing shell configurations, primarily for zsh, tmux, and Claude Code on macOS and Linux systems. It is managed by [chezmoi](https://www.chezmoi.io/): files under `home/` (see `.chezmoiroot`) are copied to the home directory by `chezmoi apply`. The ghq clone (`~/code/src/github.com/ryosan-470/dotfiles`) itself is the chezmoi source directory.

## Common Commands

### Installation and Setup
- `sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply --source ~/code/src/github.com/ryosan-470/dotfiles ryosan-470` - Initial installation
- `chezmoi diff` - Show what `apply` would change
- `chezmoi apply` - Apply the repository to the home directory
- `chezmoi update` - git pull + apply

### Daily Usage
- `dot update` / `dot diff` - Wrappers for `chezmoi update` / `chezmoi diff`
- `s` - Reload zsh configuration (source ~/.zshrc)

### Editing rules
- Edit files under `home/` in this repository, then run `chezmoi apply`. Do not edit the deployed files in `~` directly.
- chezmoi naming: `dot_` = leading `.`, `executable_` = +x, `private_` = 600/700, `empty_` = deploy empty file, `modify_` = script that rewrites the target, `.tmpl` = Go template.
- Where to put new settings (common / work / machine-local layers), recipes, and Claude settings merge rules: see `docs/chezmoi.md`. Keep it updated when the structure changes.

## Architecture

### Layers (later wins)
1. Common: this public repository (`home/`)
2. Work: `~/.config/work/`, a private repo per employer cloned by `home/.chezmoiexternal.toml.tmpl` when `workRepo` is set at `chezmoi init`. Never put employer names or the repo URL into this public repository.
3. Machine local (unmanaged): `~/.local.zsh`, `~/.gitconfig.local`, `~/.tmux.local.conf`, `~/.claude/CLAUDE.local.md`

### Core Components

**chezmoi configuration** (`home/`):
- `.chezmoi.toml.tmpl` - Prompts `workRepo` on init and sets `sourceDir` to the repo root
- `.chezmoiexternal.toml.tmpl` - Clones tpm and the work repository
- `.chezmoiignore` - Files that exist in the source but are not deployed

**Shell Configuration** (`home/dot_config/zsh/` → `~/.config/zsh/`):
- Modular zsh configuration split into logical files:
  - `alias.zsh` - Custom aliases (g=git, t=tmux, p=python3, etc.)
  - `command.zsh` - Custom functions including `dot()`, `extract()`, file utilities
  - `config.zsh` - Core zsh settings (history, completion, key bindings)
  - `completion.zsh` - Tab completion configurations
  - `os.zsh` - OS-specific settings
  - `zim.zsh` - Zim framework integration

**Dependency Management**:
- `Brewfile` (repo root, not deployed) + `home/.chezmoiscripts/run_onchange_after_brew-bundle.sh.tmpl` run `brew bundle` on macOS when the Brewfile (or `~/.config/work/Brewfile`) changes; skipped when `CI` is set or brew is missing
- Uses Zim framework for zsh (`home/dot_config/zsh/zimrc`)
- Uses TPM (Tmux Plugin Manager) for tmux plugins (tpm itself is cloned by chezmoi external)

**Claude Code Configuration** (`home/dot_claude/` → `~/.claude/`):
- `settings.base.json` - Claude Code global settings (not deployed directly)
- `modify_settings.json.tmpl` - Generates `~/.claude/settings.json` by merging the current file (Claude Code's own changes), `settings.base.json`, and `~/.config/work/claude/settings.json`. Permissions are unioned, hooks are owned by base + work. Requires `jq`.
- `CLAUDE.md` - Claude Code グローバル CLAUDE.md
- `hooks/find-guard.sh`, `statusline.sh` - Referenced from settings as `~/.claude/...`
- Note: `.claude/settings.json` at the repo root is a separate project-level Claude Code config (permissions for this repo)

### 権限ポリシー(settings.json)

`home/dot_claude/settings.base.json` の `permissions` でコマンドの許可/不許可を管理している。方針は以下の通り：

**Claude Code ツール**:
- **Allow(自動許可)**: `Glob`, `Grep`, `Read`, `WebSearch`(読み取り専用で副作用なし)
- **Allow(自動許可)**: `WebFetch` はドメイン指定で許可: `github.com`, `raw.githubusercontent.com`, `docs.anthropic.com`, `developer.mozilla.org`, `pkg.go.dev`
- **Deny(常に拒否)**: `Bash(curl *)`, `Bash(wget *)` (任意のネットワークリクエスト防止)
- Note: `find` は Claude Code の組み込み read-only コマンドのため deny 対象外。`find -exec`/`find -delete` のような危険な形式は Claude Code が常にプロンプトを表示する仕様
- **Deny(常に拒否)**: `Read(**/.env*)`, `Read(~/.aws/credentials)`, `Read(~/.aws/config)`, `Read(~/.ssh/**)`(機密ファイルの保護)
- Note: `grep` は deny から除外済み。単体検索は専用ツール `Grep` を使い、パイプでの利用(`command | grep`)は都度確認で許可する方針

**gh CLI**:
- **Allow(自動許可)**: 閲覧・参照系コマンド(`view`, `list`, `status`, `diff`, `checks`, `search` など)
- **Ask(都度確認)**: `gh api`, `issue comment`, `pr create/edit/comment/review`
- **Deny(常に拒否)**: 破壊的・不可逆な操作(`delete`, `close`, `merge`, `archive`, `rename` など)、認証・鍵の操作(`auth`, `ssh-key`, `gpg-key`)、リポジトリ設定の変更(`secret`, `variable`)、ワークフロー変更(`workflow enable/disable`)

**git**:
- **Allow(自動許可)**: 閲覧・参照系(`log`, `diff`, `show`, `status`, `branch`, `remote`, `tag`, `stash list`)
- **Ask(都度確認)**: `commit`, `push`
- **Deny(常に拒否)**: 破壊的・復元困難な操作(`push --force/-f`, `reset --hard`, `clean -fd`, `checkout -- .`, `restore`, `rm -rf`)

**brew**:
- **Deny(全操作拒否)**: 全コマンドをブロック

**システム**:
- **Deny(常に拒否)**: `sudo`, `shutdown`(特権昇格・システム停止の防止)

**ファイル操作**:
- **Ask(都度確認)**: `rm`, `mv`(誤削除・誤移動の防止)
- **Deny(常に拒否)**: `rm -rf`(再帰的削除は絶対禁止)

**構文**: 全ルールで非推奨の `:*` サフィックスを廃止し、スペース + `*` 構文に統一

**Customization System**: See "Layers" above. Machine-local files are optional and are not created automatically.

**macOS LaunchAgents** (`home/private_Library/private_LaunchAgents/`):
- `com.ryosan470.cleanup-caches.plist.tmpl` runs `~/.local/bin/cleanup-caches.sh` monthly
- `home/.chezmoiscripts/run_onchange_after_load-launchagents.sh.tmpl` reloads it via `launchctl` when the plist changes
- Keep the `private_` prefix on `Library` directories; otherwise chezmoi chmods `~/Library` to 755
- `Library` and macOS-only scripts are ignored on non-darwin in `home/.chezmoiignore`

### Key Features

**Auto-tmux**: Automatically starts/attaches to tmux sessions when opening terminal (configured in `home/dot_config/zsh/command.zsh`)

**Archive Extraction**: Universal `extract()` function with file association aliases for common archive formats (`.jar` は展開対象外)

**Development Utilities**:
- `run()` function for compiling and executing C/C++/Java files (`run foo.c` のように明示的に呼ぶ。ファイル名だけで実行される suffix alias は廃止。ダウンロードしたファイルの誤実行を防ぐため、実行系の suffix alias は追加しないこと)
- `peco-src` integration with ghq for repository navigation (Ctrl+])
- GPG agent management

## Dependencies

Required commands: chezmoi, tmux, zsh, git, jq
Optional: peco, ghq, resolveip, rtk (`~/.claude/CLAUDE.md` の `@RTK.md` と `rtk hook claude` hook の前提。`RTK.md` は rtk が生成する `~/.claude/RTK.md` で chezmoi 管理外。`rtk init -g` で用意する)

## Claude Interactions

### Language and Communication Guidelines
- `日本語でユーザーには回答するようにすること` - Always respond to users in Japanese