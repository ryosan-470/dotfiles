# private リポジトリ仕様

この dotfiles の private レイヤーの契約をまとめたもの。
個人用と仕事用の「公開したくない設定」を 1 つの private リポジトリにまとめ、公開リポジトリ (このリポジトリ) から読み込む。

## 原則

- 公開リポジトリは「どこをどう読み込むか」だけを定義する。private リポジトリは素材を置く場所。
- private リポジトリの URL は公開リポジトリに書かない。`chezmoi init` で入力し、`~/.config/chezmoi/chezmoi.toml` の `privateRepo` にだけ保存する。全マシンで同じ URL を入力する。
- 平文の秘密情報は置かない。トークン・秘密鍵・AWS の access key・`.env` などは 1Password などに置く。private リポジトリでも git の履歴には残る。
- 仕事用と個人用は 1 つのリポジトリに同居させる。常に全部が読み込まれるので、切り替えたいものはファイル内で条件分岐する (後述)。

## セットアップ

### private リポジトリを作る

```sh
# 空の Mac など gh が無い環境では先に brew install gh
gh auth login
gh repo create <your-account>/<private-repo> --private --add-readme
```

`<private-repo>` の例は `dotfiles-private`。名前は任意だが、公開リポジトリ (`dotfiles`) とは別の名前にする。

### 各マシンで init する

空の Mac からの手順全体 (Xcode Command Line Tools / Homebrew / `gh` の準備) は
[chezmoi.md の「新しいマシンのセットアップ」](./chezmoi.md#新しいマシンのセットアップ) を参照。
private リポジトリは init の途中で clone されるため、その前に `brew install gh` と `gh auth login` を済ませておく。

```sh
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply \
  --source ~/code/src/github.com/ryosan-470/dotfiles ryosan-470
```

「private リポジトリの URL」を聞かれたら、全マシンで同じ URL を入力する。使わない場合は空のまま Enter。
入力値は `~/.config/chezmoi/chezmoi.toml` にだけ保存され、`~/.config/private` に clone される。

### 既存マシンの移行 (workRepo → privateRepo)

1. `~/.config/chezmoi/chezmoi.toml` の `[data]` を編集し、`workRepo` を `privateRepo` にリネームする (値はそのまま)
2. `~/.config/work` の中身を private リポジトリに移して commit / push する
3. `chezmoi apply` を実行する
4. `~/.config/work` を削除する (中身を確認してから `rm -r ~/.config/work`)
5. URL を変える場合は、既存の clone があると chezmoi は pull するだけで URL の変更を反映しない。`~/.config/private` を一度削除してから `chezmoi apply` する

## レイアウト (スロット)

private リポジトリの直下に置く。すべて任意で、無いものは単に無視される。

| private 側 | 配置先 / 読み込み | 備考 |
|---|---|---|
| `zsh/*.zsh` | `~/.zshrc` がファイル名順に source | 順序は `00-`, `10-` などの接頭辞で制御する |
| `gitconfig` | `~/.gitconfig` から include | 公開 → private → `~/.gitconfig.local` の順 |
| `tmux.conf` | `~/.tmux.conf` から source-file | 公開 → private → `~/.tmux.local.conf` の順 |
| `claude/CLAUDE.md` | `~/.claude/CLAUDE.md` から `@` import | |
| `claude/settings.json` | `~/.claude/settings.json` にマージ | 全マシン共通。permissions は和集合、hooks は base + private |
| `claude/settings.<profile>.json` | `~/.claude/settings.json` に追加マージ | `machineProfile` と一致するファイルだけ読み込む。仕事用・個人用で分けたい marketplace / enabledPlugins を置く |
| `Brewfile` | macOS で `brew bundle` | 公開 Brewfile の後に適用 |
| `aws/config` | `~/.aws/config` へシンボリックリンク | 600。`aws configure` の変更も private 側に入る |

> [!NOTE]
> `Brewfile` は全マシンで共通に適用される。ホストごとに分けたいパッケージは `Brewfile` に書かず、そのマシンで手動で入れる。

未対応 (必要になったら「新しいスロットを追加する」の手順で足す):

- `bash/*.bash` (`~/.bashrc` から source)
- `bin/` (`PATH` に追加)
- `ssh/config` (`~/.ssh/config` から Include)
- 任意のアプリ設定

## 読み込み順 (後勝ち)

- zsh: 公開 `~/.config/zsh/*.zsh` (`.zshrc` で固定順) → private `zsh/*.zsh` (ファイル名順) → `~/.local.zsh`
- git: 公開 `~/.gitconfig` → private `gitconfig` → `~/.gitconfig.local`
- tmux: 公開 `~/.tmux.conf` → private `tmux.conf` → `~/.tmux.local.conf`
- Claude Code: 現在の `~/.claude/settings.json` を土台に、公開 `settings.base.json` → private `claude/settings.json` の順で上書きする。`permissions` は 3 つの和集合
- Brewfile: 公開 `Brewfile` → private `Brewfile`
- AWS: private のみ (シンボリックリンク)

## 仕事用と個人用の同居

1 つのリポジトリを全マシンで使うため、private の設定は常に全部読み込まれる。
切り替えたいものはファイル内で条件分岐する。ただし Claude Code の `settings.json` はプレーン JSON で分岐できないため、profile 別ファイルを使う (後述)。

git の identity は `includeIf` で切り替える。

```gitconfig
[includeIf "gitdir:~/code/src/github.com/<社のorg>/"]
    path = ~/.config/private/gitconfig-org
```

ホスト固有の設定は `$HOSTNAME` や `uname` で分岐する。

```zsh
if [[ $HOSTNAME == company-* ]]; then
    ...
fi
```

- マシンだけの一時設定は `~/.local.zsh`, `~/.gitconfig.local`, `~/.tmux.local.conf`, `~/.claude/CLAUDE.local.md` (管理外) に置く
- 会社名・社内ホスト名・社内ツール名を含む設定は private に置く。公開リポジトリには書かない
- 仕事用・プロジェクト固有の Claude Code プラグインとマーケットプレイスは private の `claude/settings.json` に置く。個人/仕事で切り替えたいものは `claude/settings.<profile>.json` に分ける。外部コードは `ref` で固定し、`autoUpdate` は `false` にする (タグが無いリポジトリは少なくとも `autoUpdate` を `false` にする)

### Claude Code の profile 別設定

`claude/settings.json` は全マシン共通、`claude/settings.<profile>.json` はマシンの profile が一致するときだけ追加でマージされる。個人専用・仕事専用のプラグインはこちらに分ける。

```
claude/settings.json          # 全マシン共通
claude/settings.work.json     # machineProfile = work のマシンだけ
claude/settings.personal.json # machineProfile = personal のマシンだけ
```

profile は `chezmoi init` 時にマシンごとに入力し、`~/.config/chezmoi/chezmoi.toml` の `[data] machineProfile` にだけ保存する。公開リポジトリにも private リポジトリにも書かない。

既存マシンでは `chezmoi init` を再実行するか、`~/.config/chezmoi/chezmoi.toml` に追記する。

```toml
[data]
    privateRepo = "https://github.com/<your-account>/<private-repo>"
    machineProfile = "work"
```

profile 別ファイルが無い、または `machineProfile` が空の場合は、共通の `settings.json` だけが読み込まれる。

## AWS

- `aws/config` を private に置くと `~/.aws/config` にリンクされる
- AWS CLI のプロファイルは `~/.aws/config` の `[profile <name>]` (default は `[default]`) で定義する。`~/.aws/profile` という標準ファイルは無い
- `~/.aws/credentials` はサポートしない (access key は秘密情報)。SSO か `credential_process` を使う
- 既存の `~/.aws/config` が実ファイルの場合は上書きしない。中身を `~/.config/private/aws/config` に移し、元ファイルを退避してから `chezmoi apply` する
- `aws configure` などで書き換えた内容は private 側のファイルに入る。`dot private` で移動して commit / push する
- ツールがリンクを実ファイルに置き換えた場合は、内容を確認してから実ファイルを退避し、`chezmoi apply` でリンクを張り直す

## 新しいスロットを追加する

1. 公開リポジトリ側に読み込みフックを追加する
   - source / include 系: `.zshrc`, `.gitconfig`, `.tmux.conf`, `CLAUDE.md`, `modify_settings.json.tmpl` など
   - ファイルリンク系: `home/.chezmoiscripts/run_onchange_after_private-links.sh.tmpl` に `link_slot` を 1 行追加する
2. `docs/chezmoi.md` とこのファイルに追記する
3. `tests/e2e.sh` の `test_private_layer` に検証を追加する

`link_slot` の例:

```bash
link_slot "$PRIVATE_DIR/ssh/config" "$HOME/.ssh/config" 600
```

- 親ディレクトリは 700 で作られる。指定したパーミッションは private 側のファイルに付く
- リンク先に実ファイルがある場合はスキップして警告する
- private 側のファイルを消してもリンクは残る。不要なら手動で削除する

## 運用

- 編集は `dot private` で `~/.config/private` に移動し、直接編集して commit / push する
- `dot update` は `~/.config/private` があれば先に `git pull --ff-only` し、その後 `chezmoi update` (公開リポジトリの pull + apply) を実行する。apply は 1 回だけなので、public / private 両方の変更がまとめて `~/.claude/settings.json` などに反映される
- `dot update` を使わずに反映したい場合は `git -C ~/.config/private pull` してから `chezmoi apply`。`chezmoi update` 単体では private は `refreshPeriod = 24h` のペースでしか更新されない (`chezmoi apply --refresh-externals` でも更新できるが、tpm や zimfw の external も取り直す)
- private リポジトリも chezmoi の external なので、`~/.config/private` を削除すると次の apply で clone し直される
- private リポジトリの git 操作は通常どおり `git` を使う
- 初回の `chezmoi init --apply` では private の clone が後になることがある。AWS のリンクや Claude の settings が反映されない場合は、もう一度 `chezmoi apply` を実行する

## テスト

`tests/e2e.sh private_layer` が、ローカルの bare リポジトリを privateRepo として init し、zsh / git / tmux / Claude / AWS リンクを検証する。
CI では private リポジトリを使わない (`privateRepo` は空)。
