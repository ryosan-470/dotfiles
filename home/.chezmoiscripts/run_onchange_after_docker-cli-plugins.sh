#!/bin/bash
# ~/.docker/cli-plugins に残った壊れた symlink を掃除する。
# アンインストール済みの Docker Desktop が置いていったリンク切れが残っていると、
# Homebrew の docker-compose / docker-buildx プラグインを隠してしまい、
# `docker compose` が "unknown command" になる。
set -eu

[ "$(uname -s)" = Darwin ] || exit 0

# CI には Docker ランタイムが無いのでスキップ
[ -n "${CI:-}" ] && exit 0

plugins="$HOME/.docker/cli-plugins"
[ -d "$plugins" ] || exit 0

removed=0
for f in "$plugins"/*; do
    [ -L "$f" ] || continue
    # リンク先が存在するものは触らない
    [ -e "$f" ] && continue
    rm -- "$f"
    echo "removed dangling plugin link: $f"
    removed=$((removed + 1))
done

[ "$removed" -eq 0 ] && echo "docker-cli-plugins: リンク切れなし"
exit 0
