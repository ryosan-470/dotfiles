#!/usr/bin/env bash
# PreToolUse hook (Bash matcher)
#
# settings.base.json の permissions はコマンド文字列の前方一致でしか判定できないため、
# 表記揺れ (rm -fr / rm -r -f) や複合コマンド (cd x && rm -rf y)、
# git エイリアス経由の破壊的操作を検出して deny / ask を返す。
#
# 判定は settings.base.json の方針と揃える:
#   deny: rm / git rm の再帰的強制削除
#   ask : 上記以外の rm / mv、git commit / push (--force / -f を含む)、
#         git reset --hard、git clean -f、git restore、git checkout -- / . / -f
#
# `bash -c '...'`、`eval`、`find -exec` の中身は再帰的に解析する。
# 限界: 完全なシェルパーサではない。変数展開や難読化されたコマンド、
# スクリプトファイルの中身までは追跡しない。

set -euo pipefail
set -f

command -v jq >/dev/null 2>&1 || exit 0

input=$(cat)
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty')
[ -n "$cmd" ] || exit 0

hook_dir=$(cd "$(dirname "$0")" && pwd)
awk_file="$hook_dir/dangerous-command-guard.awk"
[ -r "$awk_file" ] || exit 0

best=0
reason=""

# analyze <コマンド文字列> <深さ>: 入れ子のコマンドと git エイリアスを解決しつつ判定を集約する
analyze() {
    local input=$1 depth=$2 out kind p r subs scmd exp inner nested
    out=$(printf '%s' "$input" | awk -f "$awk_file" 2>/dev/null || true)
    subs=""
    nested=""
    while IFS=$'\t' read -r kind p r; do
        case "$kind" in
            D)
                p=${p:-0}
                if [ "$p" -gt "$best" ]; then
                    best=$p
                    reason=$r
                fi
                ;;
            G)
                if [ -n "$p" ]; then
                    subs="$subs $p"
                fi
                ;;
            C)
                # bash -c / eval / find -exec の中身 (改行区切りで保持する)
                if [ -n "$p" ]; then
                    nested="$nested$p"$'\n'
                fi
                ;;
        esac
    done <<<"$out"

    if [ -n "$nested" ] && [ "$depth" -lt 3 ]; then
        while IFS= read -r inner; do
            if [ -n "$inner" ]; then
                analyze "$inner" $((depth + 1))
            fi
        done <<<"$nested"
    fi

    # エイリアスの入れ子は 1 段まで辿る
    [ "$depth" -lt 2 ] || return 0
    for scmd in $subs; do
        exp=$(git config --get "alias.$scmd" 2>/dev/null | head -n 1 || true)
        [ -n "$exp" ] || continue
        case "$exp" in
            '!'*) inner=${exp#!} ;;
            *) inner="git $exp" ;;
        esac
        analyze "$inner" $((depth + 1))
    done
}

analyze "$cmd" 0

case "$best" in
    2) decision=deny ;;
    1) decision=ask ;;
    *) exit 0 ;;
esac

[ -n "$reason" ] || reason="破壊的な可能性があるコマンドのため確認が必要です"
jq -n --arg d "$decision" --arg r "$reason" \
    '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: $d, permissionDecisionReason: $r}}'
