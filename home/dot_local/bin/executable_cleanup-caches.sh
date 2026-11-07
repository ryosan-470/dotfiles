#!/bin/bash
# 再生成可能な開発キャッシュを掃除する。launchd (~/Library/LaunchAgents/com.ryosan470.cleanup-caches.plist) から月 1 回実行される。
# データが消えるもの (docker volume, LM Studio のモデルなど) は対象外。
set -u

# launchd 経由では PATH が最小限なので補う
export PATH="$HOME/.local/share/mise/shims:$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"
if [ -z "${DOCKER_HOST:-}" ] && [ -S "$HOME/.dory/dory.sock" ]; then
    export DOCKER_HOST="unix://$HOME/.dory/dory.sock"
fi

free_space() {
    df -h / | awk 'NR==2 {print $4}'
}

run() {
    if ! command -v "$1" >/dev/null 2>&1; then
        echo "skip: $1 not found"
        return
    fi
    echo "==> $*"
    "$@" || echo "warn: '$*' failed (exit $?)"
}

echo "### $(date '+%F %T') start (free: $(free_space))"

run go clean -cache
rm -rf "$HOME/Library/Caches/goimports"
# 動作中の uvx (MCP サーバー等) がロックを握っていることがあるので待ち時間を短くする
UV_LOCK_TIMEOUT=60 run uv cache prune
run brew cleanup -s --prune=all
run pnpm store prune
run npm cache clean --force
# mise prune はキャッシュではなく、どの config からも参照されていないツールのバージョンを削除する (再インストールにネットワークが必要)
# --quiet: 非 TTY でも進捗バーが行ごとにログへ出力されるのを抑える (エラーは出る)
run mise prune -y --quiet
if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
    run docker image prune -f
    run docker builder prune -f
else
    echo "skip: docker daemon is not running"
fi

echo "### $(date '+%F %T') done (free: $(free_space))"
