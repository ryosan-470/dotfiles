# dotfiles
[![Build Status](https://travis-ci.org/jtwp470/dotfiles.svg)](https://travis-ci.org/jtwp470/dotfiles)
[![License](http://img.shields.io/:license-mit-blue.svg)](http://jtwp470.mit-license.org/)
![platform-osx](https://img.shields.io/badge/platform-osx-blue.svg?style=flat-square)
![platform-linux](https://img.shields.io/badge/platform-Linux-blue.svg?style=flat-square)

This is a repository with my configuration files, those that in Linux/OSX normally are those files under the ```{$HOME}``` directory that are hidden and preceded by a dot, AKA, **dotfiles**.


## How to setup

The easiest way to install the dotfiles is open to up a terminal, type the installation command below:

If you can use Python 3,

```bash
$ curl -fsSL http://dot.jtwp470.net | python3
```

else:

```bash
$ curl -fsSL http://dot.jtwp470.net > install.py && python install.py all
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
   docker run -i -t --rm jtwp470/dotfiles:latest -v ${PWD}:/root/.dotconfig/dotfiles /bin/sh -c "cd /root/.dotconfig/dotfiles; python install.py all"
   ```

## Requirements

* zsh  (>= 5.0.2)
* tmux
* Vim 7.4
* OS X 10.9 or higher
* Ubuntu 14.04 or higher
* iTerm2 (in OSX)
* Powerline fonts

## Atom
最近になってようやく[Atom](https://atom.io)を使い始めました.今のところはEmacsと併用使いですがこれからどうなるかわかりません.
各環境で適当にAtomをインストールし, いい感じに使うしかなさそうです.

* Atomにインストールしているパッケージ一覧を吐き出す.
  ```bash
  $ apm list --installed --bare > atom-packages.txt
  ```
* Atomのパッケージ一覧からインストールする
  ```bash
  $ apm install --packages-file atom-packages.txt
  ```

## How would you like to use Emacs?
I am a Emacser. I have my configuration for Emacs. Please refer to [dotemacs](https://github.com/jtwp470/dotemacs)

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

## Reference

* [The B4B4R07's dotfiles](https://github.com/b4b4r07/dotfiles)
