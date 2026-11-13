# dangerous-command-guard.sh から呼ばれるコマンド解析器。
#
# 入力: シェルコマンド文字列 (stdin)
# 出力: タブ区切り
#   D <優先度> <理由>   優先度 2=deny, 1=ask, 0=介入なし
#   G <サブコマンド>    git のサブコマンド (エイリアス解決用)
#   C <コマンド文字列>  入れ子のコマンド (bash -c / eval / find -exec)
#
# settings.base.json の permissions は前方一致でしか判定できないため、
# ここではユーザー入力のコマンド文字列を簡易的に解析して、
# 表記揺れ (rm -fr, rm -r -f) や複合コマンド (cd x && rm -rf y) を拾う。
#
# 注意: 完全なシェルパーサではない。変数展開や難読化されたコマンド、
# スクリプトファイルの中身までは追跡しない。

function emit(d, r) {
    if (d > best) {
        best = d
        best_reason = r
    }
}

function normalize(t,   n, a) {
    gsub(/^\\+/, "", t)
    n = split(t, a, "/")
    return a[n]
}

function token_present(args, want,   n, a, i) {
    n = split(args, a, " ")
    for (i = 1; i <= n; i++)
        if (a[i] == want)
            return 1
    return 0
}

function wrapper_name(t,   b) {
    b = normalize(t)
    if (b == "sudo" || b == "command" || b == "env" || b == "exec" || b == "nohup" || b == "nice" || b == "stdbuf" || b == "timeout" || b == "time" || b == "xargs")
        return b
    return ""
}

# ラッパーコマンドのオプションが引数を取るかどうか
function wrapper_opt_arg(w, t,   o, f) {
    if (t ~ /^--.*=/)
        return 0
    if (t ~ /^--/) {
        o = t
        if (w == "sudo")
            return (o == "--user" || o == "--group" || o == "--prompt" || o == "--host" || o == "--role" || o == "--type" || o == "--other-user" || o == "--chdir")
        if (w == "env")
            return (o == "--unset" || o == "--chdir" || o == "--split-string")
        if (w == "nice")
            return (o == "--adjustment")
        if (w == "timeout")
            return (o == "--signal" || o == "--kill-after")
        if (w == "xargs")
            return (o == "--replace" || o == "--max-args" || o == "--max-procs" || o == "--max-chars" || o == "--max-lines" || o == "--eof" || o == "--delimiter" || o == "--arg-file")
        if (w == "exec")
            return (o == "--argv0")
        return 0
    }
    if (t ~ /^-[^-]/) {
        f = substr(t, 2)
        # -n1 のような短オプション + 値の連結は次のトークンを消費しない
        if (length(f) > 1)
            return 0
        o = substr(t, 1, 2)
        if (w == "sudo")
            return (o ~ /^(-u|-g|-p|-C|-r|-t|-U|-D|-T)$/)
        if (w == "env")
            return (o ~ /^(-u|-C|-S)$/)
        if (w == "nice")
            return (o == "-n")
        if (w == "timeout")
            return (o ~ /^(-s|-k)$/)
        if (w == "xargs")
            return (o ~ /^(-I|-n|-P|-s|-L|-E|-d|-a)$/)
        if (w == "exec")
            return (o == "-a")
        return 0
    }
    return 0
}

# rm / git rm のフラグを調べる。gitmode=1 のときは --cached を考慮する。
function analyze_rm(args, gitmode,   n, a, i, t, f, rec, force, cached, stop) {
    rec = 0
    force = 0
    cached = 0
    stop = 0
    n = split(args, a, " ")
    for (i = 1; i <= n; i++) {
        t = a[i]
        if (stop)
            continue
        if (t == "--") {
            # -- 以降はファイル名なのでフラグとして扱わない
            stop = 1
            continue
        }
        if (t == "--recursive") {
            rec = 1
            continue
        }
        if (t == "--force") {
            force = 1
            continue
        }
        if (t == "--cached") {
            cached = 1
            continue
        }
        if (t ~ /^-[^-]/) {
            f = substr(t, 2)
            if (f ~ /[rR]/)
                rec = 1
            if (f ~ /f/)
                force = 1
        }
    }
    if (gitmode) {
        if (rec && force && !cached)
            emit(2, "git rm の再帰的強制削除 (rm -rf 相当) は禁止されています")
        else
            emit(1, "git rm はインデックスまたは作業ツリーを変更するため確認します")
    } else {
        if (rec && force)
            emit(2, "再帰的強制削除 (rm -rf 相当) は禁止されています")
        else
            emit(1, "rm はファイルを削除するため確認します")
    }
}

# git のグローバルオプションを読み飛ばしてサブコマンドを取り出す。
# 残りの引数はグローバル変数 g_rest に入れる。
function git_sub(args,   n, a, i, t, scmd, stop, skip) {
    g_rest = ""
    n = split(args, a, " ")
    scmd = ""
    stop = 0
    skip = 0
    for (i = 1; i <= n; i++) {
        t = a[i]
        if (scmd != "") {
            g_rest = g_rest (g_rest == "" ? "" : " ") t
            continue
        }
        if (skip) {
            skip = 0
            continue
        }
        if (t == "--") {
            stop = 1
            continue
        }
        if (stop) {
            scmd = t
            continue
        }
        if (t == "-C" || t == "-c" || t == "--git-dir" || t == "--work-tree" || t == "--namespace" || t == "--exec-path" || t == "--config-env" || t == "--super-prefix" || t == "--attr-source") {
            skip = 1
            continue
        }
        if (t ~ /^-/)
            continue
        scmd = t
    }
    return scmd
}

function analyze_clean(args,   n, a, i, t, f, dry, force) {
    dry = 0
    force = 0
    n = split(args, a, " ")
    for (i = 1; i <= n; i++) {
        t = a[i]
        if (t == "--dry-run" || t == "-n") {
            dry = 1
            continue
        }
        if (t == "--force") {
            force = 1
            continue
        }
        if (t ~ /^-[^-]/) {
            f = substr(t, 2)
            if (f ~ /[fF]/)
                force = 1
            if (f ~ /n/)
                dry = 1
        }
    }
    if (force && !dry)
        emit(1, "git clean -f は未追跡ファイルを削除するため確認します")
}

function analyze_checkout(args,   n, a, i, t) {
    n = split(args, a, " ")
    for (i = 1; i <= n; i++) {
        t = a[i]
        if (t == "--" || t == "." || t == "-f" || t == "--force") {
            emit(1, "git checkout の -- / . / -f は変更を破棄するため確認します")
            return
        }
    }
}

function analyze_push(args,   n, a, i, t, f) {
    n = split(args, a, " ")
    for (i = 1; i <= n; i++) {
        t = a[i]
        if (t == "--force" || t ~ /^--force-with-lease/ || t ~ /^--force-if-includes/) {
            emit(1, "git push の force 系オプションは履歴を書き換えるため確認します")
            return
        }
        if (t == "--delete" || t == "--mirror" || t == "--prune" || t ~ /^--prune=/) {
            emit(1, "git push の削除・mirror 系オプションはリモートの ref を消すため確認します")
            return
        }
        if (t ~ /^--/)
            continue
        if (t ~ /^-[^-]/) {
            f = substr(t, 2)
            if (f ~ /f/) {
                emit(1, "git push -f は履歴を書き換えるため確認します")
                return
            }
            if (f ~ /d/) {
                emit(1, "git push -d はリモートのブランチを消すため確認します")
                return
            }
            continue
        }
        # refspec の + は強制更新、先頭の : はリモート ref の削除
        if (t ~ /^\+/ || t ~ /^:/) {
            emit(1, "git push の refspec (+ / :) はリモートの ref を強制更新・削除するため確認します")
            return
        }
    }
    # 通常の push は settings.base.json の allow に従う (安全な push)
}

function analyze_branch(args,   n, a, i, t, f) {
    n = split(args, a, " ")
    for (i = 1; i <= n; i++) {
        t = a[i]
        if (t == "--delete" || t == "--move" || t == "--copy" || t == "--force") {
            emit(1, "git branch の削除・移動・強制更新はブランチを書き換えるため確認します")
            return
        }
        if (t ~ /^-[^-]/) {
            f = substr(t, 2)
            if (f ~ /[dDmMf]/) {
                emit(1, "git branch の削除・移動・強制更新はブランチを書き換えるため確認します")
                return
            }
        }
    }
}

function analyze_tag(args,   n, a, i, t, f) {
    n = split(args, a, " ")
    for (i = 1; i <= n; i++) {
        t = a[i]
        if (t == "--delete" || t == "--force") {
            emit(1, "git tag の削除・付け替えはタグを書き換えるため確認します")
            return
        }
        if (t ~ /^-[^-]/) {
            f = substr(t, 2)
            if (f ~ /[dDf]/) {
                emit(1, "git tag の削除・付け替えはタグを書き換えるため確認します")
                return
            }
        }
    }
}

# フラグを読み飛ばして最初の引数 (サブコマンド / アクション) を返す
function first_token(args,   n, a, i, t) {
    n = split(args, a, " ")
    for (i = 1; i <= n; i++) {
        t = a[i]
        if (t ~ /^-/)
            continue
        return t
    }
    return ""
}

function analyze_remote(args,   act) {
    act = first_token(args)
    if (act ~ /^(remove|rm|rename|set-url|set-head)$/)
        emit(1, "git remote の削除・付け替えは push 先を変えるため確認します")
}

function analyze_stash(args,   act) {
    act = first_token(args)
    if (act == "drop" || act == "clear")
        emit(1, "git stash の drop / clear は stash を失うため確認します")
}

# gh のグローバルオプションを読み飛ばしてサブコマンドを取り出す。
# 残りの引数はグローバル変数 g_rest に入れる。
function gh_sub(args,   n, a, i, t, scmd, skip) {
    g_rest = ""
    n = split(args, a, " ")
    scmd = ""
    skip = 0
    for (i = 1; i <= n; i++) {
        t = a[i]
        if (scmd != "") {
            g_rest = g_rest (g_rest == "" ? "" : " ") t
            continue
        }
        if (skip) {
            skip = 0
            continue
        }
        if (t == "-R" || t == "--repo") {
            skip = 1
            continue
        }
        if (t ~ /^-/)
            continue
        scmd = t
    }
    return scmd
}

# gh api の書き込み系フラグ (-X / --method / -f / -F / --field / --raw-field / --input)
function analyze_gh_api(args,   n, a, i, t) {
    n = split(args, a, " ")
    for (i = 1; i <= n; i++) {
        t = a[i]
        if (t ~ /^-X/ || t ~ /^--method/ || t == "-f" || t == "-F" || t ~ /^-f./ || t ~ /^-F./ || t ~ /^--field/ || t ~ /^--raw-field/ || t ~ /^--input/) {
            emit(1, "gh api の書き込み系オプション (-X / -f / --input など) は確認します")
            return
        }
    }
}

function analyze_gh(args,   scmd, rest, act) {
    scmd = gh_sub(args)
    rest = g_rest
    if (scmd == "")
        return
    if (scmd == "api") {
        analyze_gh_api(rest)
        return
    }
    act = first_token(rest)
    if (scmd == "auth") {
        # gh auth status は既定ではトークンを出さないので許可する
        if (act ~ /^(login|logout|token|refresh|setup-git|switch)$/)
            emit(2, "gh auth の認証情報を変更・表示する操作は禁止されています")
        else if (rest ~ /--show-token/)
            emit(2, "gh auth status --show-token はトークンを表示するため禁止されています")
    } else if (scmd == "gpg-key" || scmd == "ssh-key") {
        emit(2, "gh の鍵操作は禁止されています")
    } else if (scmd == "issue") {
        if (act == "delete")
            emit(2, "gh issue delete は issue を削除するため禁止されています")
        else if (act ~ /^(close|edit|comment)$/)
            emit(1, "gh issue の変更操作は確認します")
    } else if (scmd == "pr") {
        if (act == "delete")
            emit(2, "gh pr delete は PR を削除するため禁止されています")
        else if (act ~ /^(create|close|edit|comment|merge|review)$/)
            emit(1, "gh pr の変更操作は確認します")
    } else if (scmd == "release") {
        if (act == "delete")
            emit(2, "gh release delete はリリースを削除するため禁止されています")
    } else if (scmd == "repo") {
        if (act ~ /^(archive|create|delete|edit|fork|rename)$/)
            emit(2, "gh repo の作成・変更・削除は禁止されています")
    } else if (scmd == "secret") {
        if (act == "set" || act == "delete")
            emit(2, "gh secret の変更・削除は禁止されています")
    } else if (scmd == "variable") {
        if (act == "set" || act == "delete")
            emit(1, "gh variable の変更・削除は確認します")
    } else if (scmd == "workflow") {
        if (act == "enable" || act == "disable")
            emit(2, "gh workflow の有効化・無効化は禁止されています")
    }
}

# 機密ファイルのパスかどうか (Read ツールの deny と同じ対象 + credentials 系)
function sensitive_path(t) {
    if (t ~ /(^|\/)\.env($|rc|[.])/)
        return 1
    if (t ~ /(^|\/)\.ssh($|\/)/)
        return 1
    if (t ~ /(^|\/)\.aws($|\/)/)
        return 1
    if (t ~ /(^|\/)\.gnupg($|\/)/)
        return 1
    if (t ~ /(^|\/)\.netrc$/)
        return 1
    if (t ~ /(^|\/)\.git-credentials$/)
        return 1
    if (t ~ /(^|\/)\.npmrc$/)
        return 1
    if (t ~ /(^|\/)\.credentials\.json$/)
        return 1
    if (t ~ /(^|\/)gh\/hosts\.yml$/)
        return 1
    if (t ~ /(^|\/)\.docker\/config\.json$/)
        return 1
    if (t ~ /(^|\/)\.kube\/config$/)
        return 1
    return 0
}

# 機密ファイルを読むコマンドを検出する。
# skip_first=1 のときは最初の引数 (grep のパターン、sed / awk のスクリプト) を飛ばす。
function analyze_read_cmd(args, skip_first,   n, a, i, t, skipped) {
    n = split(args, a, " ")
    skipped = 0
    for (i = 1; i <= n; i++) {
        t = a[i]
        if (t ~ /^-/)
            continue
        if (skip_first && !skipped) {
            skipped = 1
            continue
        }
        if (sensitive_path(t)) {
            emit(1, "機密ファイル (.env / .ssh / .aws など) を読む可能性があるため確認します")
            return
        }
    }
}

function analyze_git(args,   scmd, rest) {
    scmd = git_sub(args)
    rest = g_rest
    if (scmd == "")
        return
    # エイリアス解決は呼び出し側 (bash) が行う
    aliases[scmd] = 1
    if (scmd == "rm") {
        analyze_rm(rest, 1)
    } else if (scmd == "reset") {
        if (token_present(rest, "--hard"))
            emit(1, "git reset --hard は未コミットの変更を破棄するため確認します")
    } else if (scmd == "clean") {
        analyze_clean(rest)
    } else if (scmd == "checkout") {
        analyze_checkout(rest)
    } else if (scmd == "restore") {
        emit(1, "git restore は作業ツリーの変更を破棄するため確認します")
    } else if (scmd == "push") {
        analyze_push(rest)
    } else if (scmd == "branch") {
        analyze_branch(rest)
    } else if (scmd == "tag") {
        analyze_tag(rest)
    } else if (scmd == "remote") {
        analyze_remote(rest)
    } else if (scmd == "stash") {
        analyze_stash(rest)
    } else if (scmd == "commit") {
        emit(1, "git commit は履歴を作成するため確認します")
    }
}

# bash -c / zsh -ic などに渡されたコマンド文字列を取り出す
function collect_shell_c(args,   n, a, i, rest) {
    n = split(args, a, " ")
    for (i = 1; i <= n; i++) {
        if (a[i] == "--")
            return
        if (a[i] ~ /^-[^-]/ && substr(a[i], 2) ~ /c/) {
            rest = ""
            for (i++; i <= n; i++)
                rest = rest (rest == "" ? "" : " ") a[i]
            if (rest != "")
                nested[++nested_n] = rest
            return
        }
    }
}

# find -exec / -execdir で実行されるコマンドを取り出す
function collect_find_exec(args,   n, a, i, j, rest) {
    n = split(args, a, " ")
    for (i = 1; i <= n; i++) {
        if (a[i] == "-exec" || a[i] == "-execdir" || a[i] == "-ok" || a[i] == "-okdir") {
            rest = ""
            for (j = i + 1; j <= n; j++) {
                if (a[j] == ";" || a[j] == "+")
                    break
                rest = rest (rest == "" ? "" : " ") a[j]
            }
            if (rest != "")
                nested[++nested_n] = rest
        }
    }
}

function finish_command() {
    if (cmdname == "rm")
        analyze_rm(args, 0)
    else if (cmdname == "mv")
        emit(1, "mv はファイルを移動するため確認します")
    else if (cmdname == "git")
        analyze_git(args)
    else if (cmdname == "gh")
        analyze_gh(args)
    else if (cmdname == "brew")
        emit(1, "brew はパッケージを変更するため確認します")
    else if (cmdname == "cat" || cmdname == "bat" || cmdname == "head" || cmdname == "tail" || cmdname == "less" || cmdname == "more" || cmdname == "base64" || cmdname == "xxd" || cmdname == "od" || cmdname == "strings" || cmdname == "cp" || cmdname == "scp" || cmdname == "rsync" || cmdname == "tar")
        analyze_read_cmd(args, 0)
    else if (cmdname == "grep" || cmdname == "egrep" || cmdname == "fgrep" || cmdname == "rg" || cmdname == "ag" || cmdname == "sed" || cmdname == "awk" || cmdname == "gawk")
        analyze_read_cmd(args, 1)
    else if (cmdname == "eval") {
        if (args != "")
            nested[++nested_n] = args
    } else if (cmdname == "bash" || cmdname == "sh" || cmdname == "zsh" || cmdname == "dash" || cmdname == "ksh")
        collect_shell_c(args)
    else if (cmdname == "find")
        collect_find_exec(args)
    cmdname = ""
}

function flush(   t, w) {
    t = tok
    tok = ""
    if (t == "")
        return
    if (expect_cmd) {
        if (skip_arg) {
            skip_arg = 0
            return
        }
        if (t ~ /^[A-Za-z_][A-Za-z0-9_]*=/)
            return
        if (wrapper != "") {
            if (t == "--") {
                wrapper = ""
                return
            }
            if (t ~ /^-/) {
                if (wrapper == "command" && (t == "-v" || t == "-V"))
                    probe = 1
                if (wrapper_opt_arg(wrapper, t))
                    skip_arg = 1
                return
            }
            if (probe) {
                # command -v <name> は実行しない
                probe = 0
                expect_cmd = 0
                return
            }
            if (wrapper == "timeout" && timeout_pending) {
                # timeout DURATION COMMAND の DURATION を読み飛ばす
                timeout_pending = 0
                return
            }
        }
        w = wrapper_name(t)
        if (w != "") {
            wrapper = w
            if (w == "timeout")
                timeout_pending = 1
            return
        }
        cmdname = normalize(t)
        expect_cmd = 0
        args = ""
        return
    }
    args = args (args == "" ? "" : " ") t
}

function end_segment() {
    flush()
    finish_command()
    expect_cmd = 1
    wrapper = ""
    skip_arg = 0
    timeout_pending = 0
    probe = 0
    cmdname = ""
    args = ""
}

function parse_all(s,   n, i, c) {
    quote = ""
    tok = ""
    expect_cmd = 1
    wrapper = ""
    skip_arg = 0
    timeout_pending = 0
    probe = 0
    cmdname = ""
    args = ""
    n = length(s)
    for (i = 1; i <= n; i++) {
        c = substr(s, i, 1)
        if (quote == "'") {
            if (c == "'")
                quote = ""
            else
                tok = tok c
            continue
        }
        if (quote == "\"") {
            if (c == "\"") {
                quote = ""
            } else if (c == "\\" && i < n) {
                i++
                tok = tok substr(s, i, 1)
            } else {
                tok = tok c
            }
            continue
        }
        if (c == "'") {
            quote = "'"
            continue
        }
        if (c == "\"") {
            quote = "\""
            continue
        }
        if (c == "\\" && i < n) {
            i++
            tok = tok substr(s, i, 1)
            continue
        }
        if (c == " " || c == "\t" || c == "\n") {
            flush()
            continue
        }
        if (c == ";") {
            end_segment()
            continue
        }
        if (c == "&") {
            if (i < n && substr(s, i + 1, 1) == "&")
                i++
            end_segment()
            continue
        }
        if (c == "|") {
            if (i < n && substr(s, i + 1, 1) == "|")
                i++
            end_segment()
            continue
        }
        tok = tok c
    }
    end_segment()
}

{ if (NR > 1) all = all "\n"; all = all $0 }

END {
    best = 0
    best_reason = ""
    nested_n = 0
    parse_all(all)
    print "D\t" best "\t" best_reason
    for (s in aliases)
        print "G\t" s
    for (i = 1; i <= nested_n; i++)
        print "C\t" nested[i]
}
