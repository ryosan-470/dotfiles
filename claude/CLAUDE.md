# User Preferences

## 日本語表記
- 括弧は全角 `()` ではなく半角 `()` を使うこと

## Tools
- GitHub 関連の操作(PR、issue、リポジトリ情報の取得など)は `gh` CLI を使用すること。GitHub MCP サーバーは不要。

## コミット

Co-Authored-By は不要

## URL フェッチのルール
- URL の内容を取得する際は WebFetch ではなく `/webfetch-markdown:fetch` スキルを優先的に使用すること
- スキルが失敗した、または存在しない場合は WebFetch にフォールバックする
