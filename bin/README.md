# dotfiles/bin
自前の便利なスクリプト集

## 使い方
ホームディレクトリに`bin`という名前のディレクトリを作成し,そこのPATHを通せばどこからでも使える

```bash
$ export PATH=${HOME}/bin:${PATH}
```

## 説明とか

### delkasu
主にOSXで要らないのに生み出されるゴミファイルを消す

### glmake
OpenGLを使うC言語のコードをコンパイルするスクリプト.

LinuxかOSXで使う.

### md2pdf
Github風のMarkdownファイルをpdfに変換してくれるすぐれもの.

[Pandoc](http://pandoc.org/)が必要.

```bash
$ md2pdf test.md # test.mdがtest.pdfになって生まれてくる代物
```

フォントもいじれば変更できるようですがそこまではしていません
