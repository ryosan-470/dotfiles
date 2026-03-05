# User Preferences

## Tools
- GitHub 関連の操作（PR、issue、リポジトリ情報の取得など）は `gh` CLI を使用すること。GitHub MCP サーバーは不要。

## 権限ポリシー（settings.json）

`settings.json` の `permissions` でコマンドの許可/不許可を管理している。方針は以下の通り：

### Claude Code ツール
- **Allow（自動許可）**: `Read`, `WebFetch`, `WebSearch`（すべて読み取り専用で副作用なし）

### gh CLI
- **Allow（自動許可）**: 閲覧・参照系コマンド（`view`, `list`, `status`, `diff`, `checks`, `search` など）
- **Deny（常に拒否）**: 破壊的・不可逆な操作（`delete`, `close`, `merge`, `archive`, `rename` など）、認証・鍵の操作（`auth`, `ssh-key`, `gpg-key`）、リポジトリ設定の変更（`secret`, `variable`）、`gh api`（任意のAPI呼び出しで他の制御をバイパスできるため）
- **未指定（都度確認）**: 作成・編集系の中間的な操作（`pr create`, `issue create`, `comment`, `edit`, `review`, `release create`, `run rerun` など）

### git
- **Allow（自動許可）**: 閲覧・参照系（`log`, `diff`, `show`, `status`, `branch`, `remote`, `tag`, `stash list`）
- **Deny（常に拒否）**: 破壊的・復元困難な操作（`push --force/-f`, `reset --hard`, `clean -fd`, `checkout -- .`）
- **未指定（都度確認）**: `commit`, `push`, `checkout`, `merge`, `rebase` など通常の操作

### brew
- **Deny（全操作拒否）**: `brew:*` で全コマンドをブロック

### システム
- **Deny（常に拒否）**: `sudo`, `shutdown`（特権昇格・システム停止の防止）
