#!/usr/bin/env python
import os
import sys
import tempfile
from unittest.mock import patch

import pytest

# Add the parent directory to the path so we can import install.py
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))


@pytest.fixture
def temp_home_dir():
    """Create a temporary home directory for testing"""
    with tempfile.TemporaryDirectory() as temp_dir:
        # Save original HOME
        original_home = os.environ.get("HOME")
        # Set temporary HOME
        os.environ["HOME"] = temp_dir
        yield temp_dir
        # Restore original HOME
        if original_home:
            os.environ["HOME"] = original_home
        else:
            del os.environ["HOME"]


@pytest.fixture
def temp_dotfiles_dir(temp_home_dir):
    """Create a temporary dotfiles directory"""
    dotfiles_path = os.path.join(temp_home_dir, ".dotconfig", "dotfiles")
    os.makedirs(dotfiles_path, exist_ok=True)
    return dotfiles_path


@pytest.fixture
def mock_subprocess():
    """Mock subprocess.check_call for testing commands"""
    with patch("subprocess.check_call") as mock_call:
        yield mock_call


@pytest.fixture
def mock_which():
    """Mock the which command to control command availability"""

    def which_side_effect(cmd):
        # Default commands that should be available
        available_commands = {"git", "python", "python3"}
        return cmd in available_commands

    with patch("install.which", side_effect=which_side_effect) as mock:
        yield mock


@pytest.fixture
def mock_git_clone():
    """Mock git clone operations"""
    with patch("subprocess.check_call") as mock_call:

        def clone_side_effect(args):
            # If it's a git clone command, create the directory
            if "git" in args and "clone" in args:
                # Extract the destination from the command
                dst_index = args.index("-b") + 3 if "-b" in args else -1
                dst = args[dst_index]
                os.makedirs(dst, exist_ok=True)
            return None

        mock_call.side_effect = clone_side_effect
        yield mock_call


@pytest.fixture
def sample_dotfiles(temp_dotfiles_dir):
    """Create sample dotfiles for testing"""
    dotfiles = [".zshrc", ".vimrc", ".tmux.conf", ".gitconfig"]
    for dotfile in dotfiles:
        filepath = os.path.join(temp_dotfiles_dir, dotfile)
        with open(filepath, "w") as f:
            f.write(f"# Sample {dotfile} content\n")
    return dotfiles
