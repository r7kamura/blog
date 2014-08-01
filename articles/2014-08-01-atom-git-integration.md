---
title: Atom Git Integration
---

Atomを使っていて、ファイル一覧やステータスバーの色が変わっていることに気付いたことはあるだろうか。

こいつの正体はGitだ。
Atomは標準でGitレポジトリを管理する機能を備えていて、Gitの一般的な操作は勿論それに関連した様々な機能を備えている。
今回はAtomのGitに関連する幾つかの機能を見ていきながら、それらがどういう風に動くのかを説明していこうと思う。

## Git API
最初に言っておくと、この記事で触れるパッケージと機能は全てAtomのCore Git API上に実装されている。
`atom.project`というグローバルにアクセスできるオブジェクトが`getRepo()`というメソッドを持っており、
これが現在のプロジェクトのGitレポジトリを返すようになっている。
これを使えば、ファイルの状態や変更点など現在のレポジトリの状態を調べられる。
この機能には、git-utilsというlibgit2とのネイティブバインディングを行うライブラリが用いられている。

## Checkout HEAD revision
まずは私のお気に入りの`cmd-alt-z`から見ていこう。
このキーボードショートカットは、現在エディタで開いているファイルをHEADリビジョンにcheckoutする。
つまり、保存してstageに載せた変更を取り消して、HEADのcommit時点の状態に戻すということだ。
これはコマンドラインから`git checkout HEAD -- <path>`と`git reset HEAD -- <path>`を実行するのと本質的には変わらない。
ちなみにこのコマンドはundoスタックに積まれるので、`cmd-z`を使えばコマンド実行前の状態に戻せる。

![](https://f.cloud.github.com/assets/671378/2402434/f8d3b90a-aa21-11e3-8e8c-ba0385eef5f7.gif)

## Git status list
Atomには標準でfuzzy-finderパッケージが付いており、`cmd-t`でプロジェクト内のファイルを開いたり`cmd-b`で他の画面に移動したりできる。
このパッケージには`cmd-shift-b`というのも付いていて、変更のあったファイル一覧をポップアップすることができる。
これらのファイルはコマンドラインで`git status`を実行したときに表示されるものと同じものだ。
アイコンを見れば、ファイルがuntracked状態なのかそれとも変更されたのか分かるようになっている。

![](https://f.cloud.github.com/assets/671378/2404483/46581224-aa3c-11e3-836c-d79a5a8e9551.gif)

## Commit editor
AtomはGit commit用のエディタとして使えるし、
language-gitというcommit、merge、rebase時のシンタックスハイライトを行うパッケージも備えている。
次のようなコマンドで、Git commit時のエディタとしてAtomを使うように設定できる。

```
git config --global core.editor "atom --wait"
```

50文字か65文字を超えたあたりでlanguage-gitパッケージが色付けしてくれるので、
より簡潔なcommitメッセージが書けるようになっている。
この辺の見た目は`~/.atom/styles.less`を編集すれば変更できる。

```css
.editor .git-commit.line-too-long.deprecated {
  color: orange;
  text-decoration: none;
}

.editor .git-commit.line-too-long.illegal {
  color: #fff;
  background: #DA2C43;
  opacity: 0.9;
}
```

## Status bar icons
Atomにはstatus-barパッケージが最初から入っていて、ステータスバーの右側にGit関係の情報を表示してくれる。
例えば現在のブランチであったり、派生元ブランチから何commit離れているかというようなことも表示される。
加えて、現在のファイルがuntrackedなのか、変更されているのか、または無視されているのかといったことや、
最後のcommit以降何行変更されているのかということも表示してくれる。

![](https://f.cloud.github.com/assets/671378/2402807/fbebfeea-aa26-11e3-94c0-7caffd1774e8.gif)

## Line diffs
標準で入っているgit-diffパッケージによって、追加、編集、削除された行の横には色が付く。
加えて`alt-g down`と`alt-g up`で前後の変更行に移動できる。

![](https://f.cloud.github.com/assets/671378/2241519/04791a24-9cd6-11e3-9a12-164cabe81d58.png)

## Tree view
tree-viewパッケージの機能で、ファイル一覧の中で変更されているものは色付けられる。
変更されたファイルは太字で表示したいって？
こういうコードを`~/.atom/styles.less`に追加しよう。

```css
.tree-view .entry.directory.status-modified > .header,
.tree-view .entry.file.status-modified {
  font-weight: bold;
}
```

`.status-added`や`.status-ignored`クラスも利用できる。
次のスクリーンショットでは、新規ファイルは緑、変更されたファイルはオレンジ、無視されているファイルはグレーで表示されている。

![](https://f.cloud.github.com/assets/671378/2404228/ea43d5ac-aa38-11e3-8324-6544a433ad23.png)

## Further tweaks
`cmd-ctrl-shift-g`でstyleguideを開けば、更に利用可能なCSSクラスを調べられる。

Happy Hacking!
