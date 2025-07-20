#!/usr/bin/env python
# -*- coding: utf-8 -*-
import glob
import os
import shlex
import subprocess
import sys
from abc import ABC, abstractmethod
from dataclasses import dataclass
from typing import List


# ====================
# Interfaces
# ====================
class FileSystemInterface(ABC):
    """Abstract interface for file system operations"""

    @abstractmethod
    def exists(self, path: str) -> bool:
        pass

    @abstractmethod
    def create_symlink(self, src: str, dst: str) -> None:
        pass

    @abstractmethod
    def remove(self, path: str) -> None:
        pass

    @abstractmethod
    def makedirs(self, path: str, exist_ok: bool = False) -> None:
        pass

    @abstractmethod
    def list_files(self, pattern: str) -> List[str]:
        pass

    @abstractmethod
    def is_symlink(self, path: str) -> bool:
        pass


class CommandRunnerInterface(ABC):
    """Abstract interface for running commands"""

    @abstractmethod
    def run(self, command: str) -> bool:
        pass

    @abstractmethod
    def which(self, command: str) -> bool:
        pass


class OutputInterface(ABC):
    """Abstract interface for output handling"""

    @abstractmethod
    def info(self, msg: str) -> None:
        pass

    @abstractmethod
    def success(self, msg: str) -> None:
        pass

    @abstractmethod
    def warn(self, msg: str) -> None:
        pass

    @abstractmethod
    def fail(self, msg: str) -> None:
        pass


# ====================
# Concrete Implementations
# ====================
class FileSystem(FileSystemInterface):
    """Real file system implementation"""

    def exists(self, path: str) -> bool:
        return os.path.exists(path)

    def create_symlink(self, src: str, dst: str) -> None:
        os.symlink(src, dst)

    def remove(self, path: str) -> None:
        os.remove(path)

    def makedirs(self, path: str, exist_ok: bool = False) -> None:
        os.makedirs(path, exist_ok=exist_ok)

    def list_files(self, pattern: str) -> List[str]:
        return glob.glob(pattern)

    def is_symlink(self, path: str) -> bool:
        return os.path.islink(path)


class CommandRunner(CommandRunnerInterface):
    """Real command runner implementation"""

    def run(self, command: str) -> bool:
        try:
            subprocess.check_call(shlex.split(command))
            return True
        except subprocess.CalledProcessError:
            return False

    def which(self, pgm: str) -> bool:
        path = os.getenv("PATH")
        for p in path.split(os.path.pathsep):
            p = os.path.join(p, pgm)
            if os.path.exists(p) and os.access(p, os.X_OK):
                return True
        return False


class ColoredOutput(OutputInterface):
    """Colored terminal output implementation"""

    SUCCESS = "\033[92m"  # Green
    WARNING = "\033[93m"  # Yellow
    DANGER = "\033[91m"  # Red
    PRIMARY = "\033[94m"  # Blue
    BOLD = "\033[1m"
    END = "\033[0m"

    def _print(self, color: str, msg: str) -> None:
        print(f"{color}{msg}{self.END}")

    def info(self, msg: str) -> None:
        self._print(self.BOLD, msg)

    def success(self, msg: str) -> None:
        self._print(self.SUCCESS, msg)

    def warn(self, msg: str) -> None:
        self._print(self.WARNING, msg)

    def fail(self, msg: str) -> None:
        self._print(self.DANGER, msg)


# ====================
# Configuration
# ====================
@dataclass
class DotfilesConfig:
    """Configuration for dotfiles installation"""

    home_dir: str
    dotfiles_dir: str
    repo_url: str = "https://github.com/ryosan-470/dotfiles.git"
    exclude_patterns: set = None
    required_commands: List[str] = None

    def __post_init__(self):
        if self.exclude_patterns is None:
            self.exclude_patterns = {
                ".git",
                ".git_commit_template.txt",
                ".gitignore",
                ".circleci",
                ".gitmodules",
                ".github",
            }
        if self.required_commands is None:
            self.required_commands = ["tmux", "zsh", "vim", "git"]

    @classmethod
    def default(cls):
        """Create default configuration"""
        home = os.path.expanduser("~")
        return cls(
            home_dir=home, dotfiles_dir=os.path.join(home, ".dotconfig/dotfiles")
        )

    def get_dotfiles(self) -> set:
        """Get list of dotfiles to be linked"""
        pattern = os.path.join(self.dotfiles_dir, ".*")
        all_files = set(os.path.basename(f) for f in glob.glob(pattern))
        return all_files - self.exclude_patterns


# ====================
# Main Installer Class
# ====================
class DotfilesInstaller:
    """Main installer class with dependency injection"""

    def __init__(
        self,
        config: DotfilesConfig,
        fs: FileSystemInterface,
        runner: CommandRunnerInterface,
        output: OutputInterface,
    ):
        self.config = config
        self.fs = fs
        self.runner = runner
        self.output = output

    def check_requirements(self) -> bool:
        """Check if all required commands are available"""
        missing = [
            cmd for cmd in self.config.required_commands if not self.runner.which(cmd)
        ]

        if missing:
            self.output.warn(f"Please install the command: {', '.join(missing)}")
            return False
        return True

    def download(self, branch: str = "master") -> bool:
        """Clone the dotfiles repository"""
        self.output.info(f"Clone repository. branch is {branch}")

        if self.fs.exists(self.config.dotfiles_dir):
            self.output.success("✓ Skip to clone repository since it has been existed")
            return True

        command = (
            f"git clone -b {branch} {self.config.repo_url} {self.config.dotfiles_dir}"
        )
        self.output.info(command)

        if self.runner.run(command):
            self.output.success("✓ Finished to clone repository")
            return True
        else:
            self.output.fail("✗ Download failed. Please check your internet connection")
            return False

    def deploy(self) -> bool:
        """Create symlinks for dotfiles"""
        success = True
        dotfiles = self.config.get_dotfiles()

        for dotfile in dotfiles:
            src = os.path.join(self.config.dotfiles_dir, dotfile)
            dst = os.path.join(self.config.home_dir, dotfile)

            try:
                if self.fs.exists(dst):
                    self.output.warn(f"{src} ==> {dst} has been already existed")
                else:
                    self.fs.create_symlink(src, dst)
                    self.output.success(f"✓ linking {src} ==> {dst}")
            except Exception as e:
                self.output.fail(f"✗ Failed to link {src} ==> {dst}: {e}")
                success = False

        return success

    def clean(self) -> bool:
        """Remove symlinks"""
        success = True
        dotfiles = self.config.get_dotfiles()

        for dotfile in dotfiles:
            dst = os.path.join(self.config.home_dir, dotfile)

            try:
                if self.fs.exists(dst):
                    self.fs.remove(dst)
                    self.output.success(f"✓ Removed {dst}")
                else:
                    self.output.warn(
                        f"✘ {dst} cannot remove because it has already removed"
                    )
            except Exception as e:
                self.output.fail(f"✘ {dst} cannot remove: {e}")
                success = False

        if success:
            self.output.success("✓ Cleaned!")
        else:
            self.output.fail("✘ Failed to execute clean!")

        return success

    def initialize(self) -> bool:
        """Run initialization scripts"""
        init_dir = os.path.join(self.config.dotfiles_dir, "init")

        if not self.fs.exists(init_dir):
            self.output.warn("No init directory found")
            return True

        scripts = [
            f
            for f in self.fs.list_files(os.path.join(init_dir, "*"))
            if not f.endswith("README.md")
        ]

        success = True
        for script in scripts:
            self.output.info(f"Run: {script}")
            if not self.runner.run(f"bash {script}"):
                self.output.fail(f"Failed to run {script}")
                success = False

        return success

    def verify(self) -> bool:
        """Verify installation"""
        dotfiles = self.config.get_dotfiles()
        failed = False

        for dotfile in dotfiles:
            target = os.path.join(self.config.home_dir, dotfile)
            if self.fs.exists(target):
                self.output.success(f"✓ {target}")
            else:
                self.output.warn(f"✘ {target}")
                failed = True

        if failed:
            self.output.fail("✘ Some tests are failed")
            return False
        else:
            self.output.success("✔ All test passed")
            return True

    def install(self) -> bool:
        """Run full installation"""
        self.output.info("==> Start install progress...")

        if not self.check_requirements():
            self.output.fail("✗ Please install requirements first!")
            return False

        self.output.info("==> Clone repository from GitHub")
        if not self.download():
            return False

        self.output.info("==> Start to deploy")
        if not self.deploy():
            self.output.fail("✗ Deploying failed.")
            return False

        self.output.success("✓ Finished to deploy")
        self.output.info("==> initializing")
        self.initialize()

        self.output.info("==> Start to test")
        return self.verify()


# ====================
# CLI Interface
# ====================
def create_installer() -> DotfilesInstaller:
    """Factory function to create installer with real implementations"""
    config = DotfilesConfig.default()
    return DotfilesInstaller(
        config=config, fs=FileSystem(), runner=CommandRunner(), output=ColoredOutput()
    )


def main():
    import argparse

    parser = argparse.ArgumentParser(
        description="The setup script for dotfiles. Linux and Mac OSX supports."
    )

    subparsers = parser.add_subparsers(dest="command", help="Commands")

    # Download command
    download_cmd = subparsers.add_parser(
        "download", help="Clone repository from GitHub"
    )
    download_cmd.add_argument(
        "branch", nargs="?", default="master", help="Branch to clone"
    )

    # Other commands
    subparsers.add_parser("deploy", help="Deploy dotfiles to your home directory")
    subparsers.add_parser(
        "init", help="To initialize: make file or install dependencies"
    )
    subparsers.add_parser("test", help="Test section using Travis-CI")
    subparsers.add_parser("clean", help="Remove linking files")
    subparsers.add_parser("all", help="Do download, deploy and init")

    args = parser.parse_args()

    # Default to 'all' if no command specified
    if not args.command:
        args.command = "all"

    # Create installer
    installer = create_installer()

    # Execute command
    if args.command == "download":
        success = installer.download(args.branch)
    elif args.command == "deploy":
        success = installer.deploy()
    elif args.command == "init":
        success = installer.initialize()
    elif args.command == "test":
        success = installer.verify()
    elif args.command == "clean":
        success = installer.clean()
    elif args.command == "all":
        success = installer.install()
    else:
        parser.print_help()
        success = False

    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
