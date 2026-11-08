#!/usr/bin/env bash
# E2E テスト: chezmoi apply 後に、配置された設定が実際にツールから読み込めるかを検証する
#
# 使い方: tests/e2e.sh <テスト名>...   (引数なしで全テスト)
#   前提: `chezmoi init --apply` 済みの $HOME で実行する (CI の test.yml を参照)。
#   private-layer だけは一時的な HOME を作って自前で init するので、他の状態に依存しない。
#
# 注意: テストは $HOME 配下の ~/.claude/settings.json を書き換えるので、手元の実環境では実行しないこと。
set -euo pipefail

if [ -z "${CI:-}" ] && [ -z "${E2E_ALLOW_LOCAL:-}" ]; then
    echo "このテストは実環境の ~/.claude/settings.json 等を書き換えます。CI 以外で実行する場合は E2E_ALLOW_LOCAL=1 を指定してください" >&2
    exit 2
fi

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FAILED=0

pass() { echo "ok: $*"; }
fail() { echo "FAIL: $*" >&2; FAILED=1; }

# 一時ディレクトリ (終了時にまとめて削除)
TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

# tty 無しの CI では zsh -i が "can't open terminal" で失敗するので、擬似端末 (pty) を与えて実行する
# (stdout / stderr は端末に混ざって 1 本の出力になる。終了コードは zsh のもの。引数: zsh -c に渡すコマンド)
zsh_pty() {
    python3 -I - "$1" <<'PY'
import os, pty, sys
pid, fd = pty.fork()
if pid == 0:
    os.execvp("zsh", ["zsh", "-i", "-c", sys.argv[1]])
out = b""
while True:
    try:
        data = os.read(fd, 4096)
    except OSError:
        break
    if not data:
        break
    out += data
_, status = os.waitpid(pid, 0)
sys.stdout.write(out.decode(errors="replace"))
sys.exit(os.waitstatus_to_exitcode(status))
PY
}

# CI の Linux runner は一部ディレクトリが group-writable で compinit が "insecure directories" で止まるので直す
fix_compaudit() {
    [ -n "${CI:-}" ] || return 0
    local d
    # compaudit は問題があると非ゼロを返すので、pipefail / set -e で落ちないようにする
    { zsh -f -c 'autoload -U compaudit; compaudit' 2>/dev/null || true; } | while read -r d; do
        sudo chmod go-w "$d" 2>/dev/null || true
    done || true
}

test_zsh() {
    command -v zsh >/dev/null || { fail "zsh がインストールされていない"; return; }
    # command.zsh の tmux 自動起動を避ける
    export TMUX=dummy
    fix_compaudit
    # `exit` だけだと .zshrc 末尾のコマンドの終了ステータスが返るので `exit 0` で起動の成否だけを見る
    # 初回は zimfw がモジュールをネットワークから取得するので、ウォームアップとして 1 回流す (計測しない)
    zsh_pty 'exit 0' >/dev/null 2>&1 || true

    local out="$TMP_ROOT/zsh.out" start end
    start=$(date +%s)
    if zsh_pty 'exit 0' >"$out" 2>&1; then
        end=$(date +%s)
        pass "zsh -i -c exit は終了コード 0 ($((end - start)) 秒)"
    else
        fail "zsh -i -c exit が失敗: $(cat "$out")"
        return
    fi
    if [ -n "$(tr -d '[:space:]' < "$out")" ]; then
        fail "zsh -i -c exit の出力が空でない:"
        cat "$out" >&2
    else
        pass "zsh -i -c exit の出力 (stderr 含む) は空"
    fi
}

test_tmux() {
    command -v tmux >/dev/null || { fail "tmux がインストールされていない"; return; }
    export TERM=xterm-256color
    local sock="e2e-$$" err="$TMP_ROOT/tmux.err"
    # start-server だけでは設定が評価されない (セッションが無いとすぐ終了する) ので detached セッションを作る
    if ! tmux -L "$sock" -f "$HOME/.tmux.conf" new-session -d -s e2e 2>"$err"; then
        fail "tmux の起動に失敗: $(cat "$err")"
        return
    fi
    # 設定のエラーは source-file が stderr / 終了コードで返す
    if tmux -L "$sock" source-file "$HOME/.tmux.conf" 2>"$err" && [ ! -s "$err" ]; then
        pass ".tmux.conf をエラーなく読み込めた"
    else
        fail ".tmux.conf の読み込みでエラー: $(cat "$err")"
    fi
    tmux -L "$sock" kill-server 2>/dev/null || true
}

test_git() {
    local err="$TMP_ROOT/git.err"
    if git config --list --show-origin >/dev/null 2>"$err" && [ ! -s "$err" ]; then
        pass "git が ~/.gitconfig をエラーなく読み込めた"
    else
        fail "git の設定読み込みでエラー: $(cat "$err")"
    fi
}

test_find_guard() {
    local hook="$HOME/.claude/hooks/find-guard.sh" out
    run_hook() {
        jq -n --arg c "$1" '{tool_input: {command: $c}}' | bash "$hook" || echo "hook exit $?"
    }
    out=$(run_hook 'find / -name foo')
    if [ "$(printf '%s' "$out" | jq -r '.hookSpecificOutput.permissionDecision')" = "ask" ]; then
        pass "find-guard: 広範囲の find は ask"
    else
        fail "find-guard: 'find /' が ask にならない (出力: $out)"
    fi
    out=$(run_hook 'find /usr -maxdepth 2 -name foo')
    [ -z "$out" ] && pass "find-guard: -maxdepth 付きの find は無出力" \
        || fail "find-guard: -maxdepth 付きなのに出力がある: $out"
    out=$(run_hook 'find ./src -name foo')
    [ -z "$out" ] && pass "find-guard: 絞った find は無出力" \
        || fail "find-guard: 絞った find なのに出力がある: $out"
    out=$(run_hook 'ls /')
    [ -z "$out" ] && pass "find-guard: find 以外は無出力" \
        || fail "find-guard: find 以外なのに出力がある: $out"
}

test_idempotent() {
    chezmoi apply --no-tty
    local diff
    diff=$(chezmoi diff --no-pager 2>&1 || true)
    if [ -z "$diff" ]; then
        pass "2 回目の chezmoi apply 後に chezmoi diff が空"
    else
        fail "冪等でない。chezmoi diff:"
        echo "$diff" >&2
    fi
}

test_settings_preserved() {
    local settings="$HOME/.claude/settings.json"
    # Claude Code や他のアプリが書き込んだ状態を再現する
    jq '. + {e2eLocalKey: "keep"}
        | .permissions.allow += ["Bash(e2e-local-allow *)"]
        | .hooks.PreToolUse += [{matcher: "Bash", hooks: [{type: "command", command: "/e2e/local-hook.sh"}]}]' \
        "$settings" > "$TMP_ROOT/settings.json"
    cp "$TMP_ROOT/settings.json" "$settings"

    chezmoi apply --no-tty

    jq -e '.e2eLocalKey == "keep"' "$settings" >/dev/null \
        && pass "settings.json: ローカルのトップレベルキーが保持される" \
        || fail "settings.json: ローカルのキーが消えた"
    jq -e '.permissions.allow | index("Bash(e2e-local-allow *)")' "$settings" >/dev/null \
        && pass "settings.json: ローカルの permissions が保持される" \
        || fail "settings.json: ローカルの permissions が消えた"
    jq -e '[.hooks.PreToolUse[]?.hooks[]?.command] | index("/e2e/local-hook.sh")' "$settings" >/dev/null \
        && pass "settings.json: ローカルの hook が保持される" \
        || fail "settings.json: ローカルの hook が消えた"
    jq -e '[.hooks.PreToolUse[]?.hooks[]?.command] | any(endswith("find-guard.sh"))' "$settings" >/dev/null \
        && pass "settings.json: リポジトリ管理の hook (find-guard) も入っている" \
        || fail "settings.json: find-guard hook が無い"
    local dup
    dup=$(jq '[.hooks.PreToolUse[]?.hooks[]?.command | select(endswith("find-guard.sh"))] | length' "$settings")
    [ "$dup" = 1 ] && pass "settings.json: 繰り返し apply しても hook が重複しない" \
        || fail "settings.json: find-guard hook が ${dup} 個ある"
}

test_private_layer() {
    # 一時 HOME に閉じた環境で、ダミーの privateRepo (ローカルの bare リポジトリ) を使って init する
    local private_home="$TMP_ROOT/private-home" seed="$TMP_ROOT/private-seed" bare="$TMP_ROOT/private.git"
    mkdir -p "$private_home" "$seed/zsh" "$seed/claude" "$seed/aws"
    echo 'export E2E_PRIVATE_LAYER=loaded' > "$seed/zsh/e2e.zsh"
    printf '[e2e]\n\tprivatelayer = loaded\n' > "$seed/gitconfig"
    echo 'set -g @e2e-private-layer loaded' > "$seed/tmux.conf"
    echo '{"permissions":{"allow":["Bash(e2e-private-allow *)"]}}' > "$seed/claude/settings.json"
    echo '{"permissions":{"allow":["Bash(e2e-profile-allow *)"]}}' > "$seed/claude/settings.work.json"
    echo '{"permissions":{"allow":["Bash(e2e-other-profile *)"]}}' > "$seed/claude/settings.personal.json"
    printf '[profile e2e]\nregion = ap-northeast-1\n# e2e-private-aws\n' > "$seed/aws/config"
    git -C "$seed" init -q -b main
    git -C "$seed" add -A
    git -C "$seed" -c user.name=e2e -c user.email=e2e@example.com commit -q -m seed
    git clone -q --bare "$seed" "$bare"

    (
        export HOME="$private_home" XDG_CONFIG_HOME="$private_home/.config" TMUX=dummy TERM=xterm-256color
        unset ZDOTDIR
        # promptStringOnce は既存の data を優先するので、事前に chezmoi.toml へ privateRepo と machineProfile を書いておく
        mkdir -p "$XDG_CONFIG_HOME/chezmoi"
        printf '[data]\n    privateRepo = "file://%s"\n    machineProfile = "work"\n' "$bare" > "$XDG_CONFIG_HOME/chezmoi/chezmoi.toml"
        chezmoi init --apply --no-tty --source "$REPO_ROOT" >/dev/null \
            || { fail "private: chezmoi init --apply に失敗"; exit 1; }
        # 初回 apply では .claude/settings.json (modify) が ~/.config/private の clone より先に処理されるため、
        # private settings がマージされるのは 2 回目の apply 以降 (chezmoi update 等で自然に解消する)
        chezmoi apply --no-tty >/dev/null || { fail "private: 2 回目の chezmoi apply に失敗"; exit 1; }
        local rc=0

        [ -f "$HOME/.config/private/gitconfig" ] || { fail "private: ~/.config/private が clone されていない"; exit 1; }
        pass "private: ~/.config/private に privateRepo が clone された"

        # zsh: private の *.zsh が source される
        if zsh_pty 'echo private-layer=$E2E_PRIVATE_LAYER' 2>&1 | grep -q 'private-layer=loaded'; then
            pass "private: zsh が private/zsh/*.zsh を読み込む"
        else
            fail "private: zsh が private/zsh/*.zsh を読み込まない"; rc=1
        fi
        # git: include される
        if [ "$(git config --get e2e.privatelayer || true)" = loaded ]; then
            pass "private: git が private/gitconfig を読み込む"
        else
            fail "private: git が private/gitconfig を読み込まない"; rc=1
        fi
        # tmux: source-file される
        local sock="e2e-private-$$"
        tmux -L "$sock" -f "$HOME/.tmux.conf" new-session -d -s e2e 2>/dev/null || true
        if [ "$(tmux -L "$sock" show-options -gv @e2e-private-layer 2>/dev/null || true)" = loaded ]; then
            pass "private: tmux が private/tmux.conf を読み込む"
        else
            fail "private: tmux が private/tmux.conf を読み込まない"; rc=1
        fi
        tmux -L "$sock" kill-server 2>/dev/null || true
        # claude: settings.json にマージされる
        if jq -e '.permissions.allow | index("Bash(e2e-private-allow *)")' "$HOME/.claude/settings.json" >/dev/null; then
            pass "private: settings.json に private/claude/settings.json がマージされる"
        else
            fail "private: settings.json に private/claude/settings.json がマージされない"; rc=1
        fi
        # claude: machineProfile と一致する settings.<profile>.json だけがマージされる
        if jq -e '.permissions.allow | index("Bash(e2e-profile-allow *)")' "$HOME/.claude/settings.json" >/dev/null; then
            pass "private: settings.<machineProfile>.json がマージされる"
        else
            fail "private: settings.<machineProfile>.json がマージされない"; rc=1
        fi
        if jq -e '.permissions.allow | index("Bash(e2e-other-profile *)")' "$HOME/.claude/settings.json" >/dev/null; then
            fail "private: 一致しない profile の settings がマージされている"; rc=1
        else
            pass "private: 一致しない profile の settings はマージされない"
        fi
        # private-links: aws/config が ~/.aws/config にリンクされる
        if [ -L "$HOME/.aws/config" ] && grep -q 'e2e-private-aws' "$HOME/.aws/config"; then
            pass "private: private/aws/config が ~/.aws/config にリンクされる"
        else
            fail "private: private/aws/config が ~/.aws/config にリンクされない"; rc=1
        fi
        exit "$rc"
    ) || FAILED=1
}

ALL_TESTS=(zsh tmux git find_guard idempotent settings_preserved private_layer)
if [ "$#" -eq 0 ]; then
    set -- "${ALL_TESTS[@]}"
fi
for t in "$@"; do
    echo "=== $t ==="
    "test_${t//-/_}"
done

if [ "$FAILED" -ne 0 ]; then
    echo "E2E テストに失敗したものがあります" >&2
    exit 1
fi
echo "E2E テスト: すべて成功"
