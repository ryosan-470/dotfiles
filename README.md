# jtwp470's config repository

## 必要なこと
zsh, tmuxがインストールされていることが必要である．

また，インストール時に`$HOME/.dotconfig/`ディレクトリが必要でここの中にクローンして使う
つまり以下の様なコマンドを入力してインストールしていく

### インストール 
    $ mkdir ~/.dotconfig
    $ cd ~/.dotconfig
    $ git clone https://github.com/jtwp470/dotfiles.git
    $ cd dotfiles
    $ ./init.sh
    
    
### その他注意事項
プラグイン系(zawなど)は`$HOME/.dotconfig/`ディレクトリ以下に保存しておく(そうすればホームディレクトリが散逸しない)
## していること
単にリポジトリ内のファイルをホームディレクトリにリンクを張っているだけである．
## ルール
* 各設定を変更する際にはAppendixブランチを利用してテストした後にmasterブランチにマージすること
