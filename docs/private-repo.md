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
private リポジトリは init の途中で clone されるため、その前に `brew install gh`、`gh auth login`、`gh auth setup-git` を済ませておく (HTTPS の場合)。

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
| `claude/settings.json` | `~/.claude/settings.json` にマージ | 全マシン共通。permissions は和集合、hooks は base + private。`"$replace": ["env"]` で列挙したキーは深いマージせず置き換える |
| `claude/settings.<profile>.json` | `~/.claude/settings.json` に追加マージ | `machineProfile` と一致するファイルだけ読み込む。仕事用・個人用で分けたい marketplace / enabledPlugins を置く |
| `claude/ccgate.jsonnet` | `~/.claude/ccgate.jsonnet` へシンボリックリンク | ccgate (Claude Code の PermissionRequest hook) のグローバル設定。リンクなので private 側の編集がそのまま反映される。既存の実ファイルがあればスキップする (ccgate 節を参照) |
| `Brewfile` | macOS で `brew bundle` | 全マシン共通。公開 Brewfile の後に適用 |
| `Brewfile.<profile>` | macOS で `brew bundle` | `machineProfile` と一致するファイルだけ、private `Brewfile` の後に適用。仕事用・個人用で分けたいパッケージを置く |
| `aws/config` | `~/.aws/config` へシンボリックリンク (`machineProfile = work` かつ `aws/config.work` があるマシンでは結合) | 600。リンクのときは `aws configure` の変更も private 側に入る。結合のときは入らない (AWS 節を参照) |
| `aws/config.work` | `machineProfile = work` のマシンだけ、`aws/config` と結合して `~/.aws/config` の実ファイル (600) を作る | 仕事用の profile を置く。`[default]` は両方にあるため `aws/config.work` 側を残す |

> [!NOTE]
> `Brewfile` は全マシンで共通に適用される。profile ごとに分けたいパッケージは `Brewfile.<profile>` に書く。`machineProfile` が空、または一致するファイルが無い場合は、profile 別の Brewfile はスキップされる。ホスト単位 (同じ profile 内のマシン差) で分けたいものは、そのマシンで手動で入れる。

未対応 (必要になったら「新しいスロットを追加する」の手順で足す):

- `bash/*.bash` (`~/.bashrc` から source)
- `bin/` (`PATH` に追加)
- `ssh/config` (`~/.ssh/config` から Include)
- 任意のアプリ設定

## 読み込み順 (後勝ち)

- zsh: 公開 `~/.config/zsh/*.zsh` (`.zshrc` で固定順) → private `zsh/*.zsh` (ファイル名順) → `~/.local.zsh`
- git: 公開 `~/.gitconfig` → private `gitconfig` → `~/.gitconfig.local`
- tmux: 公開 `~/.tmux.conf` → private `tmux.conf` → `~/.tmux.local.conf`
- Claude Code: 現在の `~/.claude/settings.json` を土台に、公開 `settings.base.json` → private `claude/settings.json` → private `claude/settings.<profile>.json` の順で上書きする。`permissions` は 4 層の和集合。`"$replace"` に列挙したキーはその層の値で置き換える
- Brewfile: 公開 `Brewfile` → private `Brewfile` → private `Brewfile.<profile>` (いずれも `brew bundle --no-upgrade`。後のファイルは前のファイルの内容を打ち消さず、追加でインストールする)
- AWS: private のみ。`machineProfile = work` かつ `aws/config.work` があれば `aws/config` と結合した実ファイル、それ以外は `aws/config` のシンボリックリンク
- ccgate: private のみ。`claude/ccgate.jsonnet` を `~/.claude/ccgate.jsonnet` にシンボリックリンクする (公開側に同名のファイルは無い)

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

### Brewfile の profile 別設定

`Brewfile` は全マシン共通、`Brewfile.<profile>` はマシンの profile が一致するときだけ追加で `brew bundle` される。仕事用・個人用だけで使う CLI / cask はこちらに分ける。`machineProfile` の設定方法は前節と同じ。

```
Brewfile             # 全マシン共通 (公開 Brewfile の後に適用)
Brewfile.work        # machineProfile = work のマシンだけ
Brewfile.personal    # machineProfile = personal のマシンだけ
```

- 適用順は 公開 `Brewfile` → private `Brewfile` → private `Brewfile.<profile>`
- `machineProfile` が空、または一致するファイルが無い場合はスキップされる (エラーにならない)。`machineProfile` が未設定の古い `chezmoi.toml` でも同様
- 3 つのファイルは、それぞれの内容の hash がスクリプトに埋め込まれる。どれか 1 つでも変わると次の `chezmoi apply` で `brew bundle` が再実行される
- `--no-upgrade` で実行し、`cleanup` はしない。ファイルから消したパッケージはアンインストールされない
- 他のスロットと同様、会社名や社内ツール名を含むパッケージは private に置き、公開 `Brewfile` には書かない

## AWS

- `aws/config` を private に置くと、`~/.aws/config` にリンクされる (個人用・profile 未設定のマシン、および `aws/config.work` が無い仕事用マシン)
- `machineProfile = work` のマシンで `aws/config.work` があると、`aws/config.work` と `aws/config` を結合して `~/.aws/config` の実ファイル (600) を作る (`merge_aws_config`、`run_after_private-links.sh.tmpl`)
  - 結合の方式は chezmoi テンプレート (`create_` / `modify_`) ではなく run_after スクリプトにした。リンクと同じ「既存の実ファイルは上書きしない」規則を揃えるため、また private 側のファイルはスクリプト実行時にしか clone されず、テンプレートの `include` だと初回 apply で参照できないことがあるため
  - `[default]` は両方にあるので 1 つにまとめ、`aws/config.work` 側を残す (仕事用マシンの既定 profile にする)。`aws/config` 側の `[default]` は捨てる
  - `[default]` 以外のセクション名 (`[profile <name>]`、`[sso-session <name>]`) が両方にあると、何も書かずに警告する。AWS CLI は重複セクションがあると失敗するため
- 結合ファイルは生成時点のスナップショットになる。private 側を後から編集しても既存の `~/.aws/config` は更新されない (実ファイルは上書きしない)。private 側の定義と結果が異なるときは、apply のたびに警告が出る。反映するには `~/.aws/config` を退避してから `chezmoi apply` する
- 結合ファイルに `aws configure` などで書き込んだ内容は private 側に戻らない。仕事用の変更は `aws/config.work` を直接編集して commit / push し、上の手順で結合ファイルを作り直す
- 個人用 → 仕事用に profile を切り替えたときは、以前の `aws/config` へのリンク (private の `aws/config` を指すもの) だけを結合ファイルに置き換える。別の場所を指すリンクや実ファイルは触らず、警告する
- AWS CLI のプロファイルは `~/.aws/config` の `[profile <name>]` (default は `[default]`) で定義する。`~/.aws/profile` という標準ファイルは無い
- `~/.aws/credentials` はサポートしない (access key は秘密情報)。SSO か `credential_process` を使う
- 既存の `~/.aws/config` が実ファイルの場合は上書きしない。中身を `~/.config/private/aws/config` (個人用) または `~/.config/private/aws/config.work` (仕事用) に移し、元ファイルを退避してから `chezmoi apply` する
- リンクの状態で `aws configure` などで書き換えた内容は private 側のファイルに入る。`dot private` で移動して commit / push する
- ツールがリンクを実ファイルに置き換えた場合は、内容を確認してから実ファイルを退避し、`chezmoi apply` でリンクを張り直す

## ccgate

- `claude/ccgate.jsonnet` を private に置くと、`~/.claude/ccgate.jsonnet` にリンクされる (全マシン共通。profile 別の `ccgate.<profile>.jsonnet` は未対応)
- ccgate はシンボリックリンク越しに設定を読む。リンク先の jsonnet を評価することを ccgate 0.11.1 の実機で確認している。private 側を編集すると、次の hook 実行からそのまま反映される
- リンクは `run_after_private-links.sh.tmpl` の `link_slot` で張る。スクリプトは `chezmoi apply` のたびに実行され、配置先が無ければ作る。配置済みなら何もしないので、配置先を rm しても次の apply で張り直される
- 既存の `~/.claude/ccgate.jsonnet` が実ファイルの場合は上書きしない (警告してスキップする)。中身を `~/.config/private/claude/ccgate.jsonnet` に移し、元ファイルを退避してから `chezmoi apply` する
- 設定に秘密情報は書かない。provider の認証は環境変数か、`auth` で参照する外部ファイル・コマンドで指定する
- ccgate 本体は mise で管理する (公開側の手順は [chezmoi.md](./chezmoi.md) を参照)。ここで扱うのは設定ファイルだけ

## 新しいスロットを追加する

1. 公開リポジトリ側に読み込みフックを追加する
   - source / include 系: `.zshrc`, `.gitconfig`, `.tmux.conf`, `CLAUDE.md`, `modify_settings.json.tmpl` など
   - ファイルリンク系: `home/.chezmoiscripts/run_after_private-links.sh.tmpl` に `link_slot` を 1 行追加する
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

`tests/e2e.sh private_layer` が、ローカルの bare リポジトリを privateRepo として init し、zsh / git / tmux / Claude を検証する。AWS は `machineProfile` ごとに一時 HOME を分けて、work の結合 (600・`[default]` は 1 つ)、personal のリンク、personal → work の切り替え、既存の実ファイルの保護、重複セクションの拒否、`aws/config.work` が無い work のリンクを確認する。ccgate は seed の `claude/ccgate.jsonnet` から `~/.claude/ccgate.jsonnet` へのリンクになること、既存の実ファイルが上書きされず中身が保たれることを確認する。
ローカルで実行するときは、brew bundle が実際に走らないよう `brew` を PATH から外す (テストの Brewfile に架空の formula を入れているため、brew があると失敗する)。`CI` の環境変数を代わりに使うと、CI 用の sudo 処理も走るので避ける。
`Brewfile.<profile>` は、brew bundle 自体は CI ではスキップされるため、`run_onchange_after_brew-bundle.sh.tmpl` のレンダリング結果 (適用順・hash・一致しない profile の除外) だけを macOS で確認する。
CI では private リポジトリを使わない (`privateRepo` は空)。
