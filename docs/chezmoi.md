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
git commit && git push     # 他のマシンでは dot update (= private の pull + chezmoi update) で取り込む
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
| GUI アプリの設定を管理したい | Karabiner は `home/dot_config/private_karabiner/`、BTT はプリセットを `home/dot_btt_autoload_preset.json` に置く (後述)。Raycast はテキスト設定が無いので Brewfile のみ |
| CLI / GUI アプリを追加したい (macOS) | リポジトリ直下の `Brewfile` に `brew "foo"` / `cask "foo"` を追記する。次の `chezmoi apply` で `brew bundle` が走る。private は `~/.config/private/Brewfile` に書く (ccgate は mise で管理するので書かない。go / uv は Brewfile で管理する) |
| private リポジトリに設定を追加したい | [private-repo.md](./private-repo.md) のスロットに従ってファイルを置く。新しい種類はスロット追加の手順で公開側にフックを足す |
| macOS の LaunchAgent を追加したい | `home/private_Library/private_LaunchAgents/` に plist を置き、`run_onchange` スクリプトで再ロードする (既存の cleanup-caches を参照) |
| `docker compose` が `unknown command` になる | `~/.docker/cli-plugins/` にアンインストール済み Docker Desktop 由来のリンク切れ symlink が残っていないか確認する。`home/.chezmoiscripts/run_onchange_after_docker-cli-plugins.sh` がそれらを掃除し、Homebrew の `docker-compose` / `docker-buildx` が使えるようになる |

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

## GUI アプリの設定

macOS の GUI アプリは、設定の持ち方に合わせて管理方法を変えている。

### Karabiner-Elements

`~/.config/karabiner/karabiner.json` を `home/dot_config/private_karabiner/private_karabiner.json` として管理する (`private_` は Karabiner がファイルを 600 で作るため)。
Karabiner の UI で変更した内容は `chezmoi re-add ~/.config/karabiner/karabiner.json` で取り込む。

### BetterTouchTool

設定の実体は SQLite (`~/Library/Application Support/BetterTouchTool/btt_data_store.*`) で、そのままでは git に向かない。
そのため、BTT のプリセットを JSON (`.bttpreset`) に書き出し、`home/dot_btt_autoload_preset.json` (`~/.btt_autoload_preset.json`) として配置している。BTT は起動時にこのファイルを自動で import する。

現在の設定を書き出すには、BTT が起動している状態で:

```sh
osascript -e 'tell application "BetterTouchTool" to export_preset "imported" outputPath "/tmp"'
jq . /tmp/imported.bttpreset > home/dot_btt_autoload_preset.json
```

- `outputPath` にはファイルではなく **ディレクトリ** を渡す (BTT が `<プリセット名>.bttpreset` を作る)
- `with includeSettings` を付けると一般設定も入るが、ライセンス情報などが混ざる可能性があるので付けない
- プリセット以外 (ウィンドウスナップなど `NSUserDefaults` 側の設定) は管理対象外

### Raycast

dotfiles で管理できるテキスト設定ファイルが無いため、`Brewfile` の `cask "raycast"` でインストールだけを行う。
`~/.config/raycast/config.json` はアクセストークン (`rca_...`) なので**コミットしない**。新マシンでは Raycast を起動して認証する。
設定の Export (`.rayconfig`) はクリップボード履歴やノートを含むデータバックアップなので、dotfiles には置かない。

### LINE

LINE (Mac App Store id `539883307`) は `mas` で管理しない。mas 7 はインストール済み App Store アプリの列挙に Spotlight の索引を使うため。App Store から手動でインストールする。

## Claude Code の settings.json

`~/.claude/settings.json` は Claude Code (「常に許可」) や Orca (hooks の注入) が自分で書き換えるため、
単純なコピーではなく `home/dot_claude/modify_settings.json.tmpl` が `chezmoi apply` のたびに次の 4 つをマージして生成している。

1. 現在の `~/.claude/settings.json` (ローカルで追加されたもの)
2. `home/dot_claude/settings.base.json` (リポジトリ。同じキーは 1 を上書き)
3. `~/.config/private/claude/settings.json` (private 共通。同じキーは 2 を上書き)
4. `~/.config/private/claude/settings.<machineProfile>.json` (profile 別。同じキーは 3 を上書き)

`machineProfile` は `chezmoi init` 時にマシンごとに入力し、`~/.config/chezmoi/chezmoi.toml` にだけ保存する (`personal` / `work` など)。空なら 4 は読み込まない。

マージのルール:

- `permissions` の `allow` / `ask` / `deny` / `additionalDirectories` は 4 層の和集合
- `hooks` はイベントごとに 4 層を合わせる。ただしリポジトリ側と同じ command を含むローカルのエントリはリポジトリ側で置き換える
- それ以外のキーはリポジトリ側の値が優先 (ローカルで `/config` から変えても apply で戻る)
- 各層のトップレベルに `"$replace": ["env"]` のようにキー名を列挙すると、そのキーは前の層 (ローカルを含む) と深いマージせず、その層の値で丸ごと置き換える。その層に値が無ければキーごと消える。`"$replace"` 自体は出力されない。`permissions` / `hooks` は上記ルールが優先されるので対象外

  ```json
  // ~/.config/private/claude/settings.json: base の env もローカルに残った古い env も捨てて、これだけにする
  { "$replace": ["env"], "env": { "ANTHROPIC_BASE_URL": "http://localhost:20128" } }
  ```

  後ろの層 (profile 別) が `"$replace"` なしで同じキーを持つ場合は、置き換え後の値に深いマージされる

注意点:

- 「常に許可」で増えた権限はローカルにだけ残る。全マシンで使いたいものは `settings.base.json` にも追記する
- **`settings.base.json` から削除した権限や hook は、既存マシンからは消えない**。消したい場合は各マシンの `~/.claude/settings.json` からも手で削除する
- 既存マシンで `machineProfile` が未設定の場合は、`chezmoi init` を再実行するか `~/.config/chezmoi/chezmoi.toml` の `[data]` に追記する。未設定なら profile 別設定は読み込まれない
- マージには `jq` が必要 (macOS は標準で入っている)。無い場合は既存のファイルをそのまま残す
- `~/.claude/CLAUDE.md` が参照する `@RTK.md` は chezmoi 管理外。rtk (`rtk init -g`) が生成する `~/.claude/RTK.md` で、無くても `@` 参照が無視されるだけで害はない。hook (`rtk hook claude`) も rtk 本体が前提
- `@~/.config/private/claude/CLAUDE.md` も private リポジトリが無ければ単に無視される

### 破壊的コマンドのガード (PreToolUse hook)

`permissions` はコマンド文字列の前方一致でしか判定できないため、`rm -fr` / `rm -r -f` のような表記揺れや `cd x && rm -rf y` のような複合コマンド、git エイリアス経由の操作はルールをすり抜ける。

これを補うため、`home/dot_claude/hooks/dangerous-command-guard.sh` (解析本体は `dangerous-command-guard.awk`) を PreToolUse hook として登録している。`settings.base.json` の `PreToolUse` (matcher: `Bash`) から `bash ~/.claude/hooks/dangerous-command-guard.sh` で呼ばれ、以下を返す。

- `deny`: `rm` / `git rm` の再帰的強制削除 (`rm -rf`, `rm -fr`, `rm -r -f`, `sudo rm -rf` など)
- `ask`: 上記以外の `rm` / `mv`、`git commit`、force push (`--force` / `-f` / `--force-with-lease` / `--force-if-includes`)、`git reset --hard`, `git clean -f`, `git restore`, `git checkout -- / . / -f`
- allow に何も返さない: 通常の `git push` は `settings.base.json` の allow に従う

判定は `settings.base.json` の方針に合わせる。`bash -c '...'`、`eval`、`find -exec` の中身は再帰的に解析するが、完全なシェルパーサではないため、変数展開や難読化されたコマンド、スクリプトファイルの中身までは追跡しない。破壊的な git エイリアス (`nevermind`, `discard`) は bypass を防ぐため `home/dot_gitconfig.tmpl` から廃止した。

### プラグイン / マーケットプレイス

外部コードを自動で取り込むため、`settings.base.json` に置くものは最小限にする。

- 公開リポジトリに置くのは、全マシンで使うと決めたものだけ。仕事用・プロジェクト固有のマーケットプレイスやプラグインは private レイヤーに置く。個人/仕事を切り替えたいものは `claude/settings.<profile>.json` に置く
- `extraKnownMarketplaces` の GitHub ソースは `ref` でタグに固定し、`autoUpdate` を `false` にする (タグが無いリポジトリは少なくとも `autoUpdate` を `false` にする)。更新は `claude plugin marketplace update <name>` で明示的に行う。`autoUpdate` の既定値は有効なので、書かないと自動更新になる
- マーケットプレイスを追加すると、そのリポジトリの `.claude-plugin/marketplace.json` やプラグインの hooks / MCP サーバーが実行されうる。追加前にリポジトリの内容を確認する
- `enabledPlugins` と `extraKnownMarketplaces` は 4 層が深いマージになる。同じキーは base → private 共通 → profile 別の順で上書きされ、ローカルで追加したプラグインは残る。ただし **base から削除したエントリは既存マシンのローカル設定には残る** ので、各マシンの `~/.claude/settings.json` からも手で削除する

## 新しいマシンのセットアップ

空の Mac に何も無い状態から、`chezmoi apply` で設定が入り、日常で使えるようになるまでの手順。
Homebrew の cask と LaunchAgent は macOS のみ。Linux では該当する箇所を読み飛ばす。

### 1. chezmoi 実行前の準備

#### Xcode Command Line Tools

```sh
xcode-select --install
```

git は Xcode Command Line Tools に含まれる。Homebrew のインストールにも必要。

#### Homebrew

[公式サイト](https://brew.sh/) の手順でインストールする。
Homebrew 自体のインストールは sudo と対話が必要なため、chezmoi では行わない。

インストール直後のシェルでは PATH を通しておく。

```sh
if [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"   # Apple Silicon
elif [ -x /usr/local/bin/brew ]; then
    eval "$(/usr/local/bin/brew shellenv)"      # Intel Mac
fi
```

`chezmoi apply` で `~/.zshenv` が配置されると、`/opt/homebrew` / `/usr/local` / Linuxbrew を順に探して `brew shellenv` するようになるため、この設定を自分で書く必要はない。

#### ツールのインストール

`Brewfile` のツールと GUI アプリは、`chezmoi apply` の最後に `brew bundle` で入る。
apply の前に個別にインストールするのは、次の 2 つだけ。

- `gh`: private レイヤーを使う場合 (後述)
- `jq`: `~/.claude/settings.json` のマージに使う。macOS 標準の jq で足りる。無い環境では `brew install jq`

#### private レイヤーを使う場合の認証

private リポジトリは `chezmoi init` の途中で clone される。
この時点ではまだ `gh` も Git Credential Manager も入っていないため、先に認証を用意する。

```sh
brew install gh
gh auth login
gh auth setup-git   # HTTPS で clone する場合
```

`gh auth setup-git` が `~/.gitconfig` に書く credential helper は、`chezmoi apply` が `~/.gitconfig` を再生成すると消える。apply 後は Brewfile の Git Credential Manager が credential helper になり、初回の git 操作で認証を求められる。

SSH で clone する場合は SSH 鍵を用意し、private リポジトリの URL に SSH 形式 (`git@github.com:...`) を指定する。

### 2. chezmoi を実行する

```sh
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply \
  --source ~/code/src/github.com/ryosan-470/dotfiles ryosan-470
```

- `get.chezmoi.io` のインストーラは、chezmoi のバイナリを**カレントディレクトリの `./bin`** にダウンロードし、`--` 以降の引数でそのバイナリを実行する。恒久的なインストールではない
- `--source` は ghq の clone 先。`chezmoi init` はここにリポジトリを clone し、`~/.config/chezmoi/chezmoi.toml` の `sourceDir` もこのパスになる
- `ryosan-470` は GitHub のユーザー名で、`https://github.com/ryosan-470/dotfiles.git` が clone される
- 対話で 2 つ聞かれる
  - private リポジトリの URL: 全マシンで同じ値を入力する。使わないなら空のまま Enter
  - machineProfile: `personal` / `work` など。空なら profile 別設定を読み込まない
- `--apply` まで付けると、clone した設定をそのまま `~` に反映する。初回は `brew bundle` も走るため時間がかかり、cask によっては sudo のパスワードを聞かれる
- apply 後は Brewfile の `brew "chezmoi"` で Homebrew の chezmoi が入る。`./bin` は PATH に入らない。`~` で実行して `~/bin` に置いた場合も、`brew shellenv` が Homebrew を PATH の先頭に置くため、以後は Homebrew の chezmoi が使われる。`./bin/chezmoi` は削除してよい

### 3. apply で自動的に行われること

- `home/.chezmoiexternal.toml.tmpl`: tpm (`~/.tmux/plugins/tpm`) と zimfw 本体 (`~/.zim/zimfw.zsh`) を配置する。`privateRepo` を設定していれば `~/.config/private` に private リポジトリを clone する
- `run_onchange_after_brew-bundle.sh.tmpl`: `Brewfile` と `~/.config/private/Brewfile` を `brew bundle` する (macOS で brew がある場合)
- `run_onchange_after_private-links.sh.tmpl`: private の `aws/config` を `~/.aws/config` にシンボリックリンクする (存在する場合)
- `run_onchange_after_load-launchagents.sh.tmpl`: `cleanup-caches` の LaunchAgent を登録する (macOS)
- `modify_settings.json.tmpl`: `~/.claude/settings.json` を 4 層でマージする

### 4. 実行後の手作業

#### zsh (zimfw)

初回のインタラクティブシェル起動時に `~/.config/zsh/zim.zsh` が `zimfw.zsh init -q` を実行し、`zimrc` のモジュールをネットワークから取得する。初回だけ時間がかかる。

#### tmux (tpm)

tmux を起動し、prefix (`C-q`) + `I` でプラグインをインストールする。
tpm 本体は apply で配置済みだが、`tmux-yank` / `tmux-copycat` は初回にインストールが必要。

#### GPG 署名鍵

`home/dot_gitconfig.tmpl` は、署名鍵の秘密鍵が存在するマシンでだけ `commit.gpgsign = true` にする。
鍵が無くてもコミットは失敗せず、署名なしになる。

署名を有効にするには、鍵を安全な場所 (1Password の添付やバックアップ) から import して `chezmoi apply` を再実行する。鍵はリポジトリに置かない。

```sh
gpg --import /path/to/secret-key.asc
chezmoi apply
git config --get commit.gpgsign   # true なら有効
```

#### chezmoi 管理外のファイル

- `~/.claude/RTK.md`: rtk が `rtk init -g` で生成する。無い場合、`~/.claude/CLAUDE.md` の `@RTK.md` は単に無視される。`rtk hook claude` も rtk が前提 (Brewfile の `brew "rtk"` で入る)
- `~/.local.zsh`, `~/.gitconfig.local`, `~/.tmux.local.conf`, `~/.claude/CLAUDE.local.md`: マシン固有の設定。必要なら作成する
- `~/.config/mise/config.toml`: mise で入れるツール。`ccgate` は Brewfile ではなくここで管理する
  ```sh
  mise use -g aqua:tak848/ccgate
  ```
  mise の shim を有効にするには `~/.local.zsh` に `eval "$(mise activate zsh)"` を書く

#### アプリの初回起動 (macOS)

cask でアプリはインストールされるが、初回起動・ログイン・権限の許可は手作業。

- Claude Code: 初回起動でログインする
- Orca: 初回起動でセットアップする
- 1Password / 1Password CLI: サインインする。CLI は `op signin`。補完は `~/.config/zsh/completion.zsh` が設定する
- Raycast: 起動してサインインする。`~/.config/raycast/config.json` はアクセストークンなので管理しない
- Karabiner-Elements: 入力監視とドライバの許可を与える。設定 (`~/.config/karabiner/karabiner.json`) は apply 済み
- BetterTouchTool: ライセンス認証とアクセシビリティの許可を与える。プリセット (`~/.btt_autoload_preset.json`) は起動時に自動で import される

#### 最後に確認する

初回の apply では `brew bundle` と private リポジトリの clone が後半に走るため、`~/.gitconfig` (Git Credential Manager の検出) や private の Claude 設定がまだ反映されていない。もう一度 apply してから確認する。

```sh
chezmoi apply           # 2 回目 (brew bundle と private clone の結果を反映)
exec zsh                # 設定を読み直す
chezmoi doctor          # 環境の診断
chezmoi status          # 未反映のファイルが無いこと
```

2 台目以降は `dot update` (= `chezmoi update`) で追従する。

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
