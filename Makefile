.PHONY: all setup install lint format format-check test python-version integration-test help

all: setup lint format-check test

help:
	@echo "Available targets:"
	@echo "  all              - Run setup, lint, format-check, and test"
	@echo "  setup            - Install development dependencies"
	@echo "  install          - Install production dependencies"
	@echo "  lint             - Run ruff linter"
	@echo "  format           - Format code with ruff"
	@echo "  format-check     - Check code formatting with ruff"
	@echo "  test             - Run unit tests with pytest"
	@echo "  python-version   - Display Python version"
	@echo "  integration-test - Run integration tests"

setup:
	uv sync --dev

install:
	uv sync

lint:
	uv run ruff check .

format:
	uv run ruff format

format-check:
	uv run ruff format --check .

test: setup
	uv run pytest tests/ -v --cov=install --cov-report=term-missing

python-version:
	uv run python -c "import sys; print(sys.version)"

integration-test: setup
	uv run python install.py download
	uv run python install.py deploy
	uv run python install.py init
	uv run python install.py test
	uv run python install.py clean