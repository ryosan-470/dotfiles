# dotfiles
[![Build Status](https://travis-ci.org/jtwp470/dotfiles.svg)](https://travis-ci.org/jtwp470/dotfiles)
[![License](http://img.shields.io/:license-mit-blue.svg)](http://jtwp470.mit-license.org/)

This is a repository with my configuration files, those that in Linux/OSX normally are those files under the ```{$HOME}``` directory that are hidden and preceded by a dot, AKA, **dotfiles**.


## How to setup

The easiest way to install the dotfiles is open to up a terminal, type the installation command below:

```
$ wget https://https://raw.githubusercontent.com/jtwp470/dotfiles/development/install.py
$ python3 install.py all
```

Use shortest address is bellow:

```
$ wget http://urx.nu/itNN -O install.py
$ python3 install.py all
```

Incidentally, ```install.py all``` will perform the following tasks.

1. Download this repository. (```install.py download```)
2. Deploy (ex. create symlink) (```install.py deploy```)
3. Initialize (```install.py init```)

## Requirements

* zsh  (>= 5.0.2)
* tmux (>= 1.8)
* Vim 7.4
* OS X Yosemite (MacBook Air) or Ubuntu 14.04 LTS

## How would you like to use Emacs?
I am a Emacser. I have my configuration for Emacs. Please refer to [dotemacs](https://github.com/jtwp470/dotemacs)

## Feature
### tmux
* Enables copying to system clipboard in tmux. Works on Linux and OSX.
[tmux yank](https://github.com/tmux-plugins/tmux-yank)

Linux needs ```xsel```, OS X needs ```reatach-to-user-namespace```
* tmux status bar looks like vim-powerline. [tmux-powerline](https://github.com/erikw/tmux-powerline)

### Vim
* Vim package manager **NeoBundle** [NeoBundle](https://github.com/Shougo/neobundle.vim)

## Reference

* [The B4B4R07's dotfiles](https://github.com/b4b4r07/dotfiles)
