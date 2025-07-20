# dotfiles
[![test](https://github.com/ryosan-470/dotfiles/workflows/test/badge.svg)](https://github.com/ryosan-470/dotfiles/actions?query=workflow%3Atest)
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

## Dependencies

- zsh
  - [zimfw](https://github.com/zimfw/zimfw)
- tmux
  - [tmux plugin manager](https://github.com/tmux-plugins/tpm)

## Customization

You can customize the dotfiles by editing the files in the `~/.local.zsh`.
For example, you can set your own aliases, functions, and environment variables.

```bash
# ~/.local.zsh
# Set your own aliases
alias ll='ls -la'
```

## Development

### Running Tests

This project uses [uv](https://docs.astral.sh/uv/) for Python dependency management and testing.

```bash
# Install uv (if not already installed)
curl -LsSf https://astral.sh/uv/install.sh | sh

# Install dependencies
uv sync --dev

# Run tests
uv run pytest

# Run tests with coverage
uv run pytest --cov=install --cov-report=term-missing

# Run specific test
uv run pytest tests/test_install.py::TestWhichFunction -v
```
