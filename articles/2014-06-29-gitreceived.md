---
title: Gitreceived
---

git pushに対応することに特化したSSHサーバ
[Gitreceived](https://github.com/flynn/gitreceived)
を読んだ。

## git-shell
Git付属のシェル git-shell がGitreceivedで利用されている。
git-shellはGitに関する作業しかできない制限付きのシェルである。
GitreceivedはSSH経由で入力された任意のコマンドを外部コマンドとして実行しようとするが、
このとき外部コマンドはgit-shellを利用して実行される。
つまり、任意のコマンドと言えどGitに関する作業しか実行できないように制限されている。

## git push
クライアントでgit push origin masterが実行されたとしよう。
このときGitは、サーバへのSSH接続を開始する send-pack プロセスを実行する。
サーバ側では、以下のようなSSHの呼出を介してコマンドを実行しようとする。

```
$ ssh -x git@github.com "git-receive-pack 'r7kamura/example.git'"
```

## git-receive-pack
git-receive-packは、サーバの持っているそれぞれのrevisionへの参照を出力する。
例えばrefs/heads/masterのSHA1値や、refs/tags/v0.0.1のSHA1値といった情報がここで出力される。
GitreceivedはSSH接続経由でgit-receive-packを呼び出すよう命ぜられたとき、
即ちクライアントでgit pushが実行されたとき、
git-shellを利用して (本来呼び出されるべき) git-receive-packコマンドを実行している。

しかしながら、GitreceivedはSSH接続元クライアントから命ぜられるままgit-receive-packを実行するだけではなく、
git-receive-packを呼び出す直前にある処理を行っている。
それは「push先のGitレポジトリがサーバ側にまだ存在しなかった場合、
あるpre-receiveフックを仕込んだGitレポジトリを新たに作成する」という処理である。

## pre-receive
クライアントからのプッシュを処理するときに最初に実行されるスクリプトがpre-receiveである。
レポジトリ内のpre-receiveに任意の処理を記述しておくことで、
そのレポジトリにgit pushされたときの挙動を変更することができる。
このスクリプトには、プッシュにより変更される以前のrevision、変更後のrevision、
そして変更対象の参照の名前 (e.g. git push origin masterの場合はrefs/heads/master)
が標準入力で渡される。

Gitreceivedは、新しくGitレポジトリを作る際に以下のようなスクリプトをpre-receiveに追加する。
set -eは途中のコマンドがエラーだった場合に即時終了するようにするオプションで、
set -o pipefailはパイプ処理の途中でエラーが発生した場合にもエラーを返すようにするというオプション。
`{{RECEIVER}}`の部分は、実際にはGitreceived起動時に渡したファイルパスが入る。
即ち、Gitreceived起動時に指定しておいたコマンドがgit pushされるたびに実行されることになる。
sedの部分は、RECEIVERからの出力を整形するためのもの。
出力をバッファに溜めずに即時吐き出すようにするためにオプションを指定しているが、
Darwinとそれ以外とでオプション名が異なるので頑張っている。
sedを利用する本来の目的は、後述のエスケープコードを埋め込むためである。

```
#!/bin/bash
set -eo pipefail

while read oldrev newrev refname; do
  [[ $refname = "refs/heads/master" ]] && git archive $newrev |
  {{RECEIVER}} "$RECEIVE_REPO" "$newrev" |
  sed -$([[ $(uname) == "Darwin" ]] && echo l || echo u) "s/^/"$'\e[1G'"/"
done
```

## ANSI escape code
ANSIエスケープコードの中に「CSI n G」というパターンがあり、
カーソルの位置を先頭からn列目に移動せよ、という意味を持つ。
CSIはControl Sequence Introducerのことであり、bashなどでは`\e[`のような表記法が用いられる。
nは任意の自然数、Gはそのまま文字列のGを指す。例えばシェルの中では`\e[2G`のように使うことができる。
他に「CSI K」というパターンがあり、現在のカーソル行から末尾までを削除せよ、という意味を持っている。

Gitのpre-receiveから標準出力を行うと、prefixとして必ず「remote:」という文字列が付随することになる。
この文字列を画面に表示したくない場合の対策として、上記のANSIエスケープコードが利用できる。
Herokuではgit push時に「remote:」の代わりに「----->」が表示されるが、
これも同様の手法で実現できる。

```
$ echo 'xxx\e[2Gy'
xyx

$ echo 'xxx\e[2G\e[K'
x

$ echo 'remote: \e[1G-----> Wow!'
-----> Wow!

$ echo 'remote: \e[1G\e[KYay!'
Yay!
```

## Gitreceive
GitreceivedはGitreceive(末尾のdが無い)の後継機として開発されている。
GitreceivedがFlynn用に、GitreceiveがDokku用にそれぞれ開発されている。
Gitreceiveについては下記の記事をどうぞ。  
[Gitreceive - r7km/s](http://r7kamura.github.io/2014/02/27/gitreceive.html)

## sysexits(3)
gitreceivedのコードの中に、終了コード64と共に終了する箇所がある
([★](https://github.com/flynn/gitreceived/blob/d828619bceb1937a5daad1dceea6320e9d3b3d4f/gitreceived.go#L51))。
例えばBSDでは終了コードを標準化しようとしており、
終了コード64はsysexits(3)でEX_USAGEとして定義されている。
これはコマンドの使い方が間違っていることを示唆するためのものと解釈できる。

```
EX_USAGE (64)
   The command was used incorrectly, e.g., with the wrong number of arguments,
   a bad flag, a bad syntax in a parameter, or whatever.

── sysexits(3)より引用
```

## flynn/go-shlex
go-shlexはシェルスクリプト用のパーサで、
これを使えばシェルスクリプト上の引用符やエスケープなどを適切に扱える。
例えばone "two three" fourがコマンドライン引数として与えられたとき、
["one", "two three", "four"]の三要素で構成されているということを認識できる。

```
shlex.Split('one "two three" four')
```

## go.crypto/ssh
[code.google.com/p/go.crypto/ssh](https://godoc.org/code.google.com/p/go.crypto/ssh)
がSSHサーバの機能を提供している。
SSHサーバとしてリクエストを待ち受ける機能のほか、
公開鍵認証時にフックできる仕組みを提供しており、
gitreceivedはこのフックを利用して任意のコマンドを利用した認証機能を実現している。

## SSH channel type
SSHはクライアントとサーバ間の1つの接続の中で、複数のチャンネルを同時に利用できる。
これは多重チャンネルと呼ばれる概念であり、
SSHの仕様ではコネクションプロトコルという名前のプロトコルでこの仕様が定義されている。

```
       <------#0------>
client <------#1------> server
       <------#2------>
```

SSHの大まかな仕様はRFC4251からRFC4254の4つのRFCで定義されているが、
このうちコネクションプロトコルはRFC4254で定義されている。
つまりチャンネルの概念はRFC4254で定義されている。
SSHのチャンネルには以下の4つの種類〈チャンネルタイプ〉が定義されており、
チャンネルタイプごとに異なる機能を実現する。

* direct-tcpip
* forwarded-tcpip
* x11
* session

direct-tcpipは外向きのTCPフォワーディング、
forwarded-tcpipは内向きのTCPフォワーディング、
x11はX11クライアントの接続、
sessionはプログラムのリモート実行を表す。
日常的に利用されるほとんどのSSH接続の種類はsessionであると言っても良い。
例えば、RubyのNet::SSHではx11のチャンネルタイプをサポートしていない。
gitreceivedが扱うチャンネルタイプはsessionだけであり、
これ以外の種類のチャンネル接続要求があった場合には拒否するようになっている。

* [Net::SSH Manual :: Chapter 3: Channels](http://net-ssh.github.io/ssh/v1/chapter-3.html)
* [RFC 4254 - The Secure Shell (SSH) Connection Protocol](http://tools.ietf.org/html/rfc4254)
* [SSH サーバを作る(その 22) コネクションプロトコル - Going My Ruby Way - Rubyist](http://rubyist.g.hatena.ne.jp/lnznt/20110911/1315735390)
