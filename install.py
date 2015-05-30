#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
install.py

The setup script for me. Linux and Mac OSX supports.

Copyright (C) 2015 Ryosuke SATO (jtwp470)


This software is released under the MIT License.

Please refer to http://jtwp470.mit-license.org to know this license.
"""
import argparse
import enum
import os
import sys
import subprocess
import shlex

# ホームディレクトリ上にシンボリックリンクを貼るファイルの名前
DOT_HOME_FILES = (".zshrc", ".zshenv", ".vimrc", ".tmux.conf", ".gitconfig")
HOME = os.path.expanduser("~") + "/"  # User Home Directory
DOTFILES = HOME + ".dotconfig/dotfiles/"


class OS(enum.Enum):
    # Supported distribution
    darwin = "Mac OSX"         # Mac OSX
    windows = "Windows"        # Windows (future support)
    # prefix L_ is Linux
    L_ubuntu = "Ubuntu"        # Ubuntu Linux
    L_debian = "Debian"        # Debian
    L_archlinux = "ArchLinux"  # Arch Linux (future support)

    other = "Other"

    def __str__(self):
        return self.value


def getDistribution():
    # 参考:Linuxのディストリビューションを判別する
    # http://qiita.com/koara-local/items/1377ddb06796ec8c628a
    o = sys.platform
    if o is "darwin":
        return OS.darwin
    elif o is "win32" or o is "cygwin":
        return OS.windows
    else:
        if os.path.exists("/etc/debian_version") or os.path.exists("/etc/debian_release"):
            if os.path.exists("/etc/lsb-release"):
                return OS.L_ubuntu
            else:
                return OS.L_debian
        elif os.path.exists("/etc/arch-release"):
            return OS.L_archlinux
        else:
            return OS.other


def downloading_dotfiles():
    REPOS_URL = "https://github.com/jtwp470/dotfiles.git"
    if os.path.exists(DOTFILES):
        print("File is exists.")
        return

    try:
        # git clone --recursive ${REPO_URL} ${DOTFILES}
        # git  --recursive option is then do submodule init & submodule update
        print("Clone repository")
        commands = "git clone -b development --single-branch {repo} {dst} --recursive".format(
            repo=REPOS_URL, dst=DOTFILES)
        print(commands)
        subprocess.check_call(shlex.split(commands))
        # subprocess.Popen(shlex.split("git clone"))
    except OSError:
        sys.exit("Command not found. Please install git")
    except:
        sys.exit("Occured some error. System exit")
    print("Success Clone repository")


def deploy():
    for dfs in DOT_HOME_FILES:
        src = DOTFILES + dfs
        dst = HOME + dfs

        print("link {src} to {dst}".format(src=src, dst=dst))
        try:
            os.symlink(src, dst)
        except:
            print("symlink exists.")
            pass


def initialize():
    scripts = os.listdir(DOTFILES + "init/")
    scripts.remove("README.md")
    for s in scripts:
        try:
            commands = DOTFILES + "init/" + s
            print(commands)
            subprocess.check_call(shlex.split("bash " + commands))
        except OSError:
            sys.exit("[Error:initialize()]Command not found.")


def test():
    command = "zsh {home}.zshrc".format(home=DOTFILES)
    try:
        subprocess.check_call(shlex.split(command))
    except:
        print("Error")
        sys.exit(1)


def help_description():
    print("help")


def all_run():
    print("Start...")
    downloading_dotfiles()
    print("deploy")
    deploy()
    print("init")
    initialize()


def main():
    parser = argparse.ArgumentParser(description="Setup tool for my dotfiles")
    subparser = parser.add_subparsers()

    parser_download_repo = subparser.add_parser("download", help="Download files from github")
    parser_download_repo.set_defaults(func=downloading_dotfiles)

    parser_deploy = subparser.add_parser("deploy", help="Deploy")
    parser_deploy.set_defaults(func=deploy)

    parser_initialize = subparser.add_parser("init", help="initialize")
    parser_initialize.set_defaults(func=initialize)

    parser_help = subparser.add_parser("help")
    parser_help.set_defaults(func=help_description)

    parser_test = subparser.add_parser("test", help="test section using Travis-CI")
    parser_test.set_defaults(func=test)

    parser_all = subparser.add_parser("all")
    parser_all.set_defaults(func=all_run)
    args = parser.parse_args()

    # オプションがないとき
    if args == argparse.Namespace():
        args = parser.parse_args(["help"])
    args.func()


if __name__ == "__main__":
    main()
