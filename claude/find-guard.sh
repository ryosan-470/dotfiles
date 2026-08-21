#!/usr/bin/env bash
# PreToolUse hook (Bash matcher)
#
# find コマンドが範囲を指定せず(例: `find /`, `find ~`)に実行され、
# CPU/Disk IO を大量消費するのを防ぐためのガード。
#
# 対象パスがルート直下・ホーム全体・OS 主要ディレクトリ全体などの
# "広すぎる" パスで、かつ -maxdepth 指定がない場合のみ、
# permissionDecision: ask を返して確認を挟む。
# それ以外(スコープが絞られている find)には一切介入しない。

set -euo pipefail

input="$(cat)"
cmd="$(printf '%s' "$input" | jq -r '.tool_input.command // empty')"

[ -z "$cmd" ] && exit 0

# "find" がコマンドとして呼ばれているか(先頭 or ; & | && || の後に find)
if ! printf '%s' "$cmd" | grep -qE '(^|[;&|]|&&|\|\|)[[:space:]]*find([[:space:]]|$)'; then
  exit 0
fi

# find の直後にある最初のパス引数(/ ~ $HOME で始まるもの)を抽出
# (該当なしなら grep が非ゼロ終了するが、pipefail 環境でも落ちないよう || true で吸収)
path="$(printf '%s' "$cmd" | grep -oE 'find[[:space:]]+(/[^[:space:]]*|~[^[:space:]]*|\$HOME[^[:space:]]*)' | head -1 | awk '{print $2}' || true)"

[ -z "${path:-}" ] && exit 0

# ルート直下・ホーム全体・OS 主要ディレクトリなど「広すぎる」パスの判定
broad_pattern='^(/|~/?|\$HOME/?|/(Users|home|System|Library|usr|var|opt|Applications|mnt|media|proc|sys|etc|bin|sbin)/?)$'

if printf '%s' "$path" | grep -qE "$broad_pattern"; then
  if ! printf '%s' "$cmd" | grep -q -- '-maxdepth'; then
    reason="find の探索範囲が広すぎます(対象: ${path})。CPU/Disk IO を大量に消費するおそれがあります。-maxdepth を指定するか、対象ディレクトリをより具体的に絞ってください。"
    jq -n --arg reason "$reason" \
      '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "ask", permissionDecisionReason: $reason}}'
  fi
fi

exit 0
