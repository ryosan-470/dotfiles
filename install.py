#!/usr/bin/env python
# -*- coding: utf-8 -*-
import os
import sys
import subprocess
import shlex
import glob

try:
    import argparse
except ImportError:
    sys.exit("Please install or run Python 2.7 or later")


HOME = os.path.expanduser("~")  # User Home Directory
DOTFILES = os.path.join(HOME, ".dotconfig/dotfiles")
ALL_DOTFILES = set(x[len(DOTFILES+"/"):] for x in glob.glob(DOTFILES + "/.*"))
# 除外するファイル名の設定
EXCLUDE_DOTFILES = set([".git", ".git_commit_template.txt",
                        ".gitignore", ".travis.yml", ".gitmodules"])
# ホームディレクトリ上にシンボリックリンクを貼るファイルの名前
DOT_HOME_FILES = ALL_DOTFILES - EXCLUDE_DOTFILES


class FormatedColor:
    SUCCESS = "\033[92m"  # Green
    WARNING = "\033[93m"  # Yello
    DANGER = "\033[91m"   # Red
    PRIMARY = "\033[94m"  # Blue
    BOLD = "\033[1m"
    END = "\033[0m"

    def init(self):
        pass

    def pprint(self, header, msg, end=END):
        print(header + msg + end)

    def success(self, msg):
        self.pprint(self.SUCCESS, msg)

    def fail(self, msg):
        self.pprint(self.DANGER, msg)

    def warn(self, msg):
        self.pprint(self.WARNING, msg)

    def info(self, msg):
        self.pprint(self.BOLD, msg)


f = FormatedColor()


def run(os_command):
    """os_command is linux command, eg: git clone https://github.com/..."""
    try:
        subprocess.check_call(shlex.split(os_command))
    except subprocess.CalledProcessError as e:
        f.fail("✗ Execution command failure: %s" % os_command)
        return False
    return True


def which(pgm):
    path = os.getenv("PATH")
    for p in path.split(os.path.pathsep):
        p = os.path.join(p, pgm)
        if os.path.exists(p) and os.access(p, os.X_OK):
            return True
    return False


def has_required():
    REQUIRED_COMMAND = ("tmux", "zsh", "vim", "git")
    rest = list(filter(lambda x: not which(x), REQUIRED_COMMAND))
    if rest != []:
        f.warn("Please install the command. " + ", ".join(rest))
        return False
    return True


def downloading_dotfiles(branch="master"):
    REPOS_URL = "https://github.com/jtwp470/dotfiles.git"
    # git clone --recursive ${REPO_URL} ${DOTFILES}
    # git  --recursive option is then do submodule init & submodule update
    f.info("Clone repository. branch is " + branch)
    command = "git clone -b {branch} {repo} {dst} --recursive".format(
        branch=branch, repo=REPOS_URL, dst=DOTFILES)
    f.info(command)
    return True if run(command) else False


def deploy():
    for dfs in DOT_HOME_FILES:
        src = os.path.join(DOTFILES, dfs)
        dst = os.path.join(HOME, dfs)

        try:
            os.symlink(src, dst)
            f.success("✓ linking {src} ==> {dst}".format(src=src, dst=dst))
        except:
            f.warn("{src} ==> {dst} has been already existed".format(src=src, dst=dst))


def initialize():
    init_directory = os.path.join(DOTFILES, "init")
    scripts = set(glob.glob(init_directory + "/*"))
    scripts = scripts - set([os.path.join(init_directory, "README.md")])
    for s in scripts:
        try:
            f.info("Run: %s" % s)
            subprocess.check_call(shlex.split("bash " + s))
        except OSError:
            sys.exit("[Error:initialize()]Command not found.")


def test():
    for x in DOT_HOME_FILES:
        f.success("✓ %s" % os.path.join(HOME, x))
        assert os.path.exists(os.path.join(HOME, x))
    f.success("✓ All test passed")


def install():
    f.info("==> Start install progress...")
    if not has_required():
        f.fail("✗ Please install requirements first!")
        sys.exit(1)

    f.info("==> Clone repository from GitHub")
    if os.path.exists(DOTFILES):
        f.success("✓ Skip to clone repository since it has been existed")
    else:
        if downloading_dotfiles() is False:
            f.fail("✗ Download failed. Please check your internet connection")
            sys.exit(1)
    f.success("✓ Finished to clone repository")
    f.info("==> Start to deploy")
    if deploy() is False:
        f.fail("✗ Deploying failed.")
        sys.exit(1)

    f.success("✓ Finished to deploy")
    f.info("==> initializing")
    if initialize() is False:
        f.fail("✗ Initializing failed")
        sys.exit(1)

    f.info("==> Start to test")
    test()


def main():
    description = """
    The setup script for me. Linux and Mac OSX supports.

    Copyright (C) 2015 Ryosuke SATO (jtwp470)
    This software is released under the MIT License.

    Please refer to http://jtwp470.mit-license.org to know this license.
    """
    parser = argparse.ArgumentParser(description=description)
    subparser = parser.add_subparsers()

    parser_download_repo = subparser.add_parser("download",
                                                help="Clone repository from GitHub")
    parser_download_repo.set_defaults(func=downloading_dotfiles)

    parser_deploy = subparser.add_parser("deploy",
                                         help="Deploy dotfiles to your home directory")
    parser_deploy.set_defaults(func=deploy)

    parser_initialize = subparser.add_parser("init",
                                             help="To initialize: make file or install dependencies")
    parser_initialize.set_defaults(func=initialize)

    parser_test = subparser.add_parser("test", help="test section using Travis-CI")
    parser_test.set_defaults(func=test)

    parser_all = subparser.add_parser("all", help="do download, deploy and init")
    parser_all.set_defaults(func=install)
    args = parser.parse_args()
    args.func()


if __name__ == "__main__":
    if len(sys.argv) != 2:
        # オプションがないときはall扱いする
        sys.argv.append("all")
    main()
