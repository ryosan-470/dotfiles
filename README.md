# dotfiles
[![test](https://github.com/ryosan-470/dotfiles/workflows/test/badge.svg)](https://github.com/ryosan-470/dotfiles/actions?query=workflow%3Atest)
[![Docker Pulls](https://img.shields.io/docker/pulls/ryosan470/dotfiles.svg?style=flat-square)](https://hub.docker.com/r/ryosan470/dotfiles/)
[![License](http://img.shields.io/:license-mit-blue.svg?style=flat-square)](./LICENSE)
![platform-osx](https://img.shields.io/badge/platform-osx-blue.svg?style=flat-square)
![platform-linux](https://img.shields.io/badge/platform-Linux-blue.svg?style=flat-square)

## How to setup

The easiest way to install the dotfiles is open to up a terminal, type the installation command below:

```console
curl -L https://raw.githubusercontent.com/ryosan-470/dotfiles/master/install.py | python
```

## Update the configuration
Use `dot` command as below:

```bash
$ dot
The dot command is a controller my dotfiles based on CLI
There are common dot commands used in various situations:

update         Update your dotfiles from GitHub (e.g git fetch origin master)
help           Print this message
```

## Homebrew のセットアップについて

macOS では、パッケージの管理に Homebrew を使用しています。
新しい機器を導入する際などは以下のコマンドでセットアップすることができます。

```console
brew bundle
```


## GitConfig
コミット時の名前やメールアドレスなどは各環境に依存するため, dotfilesでの管理をとりやめました.
各環境で利用する際は, `~/.gitconfig.local` に追記する形で利用してください.

## Reference

* [The B4B4R07's dotfiles](https://github.com/b4b4r07/dotfiles)
