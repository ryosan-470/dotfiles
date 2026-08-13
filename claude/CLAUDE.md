# User Preferences

## 日本語表記
- 括弧は全角 `()` ではなく半角 `()` を使うこと

## Tools
- GitHub 関連の操作(PR、issue、リポジトリ情報の取得など)は `gh` CLI を使用すること。
- 何かの完了や条件を待つ際は `sleep N && <command>` のような standalone sleep を使わないこと。Bash の分類器にブロックされる。代わりに `Monitor` (until-loop) か、バックグラウンド実行した処理を待つ場合は `run_in_background` を使うこと。
- Bash の作業ディレクトリはツール呼び出しをまたいで保持される。直前の呼び出しで既に `cd <dir>` 済みの場合、同じ相対パスへ再度 `cd <dir> && ...` すると存在しないパスとして失敗する。現在地が不確かなら `pwd` で確認するか、`cd` を挟まず絶対パス / `git -C <絶対パス>` での実行を優先すること。
- Go リポジトリの多くは Edit/Write 直後に `make fmt` 等の自動整形を走らせる PostToolUse hook を持つ (例: gosimports/gofumpt)。同じファイルに続けて2回目の Edit をする前には再度 Read すること — 1回目の Edit 後に裏で整形され、記憶している `old_string` が一致しなくなることがある。
- この環境に Grep/Glob ツールは存在しない。ファイル内容検索は `grep`/`rg`、ファイル検索は `find` を Bash 経由で使うこと。
- GOPATH/pkg/mod の Go 依存ソース参照・`.claude/plugins/cache` 配下・兄弟リポジトリの `git show`・`/tmp` scratch など、読み取り専用と分かっている既知の境界外調査は、素朴に Bash を実行して "Accessing paths outside the current repository/worktree" のブロックで失敗するより先に、その Bash 呼び出しに `dangerouslyDisableSandbox: true` を能動的に付けること。書き込み系コマンドやリポジトリ外への削除には適用しない。

## References

@RTK.md
@CLAUDE.local.md
