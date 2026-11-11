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

test_dangerous_command_guard() {
    local hook="$HOME/.claude/hooks/dangerous-command-guard.sh" out
    run_hook() {
        jq -n --arg c "$1" '{tool_input: {command: $c}}' | bash "$hook" || echo "hook exit $?"
    }
    out=$(run_hook 'cd /tmp && rm -fr foo')
    if [ "$(printf '%s' "$out" | jq -r '.hookSpecificOutput.permissionDecision')" = "deny" ]; then
        pass "dangerous-command-guard: 複合コマンド内の rm -fr は deny"
    else
        fail "dangerous-command-guard: 'rm -fr' が deny にならない (出力: $out)"
    fi
    out=$(run_hook 'git reset --hard')
    if [ "$(printf '%s' "$out" | jq -r '.hookSpecificOutput.permissionDecision')" = "ask" ]; then
        pass "dangerous-command-guard: git reset --hard は ask"
    else
        fail "dangerous-command-guard: 'git reset --hard' が ask にならない (出力: $out)"
    fi
    out=$(run_hook 'git log --oneline')
    [ -z "$out" ] && pass "dangerous-command-guard: 通常のコマンドは無出力" \
        || fail "dangerous-command-guard: 通常のコマンドなのに出力がある: $out"
}

test_idempotent() {
    chezmoi apply --no-tty
    local diff
    # 毎回実行する run_after_ スクリプトは常に差分として出るので除外する (ファイルの冪等性だけ見る)
    diff=$(chezmoi diff --no-pager --exclude=scripts 2>&1 || true)
    if [ -z "$diff" ]; then
        pass "2 回目の chezmoi apply 後に chezmoi diff が空 (scripts を除く)"
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
    jq -e '[.hooks.PreToolUse[]?.hooks[]?.command] | any(endswith("dangerous-command-guard.sh"))' "$settings" >/dev/null \
        && pass "settings.json: リポジトリ管理の hook (dangerous-command-guard) も入っている" \
        || fail "settings.json: dangerous-command-guard hook が無い"
    local dup
    dup=$(jq '[.hooks.PreToolUse[]?.hooks[]?.command | select(endswith("find-guard.sh"))] | length' "$settings")
    [ "$dup" = 1 ] && pass "settings.json: 繰り返し apply しても find-guard hook が重複しない" \
        || fail "settings.json: find-guard hook が ${dup} 個ある"
    dup=$(jq '[.hooks.PreToolUse[]?.hooks[]?.command | select(endswith("dangerous-command-guard.sh"))] | length' "$settings")
    [ "$dup" = 1 ] && pass "settings.json: 繰り返し apply しても dangerous-command-guard hook が重複しない" \
        || fail "settings.json: dangerous-command-guard hook が ${dup} 個ある"
}

# privateRepo (bare) を使って一時 HOME を init し、2 回 apply する (1 回目は private clone より後に処理されるものがあるため)
# 引数: <home> <bare> <machineProfile>。出力 (スクリプトの警告を含む) は <home>.log に残す
private_init_home() {
    local home="$1" bare="$2" profile="$3"
    mkdir -p "$home/.config/chezmoi"
    printf '[data]\n    privateRepo = "file://%s"\n    machineProfile = "%s"\n' "$bare" "$profile" > "$home/.config/chezmoi/chezmoi.toml"
    : > "$home.log"
    for _ in 1 2; do
        # 1 回目・2 回目の警告をどちらも残す (追記)
        # CI=1: ローカルで E2E_ALLOW_LOCAL=1 実行しても、実機の brew bundle と launchctl bootstrap が走らないようにする
        CI=1 HOME="$home" XDG_CONFIG_HOME="$home/.config" chezmoi init --apply --no-tty --source "$REPO_ROOT" >>"$home.log" 2>&1 || return 1
    done
}

# ~/.aws/config の種類を返す: link (シンボリックリンク) / file (実ファイル) / none (無い)
aws_config_kind() {
    if [ -L "$1" ]; then echo link; elif [ -f "$1" ]; then echo file; else echo none; fi
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
    printf '[default]\nlogin_session = e2e-personal-default\n[profile e2e-personal]\nregion = ap-northeast-1\n# e2e-private-aws-personal\n' > "$seed/aws/config"
    printf '[default]\noutput = e2e-work-default\n[profile e2e-work]\nregion = ap-northeast-1\n# e2e-private-aws-work\n' > "$seed/aws/config.work"
    printf '// e2e-private-ccgate\n{ provider: { name: "anthropic" } }\n' > "$seed/claude/ccgate.jsonnet"
    echo 'brew "e2e-private-common"' > "$seed/Brewfile"
    echo 'brew "e2e-profile-work"' > "$seed/Brewfile.work"
    echo 'brew "e2e-profile-personal"' > "$seed/Brewfile.personal"
    mkdir -p "$seed/mise"
    printf '[tools]\njq = "1.7.1"\n' > "$seed/mise/config.toml"
    printf '[tools]\nyq = "4.44.3"\n' > "$seed/mise/config.work.toml"
    printf '[tools]\nfd = "10.2.0"\n' > "$seed/mise/config.personal.toml"
    git -C "$seed" init -q -b main
    git -C "$seed" add -A
    git -C "$seed" -c user.name=e2e -c user.email=e2e@example.com commit -q -m seed
    git clone -q --bare "$seed" "$bare"

    (
        # CI=1: brew bundle / launchctl bootstrap をスキップさせる (private_init_home と同じ理由。このサブシェルに閉じる)
        export HOME="$private_home" XDG_CONFIG_HOME="$private_home/.config" TMUX=dummy TERM=xterm-256color CI=1
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
        # private-links (AWS): machineProfile = work で aws/config.work があれば、aws/config と結合した実ファイル (600) を作る
        if [ "$(aws_config_kind "$HOME/.aws/config")" = file ] \
            && [ -n "$(find "$HOME/.aws/config" -maxdepth 0 -perm 600)" ] \
            && grep -q '^# e2e-private-aws-work$' "$HOME/.aws/config" \
            && grep -q '^# e2e-private-aws-personal$' "$HOME/.aws/config" \
            && [ "$(grep -c '^\[default\]$' "$HOME/.aws/config")" = 1 ] \
            && grep -q 'e2e-work-default' "$HOME/.aws/config" \
            && ! grep -q 'e2e-personal-default' "$HOME/.aws/config"; then
            pass "private: machineProfile = work で aws/config と aws/config.work が 600 の実ファイルに結合される ([default] は 1 つ)"
        else
            fail "private: machineProfile = work の ~/.aws/config の結合結果が想定と違う"; rc=1
        fi
        # private-links (AWS): machineProfile = personal は従来どおり aws/config をリンクし、aws/config.work は使わない
        local home_personal="$TMP_ROOT/personal-home"
        if private_init_home "$home_personal" "$bare" personal \
            && [ "$(aws_config_kind "$home_personal/.aws/config")" = link ] \
            && [ "$(readlink "$home_personal/.aws/config")" = "$home_personal/.config/private/aws/config" ] \
            && ! grep -q 'e2e-private-aws-work' "$home_personal/.aws/config"; then
            pass "private: machineProfile = personal は aws/config を ~/.aws/config にリンクする (aws/config.work は使わない)"
        else
            fail "private: machineProfile = personal の ~/.aws/config がリンクになっていない"; rc=1
        fi
        # private-links (AWS): personal → work に切り替えると、以前のリンクは結合ファイルに置き換わる
        if private_init_home "$home_personal" "$bare" work \
            && [ "$(aws_config_kind "$home_personal/.aws/config")" = file ] \
            && grep -q '^# e2e-private-aws-work$' "$home_personal/.aws/config"; then
            pass "private: personal → work への切り替えで、以前のリンクが結合ファイルに置き換わる"
        else
            fail "private: personal → work への切り替えで ~/.aws/config が結合ファイルに置き換わらない"; rc=1
        fi
        # private-links (AWS): 既存の実ファイルは上書きせず、スキップを警告する
        local home_existing="$TMP_ROOT/existing-home"
        mkdir -p "$home_existing/.aws"
        echo '# e2e-existing-config' > "$home_existing/.aws/config"
        if private_init_home "$home_existing" "$bare" work \
            && [ "$(aws_config_kind "$home_existing/.aws/config")" = file ] \
            && grep -qx '# e2e-existing-config' "$home_existing/.aws/config" \
            && grep -q 'private 側の定義と異なるためスキップ' "$home_existing.log"; then
            pass "private: 既存の ~/.aws/config 実ファイルを上書きせず、スキップを警告する"
        else
            fail "private: 既存の ~/.aws/config 実ファイルを上書きした、または警告が出ない"; rc=1
        fi
        # private-links (AWS): 両方に同じセクション名があれば生成せず警告する (AWS CLI は重複セクションで失敗するため)
        local dup_seed="$TMP_ROOT/dup-seed" dup_bare="$TMP_ROOT/dup.git" home_dup="$TMP_ROOT/dup-home"
        cp -R "$seed" "$dup_seed"
        printf '[profile e2e-personal]\nregion = us-east-1\n' >> "$dup_seed/aws/config.work"
        git -C "$dup_seed" -c user.name=e2e -c user.email=e2e@example.com commit -q -am dup
        git clone -q --bare "$dup_seed" "$dup_bare"
        if private_init_home "$home_dup" "$dup_bare" work \
            && [ "$(aws_config_kind "$home_dup/.aws/config")" = none ] \
            && grep -q '重複' "$home_dup.log"; then
            pass "private: 重複セクションがあれば ~/.aws/config を生成せず警告する"
        else
            fail "private: 重複セクションがあるのに ~/.aws/config を生成した、または警告が出ない"; rc=1
        fi
        # private-links (AWS): machineProfile = work でも aws/config.work が無ければ従来どおり aws/config をリンクする
        local nowork_seed="$TMP_ROOT/nowork-seed" nowork_bare="$TMP_ROOT/nowork.git" home_nowork="$TMP_ROOT/nowork-home"
        cp -R "$seed" "$nowork_seed"
        git -C "$nowork_seed" rm -q aws/config.work
        git -C "$nowork_seed" -c user.name=e2e -c user.email=e2e@example.com commit -q -m nowork
        git clone -q --bare "$nowork_seed" "$nowork_bare"
        if private_init_home "$home_nowork" "$nowork_bare" work \
            && [ "$(aws_config_kind "$home_nowork/.aws/config")" = link ]; then
            pass "private: aws/config.work が無い work マシンは aws/config をリンクする"
        else
            fail "private: aws/config.work が無い work マシンで ~/.aws/config がリンクにならない"; rc=1
        fi
        # private-links (ccgate): claude/ccgate.jsonnet を ~/.claude/ccgate.jsonnet へシンボリックリンクする
        if [ -L "$HOME/.claude/ccgate.jsonnet" ] \
            && [ "$(readlink "$HOME/.claude/ccgate.jsonnet")" = "$HOME/.config/private/claude/ccgate.jsonnet" ] \
            && grep -qx '// e2e-private-ccgate' "$HOME/.claude/ccgate.jsonnet"; then
            pass "private: claude/ccgate.jsonnet が ~/.claude/ccgate.jsonnet へのシンボリックリンクになる"
        else
            fail "private: ~/.claude/ccgate.jsonnet が private/claude/ccgate.jsonnet へのリンクになっていない"; rc=1
        fi
        # private-links: 配置先を消しても次の apply で復元される (run_onchange_ ではなく run_after_ で毎回実行するため)
        rm -f "$HOME/.claude/ccgate.jsonnet" "$HOME/.aws/config"
        if chezmoi apply --no-tty >/dev/null \
            && [ -L "$HOME/.claude/ccgate.jsonnet" ] \
            && [ "$(readlink "$HOME/.claude/ccgate.jsonnet")" = "$HOME/.config/private/claude/ccgate.jsonnet" ] \
            && [ "$(aws_config_kind "$HOME/.aws/config")" = file ] \
            && grep -q '^# e2e-private-aws-work$' "$HOME/.aws/config"; then
            pass "private: 消した ~/.claude/ccgate.jsonnet (リンク) と ~/.aws/config (結合ファイル) が次の apply で復元される"
        else
            fail "private: ~/.claude/ccgate.jsonnet と ~/.aws/config を消したあとの apply で復元されない"; rc=1
        fi
        # private-links (ccgate): 既存の実ファイルは上書きせず、スキップを警告する
        local home_ccgate="$TMP_ROOT/ccgate-home"
        mkdir -p "$home_ccgate/.claude"
        echo '// e2e-existing-ccgate' > "$home_ccgate/.claude/ccgate.jsonnet"
        if private_init_home "$home_ccgate" "$bare" work \
            && [ -f "$home_ccgate/.claude/ccgate.jsonnet" ] && [ ! -L "$home_ccgate/.claude/ccgate.jsonnet" ] \
            && grep -qx '// e2e-existing-ccgate' "$home_ccgate/.claude/ccgate.jsonnet" \
            && grep -qF "$home_ccgate/.claude/ccgate.jsonnet が既に存在するためスキップ" "$home_ccgate.log"; then
            pass "private: 既存の ~/.claude/ccgate.jsonnet 実ファイルを上書きせず、スキップを警告する"
        else
            fail "private: 既存の ~/.claude/ccgate.jsonnet 実ファイルを上書きした、または警告が出ない"; rc=1
        fi
        # private-links (mise): conf.d に 公開 00-common.toml (実ファイル) と private のリンクが並ぶ。
        # machineProfile (work) と一致しない config.personal.toml はリンクされない
        local mise_d="$HOME/.config/mise/conf.d" mise_p="$HOME/.config/private/mise"
        if [ -f "$mise_d/00-common.toml" ] && [ ! -L "$mise_d/00-common.toml" ] \
            && [ "$(readlink "$mise_d/10-private.toml")" = "$mise_p/config.toml" ] \
            && [ "$(readlink "$mise_d/20-private-work.toml")" = "$mise_p/config.work.toml" ] \
            && [ ! -e "$mise_d/20-private-personal.toml" ] && [ ! -L "$mise_d/20-private-personal.toml" ]; then
            pass "private: mise の 00-common.toml (実ファイル) と private の config.toml / config.<profile>.toml (リンク) が conf.d に配置される"
        else
            fail "private: mise の conf.d の配置が想定と違う (00-common 実ファイル / 10-private / 20-private-<profile> / 一致しない profile は無し)"; rc=1
        fi
        # private-links (mise): profile を変えて残った private 向けの古いリンクだけ消し、実ファイルと private 以外へのリンクには触らない
        ln -s "$mise_p/config.personal.toml" "$mise_d/20-private-personal.toml"
        echo '[tools]' > "$mise_d/30-local.toml"
        ln -s /etc/hosts "$mise_d/40-foreign.toml"
        if chezmoi apply --no-tty >/dev/null \
            && [ ! -e "$mise_d/20-private-personal.toml" ] && [ ! -L "$mise_d/20-private-personal.toml" ] \
            && [ -f "$mise_d/30-local.toml" ] && [ ! -L "$mise_d/30-local.toml" ] \
            && [ "$(readlink "$mise_d/40-foreign.toml")" = /etc/hosts ] \
            && [ -L "$mise_d/10-private.toml" ] && [ -L "$mise_d/20-private-work.toml" ]; then
            pass "private: mise の conf.d で、古い private 向けリンクだけが消え、実ファイルと他を指すリンクは残る"
        else
            fail "private: mise の conf.d の掃除で、古いリンクが残った、または関係ないファイルを消した"; rc=1
        fi
        rm -f "$mise_d/30-local.toml" "$mise_d/40-foreign.toml"
        # private-links (mise): 消したリンクが次の apply で復元される
        rm -f "$mise_d/10-private.toml" "$mise_d/20-private-work.toml"
        if chezmoi apply --no-tty >/dev/null \
            && [ "$(readlink "$mise_d/10-private.toml")" = "$mise_p/config.toml" ] \
            && [ "$(readlink "$mise_d/20-private-work.toml")" = "$mise_p/config.work.toml" ]; then
            pass "private: 消した mise の conf.d のリンクが次の apply で復元される"
        else
            fail "private: 消した mise の conf.d のリンクが次の apply で復元されない"; rc=1
        fi
        # tools-mise-install: 公開 / private / 一致する profile の定義の hash が埋め込まれ、一致しない profile は含まれない
        # (mise install の発火条件。CI=1 ではスクリプト自体がスキップされるのでレンダリング結果だけを見る)
        local mise_tmpl="$REPO_ROOT/home/.chezmoiscripts/run_onchange_after_tools-mise-install.sh.tmpl" mise_rendered
        if mise_rendered=$(chezmoi execute-template --source "$REPO_ROOT" < "$mise_tmpl") \
            && grep -qF "# common hash: $(shasum -a 256 "$REPO_ROOT/home/dot_config/mise/conf.d/00-common.toml" | cut -d' ' -f1)" <<< "$mise_rendered" \
            && grep -qF "# private hash: $(shasum -a 256 "$mise_p/config.toml" | cut -d' ' -f1)" <<< "$mise_rendered" \
            && grep -qF "# private work hash: $(shasum -a 256 "$mise_p/config.work.toml" | cut -d' ' -f1)" <<< "$mise_rendered" \
            && ! grep -q 'personal' <<< "$mise_rendered"; then
            pass "private: tools-mise-install に公開 / private / 一致する profile の hash が埋め込まれる"
        else
            fail "private: tools-mise-install の hash 埋め込みが想定と違う (公開 / private / 一致する profile、一致しない profile は無し)"; rc=1
        fi
        # brew-bundle: machineProfile と一致する Brewfile.<profile> だけがスクリプトに含まれる
        # (macOS 専用のスクリプト。Linux ではテンプレートが空になる。CI では brew bundle 自体はスキップされるのでレンダリング結果だけを見る)
        if [ "$(uname -s)" = Darwin ]; then
            local tmpl="$REPO_ROOT/home/.chezmoiscripts/run_onchange_after_brew-bundle.sh.tmpl" rendered order want_hash
            if rendered=$(chezmoi execute-template --source "$REPO_ROOT" < "$tmpl"); then
                if grep -q '^brew bundle .*/\.config/private/Brewfile\.work"$' <<< "$rendered"; then
                    pass "private: brew-bundle が Brewfile.<machineProfile> を bundle する"
                else
                    fail "private: brew-bundle に Brewfile.<machineProfile> が含まれない"; rc=1
                fi
                # 適用順: 公開 Brewfile → private Brewfile → private Brewfile.<profile>
                order=$(sed -n 's/^brew bundle .*--file="\(.*\)"$/\1/p' <<< "$rendered" \
                    | sed -e 's|^.*/\.config/private/|private:|' -e 's|^.*/Brewfile$|public:Brewfile|' | paste -sd' ' -)
                if [ "$order" = "public:Brewfile private:Brewfile private:Brewfile.work" ]; then
                    pass "private: brew-bundle の適用順が 公開 → private → private profile になっている"
                else
                    fail "private: brew-bundle の適用順が想定と違う: ${order}"; rc=1
                fi
                # 変更検知用の hash がコメントに埋め込まれている (run_onchange の発火条件)
                want_hash=$(shasum -a 256 "$HOME/.config/private/Brewfile.work" | cut -d' ' -f1)
                if grep -qF "# private Brewfile.work hash: $want_hash" <<< "$rendered"; then
                    pass "private: brew-bundle に Brewfile.<machineProfile> の hash が埋め込まれる"
                else
                    fail "private: brew-bundle に Brewfile.<machineProfile> の hash が無い"; rc=1
                fi
                # machineProfile と一致しない profile の Brewfile は含まれない
                if grep -q 'Brewfile\.personal' <<< "$rendered"; then
                    fail "private: 一致しない profile の Brewfile が brew-bundle に含まれている"; rc=1
                else
                    pass "private: 一致しない profile の Brewfile は brew-bundle に含まれない"
                fi
            else
                fail "private: brew-bundle テンプレートのレンダリングに失敗"; rc=1
            fi
            # machineProfile が空 / 未設定 (古い chezmoi.toml) でもエラーにならず、profile 別 Brewfile は含まれない
            local data cfg
            for data in 'machineProfile = ""' 'privateRepo = ""'; do
                cfg="$TMP_ROOT/brew-profile.toml"
                printf 'sourceDir = "%s"\n[data]\n    %s\n' "$REPO_ROOT" "$data" > "$cfg"
                if rendered=$(chezmoi -c "$cfg" execute-template --source "$REPO_ROOT" < "$tmpl") \
                    && ! grep -q 'Brewfile\.' <<< "$rendered"; then
                    pass "private: brew-bundle は [data] が ${data} だと profile 別 Brewfile をスキップする"
                else
                    fail "private: brew-bundle が [data] ${data} でエラー、または profile 別 Brewfile を含む"; rc=1
                fi
            done
        else
            echo "skip: private: brew-bundle のレンダリング確認は macOS のみ"
        fi
        exit "$rc"
    ) || FAILED=1
}

ALL_TESTS=(zsh tmux git find_guard dangerous_command_guard idempotent settings_preserved private_layer)
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
