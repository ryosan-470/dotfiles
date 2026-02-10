#!/bin/bash
INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('tool_input',{}).get('file_path',''))" 2>/dev/null)

[[ "$FILE_PATH" == *.py ]] || exit 0

cd "$CLAUDE_PROJECT_DIR" || exit 0

echo "Running ruff check..." >&2
uv run ruff check . >&2 || exit 2

echo "Running ruff format --check..." >&2
uv run ruff format --check . >&2 || exit 2

echo "Running pytest..." >&2
uv run pytest tests/ >&2 || exit 2
