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
expect ask "bash -c 'gh pr merge 1'"
expect deny "bash -c 'gh secret set FOO'"
expect ask "bash -c 'cat .env'"

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

# --- git push: 削除 / mirror / refspec ---
expect ask 'git push --delete origin main'
expect ask 'git push -d origin main'
expect ask 'git push --mirror origin'
expect ask 'git push --prune origin'
expect ask 'git push origin +main'
expect ask 'git push origin :main'
expect none 'git push origin HEAD:main'
expect none 'git push origin main'

# --- git push: 長オプションの省略形 (git は一意な省略形を受け付ける) ---
expect ask 'git push --del origin main'
expect ask 'git push --dele origin main'
expect ask 'git push --mir origin'
expect ask 'git push --prune-tags origin'

# --- git branch / tag / remote / stash ---
expect ask 'git branch -D main'
expect ask 'git branch -d main'
expect ask 'git branch -m old new'
expect ask 'git branch -f main origin/main'
expect none 'git branch -a'
expect none 'git branch -vv'
expect ask 'git branch --delete-merged foo*'
expect ask 'git branch --mov old new'
expect ask 'git branch --forc main origin/main'
expect none 'git branch --merged'
expect ask 'git tag -d v1'
expect ask 'git tag -f v1'
expect ask 'git tag --del v1'
expect ask 'git tag --forc v1'
expect none 'git tag -l'
expect none 'git tag -a v1 -m release'
expect ask 'git remote remove origin'
expect ask 'git remote set-url origin git@example.com:x.git'
expect none 'git remote -v'
expect none 'git remote show origin'
expect ask 'git stash drop'
expect ask 'git stash clear'
expect none 'git stash list'

# --- gh api: 書き込み系フラグ (rtk に書き換えられても元の入力で判定する) ---
expect ask 'gh api -X DELETE /repos/o/r'
expect ask 'gh api --method POST /repos/o/r'
expect ask 'gh api --method=POST /repos/o/r'
expect ask 'gh api -f body=x /repos/o/r'
expect ask 'gh api -F body=@x /repos/o/r'
expect ask 'gh api --input body.json /repos/o/r'
expect ask 'gh api /repos/o/r -X DELETE'
expect ask 'gh api graphql -f query=query'
expect none 'gh api /repos/o/r'
expect none 'gh api --paginate /repos/o/r/issues'

# --- gh / brew: settings の ask / deny を guard でも判定する ---
expect ask 'gh pr merge 1'
expect ask 'gh pr close 1'
expect ask 'gh issue close 1'
expect ask 'gh variable set FOO'
expect ask 'gh variable delete FOO'
expect none 'gh variable list'
expect none 'gh variable get FOO'
expect none 'gh pr view 1'
expect none 'gh issue view 1'
expect none 'gh secret list'
expect deny 'gh secret set FOO'
expect deny 'gh secret delete FOO'
expect deny 'gh auth login'
expect deny 'gh auth token'
expect none 'gh auth status'
expect deny 'gh auth status --show-token'
expect deny 'gh auth status -t'
expect deny 'gh auth status -h github.com -t'
expect deny 'gh auth status -t=true'
expect deny 'gh auth status -at'
expect none 'gh auth status -a'
expect none 'gh auth status -h github.com'
expect ask 'brew install jq'
expect none 'rtk gh pr merge 1'   # rtk 経由の文字列は対象外 (元のコマンドで判定する)

# --- 機密ファイルを読むコマンド ---
expect ask 'cat .env'
expect ask 'cat ~/.ssh/id_rsa'
expect ask 'grep -r AWS ~/.aws'
expect ask 'head -n 5 .env.local'
expect ask 'base64 ~/.aws/credentials'
expect ask 'cat .env-prod'
expect ask 'cat .env-staging.local'
expect none 'cat foo.env'
expect none 'cat README.md'
expect none 'grep -r "ssh" docs'
expect none 'grep -r "\.env" docs'
expect none 'sed -n "s/foo/bar/p" README.md'

# --- その他 ---
expect ask 'mv a b'
expect ask 'git commit -m "reset --hard"'
expect none ''

exit $fail
