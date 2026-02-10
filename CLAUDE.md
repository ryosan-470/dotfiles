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
- Note: `.claude/settings.local.json` is a separate project-level Claude Code config (permissions for this repo)

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