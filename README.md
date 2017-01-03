# dotfiles
[![Build Status](https://travis-ci.org/jtwp470/dotfiles.svg)](https://travis-ci.org/jtwp470/dotfiles)
[![License](http://img.shields.io/:license-mit-blue.svg)](http://jtwp470.mit-license.org/)
![platform-osx](https://img.shields.io/badge/platform-osx-blue.svg?style=flat-square)
![platform-linux](https://img.shields.io/badge/platform-Linux-blue.svg?style=flat-square)

This is a repository with my configuration files, those that in Linux/OSX normally are those files under the ```{$HOME}``` directory that are hidden and preceded by a dot, AKA, **dotfiles**.

# IMPORTANT NOTICE
I decide to use [spacemacs](http://spacemacs.org). I don't support my [dotemacs](https://github.com/dotemacs) and merge to this repository.

## How to setup

The easiest way to install the dotfiles is open to up a terminal, type the installation command below:

```bash
$ curl -L http://dot.jtwp470.net | python
```

else:

```bash
$ curl -L https://raw.githubusercontent.com/jtwp470/dotfiles/master/install.py | python
```

Incidentally, ```install.py all``` will perform the following tasks.

1. Download this repository. (```install.py download```)
2. Deploy (ex. create symlink) (```install.py deploy```)
3. Initialize (```install.py init```)

## Try my confs
Try my conf to use Docker container.

1. Install [docker](https://docs.docker.com/engine/installation/)
2. Clone this repository and build container like this:
   ```bash
   git clone https://github.com/jtwp470/dotfiles
   cd dotfiles
   ```

3. Pull or build container. ([Docker hub repo](https://hub.docker.com/r/jtwp470/dotfiles/))
   Pull container like this: (**recommended**)
   ```bash
   docker pull jtwp470/dotfiles
   ```
   or you want to build container, like this:
   ```bash
   docker build -t jtwp470/dotfiles .
   ```

4. Run container and try.
   ```bash
   docker run -ti -v $(pwd):/root/.dotconfig/dotfiles jtwp470/dotfiles:latest /bin/bash
   # In container
   cd /root/.dotconfig/dotfiles  # Move to dotfiles directory
   # You DON'T get repository from GitHub
   python install.py deploy
   python install.py init
   python install.py test
   # Run test
   ```

## Requirements

* zsh  (>= 5.0.2)
* tmux
* Vim 7.4
* OS X 10.9 or higher
* Ubuntu 14.04 or higher
* iTerm2 (in OSX)
* Powerline fonts
* Emacs 25

## Spacemacs
Spacemacsはキーバインドを hybrid にして使っています．こうすることで<keyboard>SPC</keyboard>の恩恵を受けつつ，インサートモード時はEmacsのキーバインドを最大限利用できるようになりました．

## Feature
### tmux

* Enables copying to system clipboard in tmux. Works on Linux and OSX.  [tmux yank](https://github.com/tmux-plugins/tmux-yank)
If you use Linux to install,  ```xsel```, else if you use OS X to install ```reatach-to-user-namespace```. **Windows** NOT SUPPORT.

### Vim

* Vim package manager **dein.vim** [dein.vim](https://github.com/Shougo/dein.vim)

### Powerline Fonts
Please install the fonts patched Powerline. If you get pre-patched fonts, go to [Powerline fonts](https://github.com/powerline/fonts).
If you use OS X and Homebrew, you can install using `brew` like this:

```bash
$ brew tap sanemat/fonts
$ brew install ricty --powerline --vim-powerline
```

## GitConfig
コミット時の名前やメールアドレスなどは各環境に依存するため, dotfilesでの管理をとりやめました.
各環境で利用する際は, `~/.gitconfig.local` に追記する形で利用してください.

## Reference

* [The B4B4R07's dotfiles](https://github.com/b4b4r07/dotfiles)
