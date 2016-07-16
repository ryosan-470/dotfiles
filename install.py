#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
install.py

The setup script for me. Linux and Mac OSX supports.

Copyright (C) 2015 Ryosuke SATO (jtwp470)


This software is released under the MIT License.

Please refer to http://jtwp470.mit-license.org to know this license.
"""
import argparse
import os
import sys
import subprocess
import shlex
import glob
import shutil


HOME = os.path.expanduser("~")  # User Home Directory
DOTFILES = os.path.join(HOME, ".dotconfig/dotfiles")
ALL_DOTFILES = set(x[len(DOTFILES+"/"):] for x in glob.glob(DOTFILES + "/.*"))
# 除外するファイル名の設定
EXCLUDE_DOTFILES = set([".git", ".git_commit_template.txt",
                        ".gitignore", ".travis.yml", ".gitmodules"])
# ホームディレクトリ上にシンボリックリンクを貼るファイルの名前
DOT_HOME_FILES = ALL_DOTFILES - EXCLUDE_DOTFILES


def run(os_command):
    """os_command is linux command, eg: git clone https://github.com/..."""
    try:
        subprocess.check_call(shlex.split(os_command))
    except subprocess.CalledProcessError as e:
        print("Failure command: "  + os_command)
        return False
    return True


def has_required():
    REQUIRED_COMMAND = ("tmux", "zsh", "vim", "git")
    rest = filter(lambda x: not shutil.which(x), REQUIRED_COMMAND)
    if rest:
        print("Please install the command. " + ", ".join(rest))
        return False
    return True


def downloading_dotfiles(branch="master"):
    REPOS_URL = "https://github.com/jtwp470/dotfiles.git"
    # git clone --recursive ${REPO_URL} ${DOTFILES}
    # git  --recursive option is then do submodule init & submodule update
    print("Clone repository. branch is " + branch)
    command = "git clone -b {branch} {repo} {dst} --recursive".format(
        branch=branch, repo=REPOS_URL, dst=DOTFILES)
    print(command)
    return True if run(command) else False


def deploy():
    for dfs in DOT_HOME_FILES:
        src = os.path.join(DOTFILES, dfs)
        dst = os.path.join(HOME, dfs)

        print("link {src} to {dst}".format(src=src, dst=dst))
        try:
            os.symlink(src, dst)
        except:
            print("symlink exists.")
            pass


def initialize():
    init_directory = os.path.join(DOTFILES, "init")
    scripts = set(glob.glob(init_directory + "/*"))
    scripts = scripts - set([os.path.join(init_directory, "README.md")])
    for s in scripts:
        try:
            print("Run: " + s)
            subprocess.check_call(shlex.split("bash " + s))
        except OSError:
            sys.exit("[Error:initialize()]Command not found.")


def test():
    for x in DOT_HOME_FILES:
        print(x)
        assert os.path.exists(os.path.join(HOME, x))


def help_description():
    print("help")


def install():
    print("Start...")
    print("starting download")
    if os.path.exists(DOTFILES):
        print("File is exists. So skipping git clone")
    else:
        if downloading_dotfiles() is False:
            sys.exit("Download failed")

    print("deploy")
    if deploy() is False:
        sys.exit("Deploy failed")

    print("init")
    if initialize() is False:
        sys.exit("Initialize failed")


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
    parser_all.set_defaults(func=install)
    args = parser.parse_args()

    # オプションがないとき
    if args == argparse.Namespace():
        args = parser.parse_args(["all"])
    args.func()


if __name__ == "__main__":
    main()
