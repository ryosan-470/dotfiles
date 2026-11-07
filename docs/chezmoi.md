# chezmoi 運用ガイド

この dotfiles は [chezmoi](https://www.chezmoi.io/) で管理している。
このドキュメントは「設定を追加・変更したくなったとき、どこをどう触ればいいか」をまとめたもの。

## 全体像

- リポジトリ (ghq の clone: `~/code/src/github.com/ryosan-470/dotfiles`) が chezmoi の source directory
- `home/` 以下だけが `~` に配置される (`.chezmoiroot` で指定)。`docs/` や `.github/` は配置されない
- 配置はシンボリックリンクではなく **コピー**。リポジトリを編集しただけでは反映されず、`chezmoi apply` で反映する

## 基本の流れ

```sh
chezmoi cd                 # リポジトリに移動 (ghq の clone)
# home/ 以下を編集
chezmoi diff               # 反映前に何が変わるか確認
chezmoi apply              # ~ に反映
git commit && git push     # 他のマシンでは dot update (= chezmoi update) で取り込む
```

> [!WARNING]
> `~/.zshrc` などの配置先ファイルを直接編集しないこと。次の `chezmoi apply` でリポジトリの内容に戻る。
> うっかり直接編集した場合は `chezmoi re-add ~/.zshrc` でリポジトリ側に取り込める。

## ファイル名のルール

source 側のファイル名のプレフィックス/サフィックスで、配置先の名前や属性が決まる。

```
home/dot_config/zsh/alias.zsh  →  ~/.config/zsh/alias.zsh
     ^^^^ "dot_" が先頭の "." になる
```

| 付けるもの | 意味 | 例 |
|---|---|---|
| `dot_` | 先頭の `.` | `dot_zshrc` → `.zshrc` |
| `executable_` | 実行権限 (+x) を付ける | `executable_used-mem` |
| `private_` | 自分以外は読めない (ファイル 600 / ディレクトリ 700) | `private_Library` |
| `empty_` | 空ファイルでも配置する (付けないと空ファイルは配置されない) | `empty_dot_zlogout` |
| `symlink_` | シンボリックリンクとして配置 (中身がリンク先パス) | |
| `modify_` | 既存ファイルを入力に受け取り、出力で置き換えるスクリプト | `modify_settings.json.tmpl` |
| `.tmpl` (末尾) | Go テンプレートとして展開してから配置 | `dot_gitconfig.tmpl` |

> [!IMPORTANT]
> `~/Library` 配下のディレクトリには必ず `private_` を付けること。付けないと chezmoi が `~/Library` の権限を 700 → 755 に変更してしまう。

## やりたいこと別の早見表

| やりたいこと | 方法 |
|---|---|
| 既存の設定を変える (alias 追加など) | `home/` の該当ファイルを編集する (alias なら `home/dot_config/zsh/alias.zsh`) |
| 新しいツールの設定ファイルを管理したい | `chezmoi add ~/.config/foo/config` を実行すると `home/dot_config/foo/config` として取り込まれる |
| macOS / Linux で内容を変えたい | ファイル名に `.tmpl` を付けて `{{ if eq .chezmoi.os "darwin" }}...{{ end }}` で分岐する |
| 特定の OS ではファイルごと配置しない | `home/.chezmoiignore` に追記する (このファイル自体がテンプレート) |
| 内容が変わったときだけコマンドを実行したい | `home/.chezmoiscripts/run_onchange_after_<名前>.sh.tmpl` を作る (後述) |
| 外部の git リポジトリを置きたい | `home/.chezmoiexternal.toml.tmpl` に追記する (tpm と同じ書き方) |
| Claude Code の設定を変える | `home/dot_claude/settings.base.json` を編集する (後述) |
| macOS の LaunchAgent を追加したい | `home/private_Library/private_LaunchAgents/` に plist を置き、`run_onchange` スクリプトで再ロードする (既存の cleanup-caches を参照) |

### テンプレートでよく使う値

```
{{ .chezmoi.os }}        # "darwin" / "linux"
{{ .chezmoi.homeDir }}   # /Users/ryosan470 など (launchd の plist のように ~ が使えない場所で使う)
{{ .chezmoi.hostname }}  # マシン名
{{ .workRepo }}          # 仕事用リポジトリの URL (私用マシンでは空)
```

展開結果は `chezmoi execute-template < home/<ファイル>.tmpl` や `chezmoi cat ~/<配置先>` で確認できる。

### 内容が変わったときにコマンドを実行する (run_onchange)

`run_onchange_` スクリプトは「スクリプトの中身が前回実行時から変わったとき」だけ実行される。
別ファイルの変更をきっかけにしたい場合は、そのファイルのハッシュをコメントに埋め込む。

```bash
{{ if eq .chezmoi.os "darwin" -}}
#!/bin/bash
# Brewfile hash: {{ include (joinPath .chezmoi.workingTree "Brewfile") | sha256sum }}
brew bundle --file={{ joinPath .chezmoi.workingTree "Brewfile" | quote }}
{{ end -}}
```

- `after_` を付けるとファイル配置の後に、`before_` を付けると前に実行される
- 中身が空になるスクリプト (上の例の Linux) は実行されない

## どのレイヤーに書くか

設定は次の順で読み込まれ、後のものが優先される。

| レイヤー | 置き場所 | 書くもの |
|---|---|---|
| 共通 | このリポジトリの `home/` (公開) | どのマシンでも使う設定 |
| 仕事用 | 仕事用 private リポジトリ (`~/.config/work/` に clone される) | 勤務先でだけ使う設定。会社名・社内ツール・社内ホスト名など |
| マシン固有 | `~/.local.zsh`, `~/.local.bash`, `~/.gitconfig.local`, `~/.tmux.local.conf`, `~/.claude/CLAUDE.local.md` (管理外) | そのマシンだけの一時的な設定 |
| 秘密情報 | 1Password など | トークン・鍵など。**どのリポジトリにも書かない** |

迷ったら「会社名が推測できる内容なら仕事用、そうでなければ共通」。

### 仕事用リポジトリ

- 勤務先ごとに個人アカウントの private リポジトリを作る。リポジトリ名に会社名を入れないと公開プロフィールから推測されない (例: `dotfiles-work`)
- `chezmoi init` 時に URL を入力する。URL は `~/.config/chezmoi/chezmoi.toml` にだけ保存され、公開リポジトリには入らない
- private リポジトリなので、新しいマシンでは `chezmoi init` の前に `gh auth login` などで認証しておく
- 転職時は新しい勤務先用のリポジトリを作り、`~/.config/chezmoi/chezmoi.toml` の `workRepo` を書き換え、古い `~/.config/work` を削除してから `chezmoi apply` する (既存の clone があると chezmoi は pull するだけで URL の変更を反映しないため)。公開リポジトリは変更不要

想定しているファイル構成 (すべて任意。無いものは読み込まれないだけ):

```
zsh/*.zsh               # ~/.zshrc から source される
gitconfig               # ~/.gitconfig から include される
tmux.conf               # ~/.tmux.conf から source される
claude/CLAUDE.md        # ~/.claude/CLAUDE.md から import される
claude/settings.json    # ~/.claude/settings.json にマージされる
```

仕事用 `gitconfig` では `includeIf` を使うと、社用 PC 上でも私用リポジトリは私用の email/署名のままにできる。

```gitconfig
[includeIf "gitdir:~/code/src/github.com/<社のorg>/"]
    path = ~/.config/work/gitconfig-org
```

### コミット署名 (`dot_gitconfig.tmpl`)

`commit.gpgsign = true` は、署名鍵の秘密鍵がそのマシンの gpg にある場合だけ出力される。
鍵が無い新規マシンでもコミットが失敗しない。鍵を import した後は `chezmoi apply` を再実行すると署名が有効になる。
署名鍵の UID には私用・社用のアドレスを含めているため、鍵は私用/社用で分けずに 1 本を共用する。

## Claude Code の settings.json

`~/.claude/settings.json` は Claude Code (「常に許可」) や Orca (hooks の注入) が自分で書き換えるため、
単純なコピーではなく `home/dot_claude/modify_settings.json.tmpl` が `chezmoi apply` のたびに次の 3 つをマージして生成している。

1. 現在の `~/.claude/settings.json` (ローカルで追加されたもの)
2. `home/dot_claude/settings.base.json` (リポジトリ。同じキーは 1 を上書き)
3. `~/.config/work/claude/settings.json` (仕事用。同じキーは 2 を上書き)

マージのルール:

- `permissions` の `allow` / `ask` / `deny` / `additionalDirectories` は 3 つの和集合
- `hooks` はイベントごとに 3 つを合わせる。ただしリポジトリ側と同じ command を含むローカルのエントリはリポジトリ側で置き換える
- それ以外のキーはリポジトリ側の値が優先 (ローカルで `/config` から変えても apply で戻る)

注意点:

- 「常に許可」で増えた権限はローカルにだけ残る。全マシンで使いたいものは `settings.base.json` にも追記する
- **`settings.base.json` から削除した権限や hook は、既存マシンからは消えない**。消したい場合は各マシンの `~/.claude/settings.json` からも手で削除する
- マージには `jq` が必要 (macOS は標準で入っている)。無い場合は既存のファイルをそのまま残す

## 新しいマシンのセットアップ

```sh
# 仕事用リポジトリを使う場合は先に認証しておく
gh auth login

sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply \
  --source ~/code/src/github.com/ryosan-470/dotfiles ryosan-470
```

「仕事用 private リポジトリの URL」と聞かれたら、私用マシンでは空のまま Enter。

## 困ったとき

```sh
chezmoi diff            # リポジトリと ~ の差分
chezmoi status          # 反映されていないファイルの一覧
chezmoi managed         # 管理しているファイルの一覧
chezmoi doctor          # 環境の診断
chezmoi edit ~/.zshrc   # 配置先のパスから、対応する source ファイルを開く
chezmoi re-add ~/.zshrc # 直接編集してしまった配置先ファイルをリポジトリに取り込む
chezmoi cat ~/.zshrc    # apply したら何が書かれるか表示 (テンプレート展開後)
```

- `chezmoi apply` で「has changed since chezmoi last wrote it」と聞かれたら、配置先が直接編集されている。`d` で差分を見て、残したい変更なら中断して `chezmoi re-add` する
- インストーラーが `~/.zshrc` などに設定を追記するツール (dory など) は、apply で消しても再追記して差分 (`chezmoi status` で `MM`) になる。追記されるブロックと**同一内容**をリポジトリ側に入れておくと再追記されなくなる (`home/dot_zshrc.tmpl` 末尾の dory ブロックを参照。パスは `{{ .chezmoi.homeDir }}`、未インストールのマシン向けに `stat` で条件分岐)
- 公式ドキュメント: https://www.chezmoi.io/user-guide/command-overview/
