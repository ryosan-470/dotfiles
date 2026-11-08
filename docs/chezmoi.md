# chezmoi 運用ガイド

この dotfiles は [chezmoi](https://www.chezmoi.io/) で管理している。
このドキュメントは「設定を追加・変更したくなったとき、どこをどう触ればいいか」をまとめたもの。
private レイヤーの仕様は [private-repo.md](./private-repo.md) を参照。

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
| 外部のツール / リポジトリを置きたい | `home/.chezmoiexternal.toml.tmpl` に追記する。サプライチェーン対策として、ブランチ先頭 (`git-repo`) ではなくタグ固定の `archive` / `file` + `checksum.sha256` で取り込む (tpm / zimfw と同じ書き方。checksum は 0 埋めで apply して出る SHA256 mismatch の値を使う) |
| Claude Code の設定を変える | `home/dot_claude/settings.base.json` を編集する (後述) |
| CLI / GUI アプリを追加したい (macOS) | リポジトリ直下の `Brewfile` に `brew "foo"` / `cask "foo"` を追記する。次の `chezmoi apply` で `brew bundle` が走る。private は `~/.config/private/Brewfile` に書く (mise で管理する言語ランタイムや ccgate は書かない) |
| private リポジトリに設定を追加したい | [private-repo.md](./private-repo.md) のスロットに従ってファイルを置く。新しい種類はスロット追加の手順で公開側にフックを足す |
| macOS の LaunchAgent を追加したい | `home/private_Library/private_LaunchAgents/` に plist を置き、`run_onchange` スクリプトで再ロードする (既存の cleanup-caches を参照) |

### テンプレートでよく使う値

```
{{ .chezmoi.os }}        # "darwin" / "linux"
{{ .chezmoi.homeDir }}   # /Users/ryosan470 など (launchd の plist のように ~ が使えない場所で使う)
{{ .chezmoi.hostname }}  # マシン名
{{ .privateRepo }}       # private リポジトリの URL (未使用なら空)
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
| private | private リポジトリ (`~/.config/private/` に clone される) | 個人用・仕事用の非公開設定。会社名・社内ツール・社内ホスト名・AWS の profile など |
| マシン固有 | `~/.local.zsh`, `~/.local.bash`, `~/.gitconfig.local`, `~/.tmux.local.conf`, `~/.claude/CLAUDE.local.md` (管理外) | そのマシンだけの一時的な設定 |
| 秘密情報 | 1Password など | トークン・鍵など。**どのリポジトリにも書かない** |

迷ったら「公開したくない内容なら private、そうでなければ共通」。

### private リポジトリ

- 個人用と仕事用を 1 つの private リポジトリにまとめる。リポジトリ名は任意 (例: `dotfiles-private`)
- URL は `chezmoi init` で入力し、`~/.config/chezmoi/chezmoi.toml` にだけ保存する。公開リポジトリには書かない。全マシンで同じ URL を入力する
- private リポジトリなので、新しいマシンでは `chezmoi init` の前に `gh auth login` などで認証しておく
- 想定しているファイル構成・読み込み順・スロットの追加方法は [private-repo.md](./private-repo.md) を参照
- 平文の秘密情報は置かない。トークン・秘密鍵・AWS の access key などは 1Password などに置く
- private の `gitconfig` では `includeIf` を使うと、会社のマシンでも私用リポジトリは私用の email / 署名のままにできる

```gitconfig
[includeIf "gitdir:~/code/src/github.com/<社のorg>/"]
    path = ~/.config/private/gitconfig-org
```

## Claude Code の settings.json

`~/.claude/settings.json` は Claude Code (「常に許可」) や Orca (hooks の注入) が自分で書き換えるため、
単純なコピーではなく `home/dot_claude/modify_settings.json.tmpl` が `chezmoi apply` のたびに次の 3 つをマージして生成している。

1. 現在の `~/.claude/settings.json` (ローカルで追加されたもの)
2. `home/dot_claude/settings.base.json` (リポジトリ。同じキーは 1 を上書き)
3. `~/.config/private/claude/settings.json` (private。同じキーは 2 を上書き)

マージのルール:

- `permissions` の `allow` / `ask` / `deny` / `additionalDirectories` は 3 つの和集合
- `hooks` はイベントごとに 3 つを合わせる。ただしリポジトリ側と同じ command を含むローカルのエントリはリポジトリ側で置き換える
- それ以外のキーはリポジトリ側の値が優先 (ローカルで `/config` から変えても apply で戻る)

注意点:

- 「常に許可」で増えた権限はローカルにだけ残る。全マシンで使いたいものは `settings.base.json` にも追記する
- **`settings.base.json` から削除した権限や hook は、既存マシンからは消えない**。消したい場合は各マシンの `~/.claude/settings.json` からも手で削除する
- マージには `jq` が必要 (macOS は標準で入っている)。無い場合は既存のファイルをそのまま残す
- `~/.claude/CLAUDE.md` が参照する `@RTK.md` は chezmoi 管理外。rtk (`rtk init -g`) が生成する `~/.claude/RTK.md` で、無くても `@` 参照が無視されるだけで害はない。hook (`rtk hook claude`) も rtk 本体が前提
- `@~/.config/private/claude/CLAUDE.md` も private リポジトリが無ければ単に無視される

### プラグイン / マーケットプレイス

外部コードを自動で取り込むため、`settings.base.json` に置くものは最小限にする。

- 公開リポジトリに置くのは、全マシンで使うと決めたものだけ。仕事用・プロジェクト固有のマーケットプレイスやプラグインは private レイヤー (`~/.config/private/claude/settings.json`) に置く
- `extraKnownMarketplaces` の GitHub ソースは `ref` でタグに固定し、`autoUpdate` を `false` にする (タグが無いリポジトリは少なくとも `autoUpdate` を `false` にする)。更新は `claude plugin marketplace update <name>` で明示的に行う。`autoUpdate` の既定値は有効なので、書かないと自動更新になる
- マーケットプレイスを追加すると、そのリポジトリの `.claude-plugin/marketplace.json` やプラグインの hooks / MCP サーバーが実行されうる。追加前にリポジトリの内容を確認する
- `enabledPlugins` と `extraKnownMarketplaces` は 3 層が深いマージになる。同じキーは base → private の順で上書きされ、ローカルで追加したプラグインは残る。ただし **base から削除したエントリは既存マシンのローカル設定には残る** ので、各マシンの `~/.claude/settings.json` からも手で削除する

## 新しいマシンのセットアップ

```sh
# private リポジトリを使う場合は先に認証しておく
gh auth login

sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply \
  --source ~/code/src/github.com/ryosan-470/dotfiles ryosan-470
```

「private リポジトリの URL」と聞かれたら、全マシンで同じ URL を入力する。使わない場合は空のまま Enter。

Homebrew 自体のインストールは sudo と対話が必要なため chezmoi では行わない。macOS では先に [公式手順](https://brew.sh/) で Homebrew を入れておくと、`chezmoi apply` が `Brewfile` (と `~/.config/private/Brewfile`) を `brew bundle` する。brew が無ければスキップされる。

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
