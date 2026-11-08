#!/bin/bash
# home/dot_claude/hooks/dangerous-command-guard.sh と .awk のテスト
# 使い方: tests/dangerous-command-guard.sh   (要: awk, jq, git)
set -uo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
hook="$root/home/dot_claude/hooks/dangerous-command-guard.sh"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

# 実際の gitconfig を読まないよう、HOME を一時ディレクトリに閉じる
export HOME="$tmp/home"
export XDG_CONFIG_HOME="$HOME/.config"
export GIT_CONFIG_NOSYSTEM=1
mkdir -p "$HOME"
cat >"$HOME/.gitconfig" <<'EOF'
[alias]
	nevermind = !git reset --hard HEAD && git clean -d -f
	boom = !rm -rf
	multi = !git nevermind
	c = commit
	p = !git push origin HEAD --force-with-lease
	plainpush = !git push origin HEAD
EOF

fail=0
decision() {
    local out
    out=$(jq -n --arg c "$1" '{tool_input: {command: $c}}' | bash "$hook")
    if [ -z "$out" ]; then
        echo none
    else
        printf '%s' "$out" | jq -r '.hookSpecificOutput.permissionDecision // "none"'
    fi
}
expect() { # expect <want> <command> [<表示名>]
    local want=$1 cmd=$2 name=${3:-$2} got
    got=$(decision "$cmd")
    if [ "$got" = "$want" ]; then
        echo "ok   - $name"
    else
        echo "FAIL - $name (want=$want got=$got)"
        fail=1
    fi
}

# --- rm: 再帰的強制削除は deny ---
expect deny 'rm -rf foo'
expect deny 'rm -fr foo'
expect deny 'rm -r -f foo'
expect deny 'rm -f -r foo'
expect deny 'rm -Rf foo'
expect deny 'rm -fR foo'
expect deny 'rm --recursive --force foo'
expect deny 'rm -rf'
expect ask 'rm -- -rf'          # -- 以降はファイル名
expect ask 'rm -r foo'
expect ask 'rm foo'

# --- rm: 複合コマンドやラッパー越しでも検出する ---
expect deny 'cd /tmp && rm -rf foo'
expect deny 'ls; rm -fr foo'
expect deny 'sudo rm -rf foo'
expect deny 'sudo -u root rm -rf foo'
expect deny '/bin/rm -rf foo'
expect deny '\rm -rf foo'
expect deny 'command rm -rf foo'
expect deny 'env FOO=1 rm -rf foo'
expect deny 'env -u FOO rm -rf foo'
expect deny 'xargs -0 rm -rf'
expect deny 'xargs -n1 rm -rf'
expect deny 'timeout 5 rm -rf foo'
expect deny 'timeout -s KILL 10 rm -rf foo'
expect deny 'nice -n 10 rm -rf foo'

# --- 誤検知しないこと ---
expect none 'echo "rm -rf foo"'
expect none 'grep -r "rm -rf" .'
expect none 'command -v rm'
expect none 'ls /'
expect none 'find . -name "rm -rf"'

# --- 入れ子のコマンド (bash -c / eval / find -exec) ---
expect deny "bash -c 'rm -rf foo'"
expect ask "sh -lc 'git reset --hard'"
expect deny "eval 'rm -rf foo'"
expect deny 'find . -exec rm -rf {} +'
expect deny "find . -exec sh -c 'rm -rf {}' \\;"
expect none 'find . -exec ls {} \;'
expect none "bash -c 'echo rm -rf'"
expect none 'bash script.sh'
expect none "bash -c 'git log --oneline'"

# --- git rm ---
expect deny 'git rm -rf foo'
expect deny 'git rm -fr foo'
expect deny 'git rm -r -f foo'
expect ask 'git rm -r foo'
expect ask 'git rm foo'
expect ask 'git rm -rf --cached .'   # --cached は実体を消さない

# --- git reset / clean / checkout / restore / push ---
expect ask 'git reset --hard'
expect ask 'git reset --hard HEAD'
expect ask 'git -C /tmp reset --hard'
expect ask 'git --git-dir=/tmp/.git reset --hard'
expect none 'git reset --soft HEAD'
expect ask 'git clean -fd'
expect ask 'git clean -fdx'
expect none 'git clean -n'
expect ask 'git checkout -- .'
expect ask 'git checkout .'
expect ask 'git checkout -f main'
expect none 'git checkout main'
expect ask 'git restore foo'
expect ask 'git restore --staged foo'
expect ask 'git commit -m foo'
expect none 'git push'
expect ask 'git push -f'
expect ask 'git push --force'
expect ask 'git push -f origin main'
expect ask 'git push --force-with-lease'
expect ask 'git push origin main --force'
expect ask 'git push --force-with-lease=origin/main'
expect none 'git push origin main'
expect none 'git push origin main --no-verify'
expect none 'git log --oneline'

# --- git エイリアス ---
expect ask 'git nevermind'
expect deny 'git boom'
expect ask 'git -C /tmp nevermind'
expect ask 'git multi'
expect ask 'git c -m foo'
expect ask 'git p'
expect none 'git plainpush'

# --- その他 ---
expect ask 'mv a b'
expect ask 'git commit -m "reset --hard"'
expect none ''

exit $fail
