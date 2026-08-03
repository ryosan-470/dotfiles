# User Preferences

## 日本語表記
- 括弧は全角 `()` ではなく半角 `()` を使うこと

## Tools
- GitHub 関連の操作(PR、issue、リポジトリ情報の取得など)は `gh` CLI を使用すること。GitHub MCP サーバーは不要。
- 何かの完了や条件を待つ際は `sleep N && <command>` のような standalone sleep を使わないこと。Bash の分類器にブロックされる。代わりに `Monitor` (until-loop) か、バックグラウンド実行した処理を待つ場合は `run_in_background` を使うこと。

## References

@RTK.md
@CLAUDE.local.md
