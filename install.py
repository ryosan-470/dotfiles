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
                        ".gitignore", ".circleci", ".gitmodules"])
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
    except subprocess.CalledProcessError:
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
    REPOS_URL = "https://github.com/ryosan-470/dotfiles.git"
    # git clone --recursive ${REPO_URL} ${DOTFILES}
    # git  --recursive option is then do submodule init & submodule update
    f.info("Clone repository. branch is " + branch)
    command = "git clone -b {branch} {repo} {dst}".format(
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


def clean():
    # DOT_HOME_FILES.update([os.path.join(HOME, ".tmux/plugins/tpm")])
    failed = False

    for dfs in DOT_HOME_FILES:
        dst = os.path.join(HOME, dfs)
        try:
            os.remove(dst)
        except OSError as e:
            import errno
            if e.errno == errno.ENOENT:
                f.warn("✘ {dst} cannot remove because it has already removed".format(dst=dst))
            else:
                f.fail("✘ {dst} cannot remove !!".format(dst=dst))
                failed = True

    if failed:
        f.fail("✘ Failed to execute clean!")
        sys.exit(1)
    f.success("✓ Cleaned!")


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
    failed = False
    for x in DOT_HOME_FILES:
        target = os.path.join(HOME, x)
        try:
            assert os.path.exists(target)
            f.success("✓ %s" % target)
        except AssertionError:
            f.warn("✘ %s" % target)
            failed = True

    if failed:
        f.fail("✘ Some tests are failed")
        sys.exit(1)
    f.success("✔ All test passed")


def install():
    f.info("==> Start install progress...")
    if not has_required():
        f.fail("✗ Please install requirements first!")
        sys.exit(1)

    f.info("==> Clone repository from GitHub")
    if os.path.exists(DOTFILES):
        f.success("✓ Skip to clone repository since it has been existed")
    else:
        ret = downloading_dotfiles()
        if ret is False:
            f.fail("✗ Download failed. Please check your internet connection")
            sys.exit(1)
    f.success("✓ Finished to clone repository")
    f.info("==> Start to deploy")
    ret = deploy()
    if ret is False:
        f.fail("✗ Deploying failed.")
        sys.exit(1)

    f.success("✓ Finished to deploy")
    f.info("==> initializing")
    initialize()
    f.info("==> Start to test")
    test()


def create_parser():
    description = """
    The setup script for me. Linux and Mac OSX supports.
    Copyright (C) 2015 - 2017 Ryosuke SATO (jtwp470)
    This software is released under the MIT License.
    """
    parser = argparse.ArgumentParser(description=description)

    subparsers = parser.add_subparsers()
    download_cmd = subparsers.add_parser(
        "download",
        help="Clone repository from GitHub"
    )
    download_cmd.add_argument("branch", nargs='?', default="master")

    deploy_cmd = subparsers.add_parser(
        "deploy",
        help="Deploy dotfiles to your home directory"
    )
    deploy_cmd.set_defaults(func=deploy)

    init_cmd = subparsers.add_parser(
        "init",
        help="To initialize: make file or install dependencies"
    )
    init_cmd.set_defaults(func=initialize)

    test_cmd = subparsers.add_parser(
        "test",
        help="test section using Travis-CI"
    )
    test_cmd.set_defaults(func=test)

    clean_cmd = subparsers.add_parser(
        "clean",
        help="Remove linking files")
    clean_cmd.set_defaults(func=clean)

    all_cmd = subparsers.add_parser(
        "all",
        help="do download, deploy and init"
    )
    all_cmd.set_defaults(func=install)

    return parser


def main():
    parser = create_parser()
    args = parser.parse_args(sys.argv[1:])
    vargs = vars(args)
    if vargs.get('branch'):
        downloading_dotfiles(vargs.get('branch'))
    else:
        args.func()


if __name__ == "__main__":
    if len(sys.argv) < 2:
        sys.argv.append("all")
    main()
