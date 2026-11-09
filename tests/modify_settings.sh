#!/bin/bash
# home/dot_claude/modify_settings.json.tmpl のマージロジックのテスト
# 使い方: tests/modify_settings.sh   (要: chezmoi, jq)
set -uo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
tmpl="$root/home/dot_claude/modify_settings.json.tmpl"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

# fixture の base と profile を使うため、描画したスクリプトの該当行を差し替える
base_json='{
  "env": {"A": "base"},
  "permissions": {"allow": ["Read", "Bash(ls *)"], "deny": ["Bash(sudo *)"]},
  "hooks": {"PreToolUse": [{"matcher": "Bash", "hooks": [{"type": "command", "command": "guard.sh", "timeout": 10}]}]}
}'
printf '%s' "$base_json" >"$tmp/base.json"
chezmoi execute-template --source "$root" <"$tmpl" |
    sed -e "s|^base=.*|base=\"$tmp/base.json\"|" \
        -e 's|^private_profile=.*|private_profile="test"|' >"$tmp/modify.sh" || { echo "render failed"; exit 1; }

home="$tmp/home"
mkdir -p "$home/.config/private/claude"
private_file="$home/.config/private/claude/settings.json"

# run <stdin の内容>: modify スクリプトを実行して stdout を返す
run() { printf '%s' "$1" | HOME="$home" bash "$tmp/modify.sh"; }

fail=0
check() { # check <name> <jq の真偽式> <出力>
    if printf '%s' "$3" | jq -e "$2" >/dev/null 2>&1; then
        echo "ok   - $1"
    else
        echo "FAIL - $1"; printf '%s\n' "$3"; fail=1
    fi
}

# 1. 空 / 存在しない → base そのまま
out=$(run "")
check "empty input yields base" '. == '"$base_json" "$out"

# 2. permissions は和集合で重複しない
cur='{"permissions": {"allow": ["Bash(ls *)", "Bash(git log *)"], "additionalDirectories": ["/x"]}}'
out=$(run "$cur")
check "permissions union without duplicates" \
    '.permissions.allow == ["Bash(ls *)", "Bash(git log *)", "Read"] and .permissions.deny == ["Bash(sudo *)"] and .permissions.additionalDirectories == ["/x"]' "$out"

# 3. ローカル hook (別 command) は保持される
cur='{"hooks": {"PreToolUse": [{"hooks": [{"type": "command", "command": "orca.sh"}]}], "Stop": [{"hooks": [{"type": "command", "command": "stop.sh"}]}]}}'
out=$(run "$cur")
check "local hooks preserved" \
    '(.hooks.PreToolUse | map(.hooks[0].command)) == ["orca.sh", "guard.sh"] and .hooks.Stop[0].hooks[0].command == "stop.sh"' "$out"

# 4. base と同じ command のローカル hook は base で置き換わる
cur='{"hooks": {"PreToolUse": [{"matcher": "Bash", "hooks": [{"type": "command", "command": "guard.sh", "timeout": 99}]}]}}'
out=$(run "$cur")
check "same-command hook replaced by base" \
    '.hooks.PreToolUse | length == 1 and .[0].hooks[0].timeout == 10' "$out"

# 5. private 設定なし / あり
rm -f "$private_file"
out=$(run "")
check "no private file" '.env.A == "base"' "$out"
printf '%s' '{"env": {"A": "private"}, "permissions": {"allow": ["Bash(private *)"]}, "hooks": {"Stop": [{"hooks": [{"type": "command", "command": "p.sh"}]}]}}' >"$private_file"
out=$(run '{"permissions": {"allow": ["Read"]}}')
check "private file overrides and unions" \
    '.env.A == "private" and .permissions.allow == ["Read", "Bash(ls *)", "Bash(private *)"] and .hooks.Stop[0].hooks[0].command == "p.sh"' "$out"

# 5b. profile 別 private 設定 (machineProfile=test → settings.test.json)
private_profile_file="$home/.config/private/claude/settings.test.json"
printf '%s' '{"env": {"A": "profile"}, "permissions": {"allow": ["Bash(profile *)"]}, "hooks": {"Stop": [{"hooks": [{"type": "command", "command": "t.sh"}]}]}}' >"$private_profile_file"
out=$(run '{"permissions": {"allow": ["Read"]}}')
check "profile overrides common and unions" \
    '.env.A == "profile" and (.permissions.allow | index("Bash(private *)")) and (.permissions.allow | index("Bash(profile *)")) and (.hooks.Stop | map(.hooks[0].command) | index("t.sh"))' "$out"
rm -f "$private_profile_file"
out=$(run "")
check "profile file absent" \
    '.env.A == "private" and .hooks.Stop[0].hooks[0].command == "p.sh"' "$out"

# 5c. "$replace" で列挙したキーは深いマージせず置き換える (ローカル・base の残りを消す)
printf '%s' '{"$replace": ["env", "permissions"], "env": {"P": "private"}, "permissions": {"allow": ["Bash(private *)"]}}' >"$private_file"
out=$(run '{"env": {"STALE": "1"}, "permissions": {"allow": ["Read"]}}')
check "replace overrides env entirely" \
    '.env == {"P": "private"} and (has("$replace") | not) and (.permissions.allow | index("Read")) and (.permissions.allow | index("Bash(private *)"))' "$out"
twice=$(run "$out")
if [ "$(printf '%s' "$out" | jq -S .)" = "$(printf '%s' "$twice" | jq -S .)" ]; then
    echo "ok   - replace idempotent"
else
    echo "FAIL - replace idempotent"; fail=1
fi
# profile 層は replace 後の private の値に深いマージされる
printf '%s' '{"env": {"Q": "profile"}}' >"$private_profile_file"
out=$(run '{"env": {"STALE": "1"}}')
check "profile merges onto replaced env" '.env == {"P": "private", "Q": "profile"}' "$out"
# profile 層の replace で値を持たないキーは削除される
printf '%s' '{"$replace": ["env"]}' >"$private_profile_file"
out=$(run '{"env": {"STALE": "1"}}')
check "replace without value removes key" '(has("env") | not)' "$out"
rm -f "$private_profile_file"
printf '%s' '{"env": {"A": "private"}, "permissions": {"allow": ["Bash(private *)"]}, "hooks": {"Stop": [{"hooks": [{"type": "command", "command": "p.sh"}]}]}}' >"$private_file"

# 6. 冪等性
once=$(run '{"permissions": {"allow": ["Z"]}, "hooks": {"Stop": [{"hooks": [{"type": "command", "command": "l.sh"}]}]}}')
twice=$(run "$once")
if [ "$(printf '%s' "$once" | jq -S .)" = "$(printf '%s' "$twice" | jq -S .)" ]; then
    echo "ok   - idempotent output equal"
else
    echo "FAIL - idempotent output differs"; fail=1
fi

# 7. jq が無い環境では既存ファイルを壊さない
mkdir -p "$tmp/nojq"
ln -s "$(command -v cat)" "$tmp/nojq/cat"
nojq() { printf '%s' "$1" | HOME="$home" PATH="$tmp/nojq" "$BASH" "$tmp/modify.sh"; }
cur='{"keep": true}'
if [ "$(nojq "$cur")" = "$cur" ]; then echo "ok   - no jq keeps existing"; else echo "FAIL - no jq keeps existing"; fail=1; fi
if [ "$(nojq "")" = "$(cat "$tmp/base.json")" ]; then echo "ok   - no jq empty yields base"; else echo "FAIL - no jq empty yields base"; fail=1; fi

# 8. 不正な JSON はエラー終了する (apply を失敗させて既存ファイルを守る)
if run '{broken' >/dev/null 2>&1; then echo "FAIL - invalid JSON should fail"; fail=1; else echo "ok   - invalid JSON fails"; fi

exit $fail
