---
title: Gitreceive
---

[gitreceive](https://github.com/progrium/gitreceive)
という、git push時に任意の処理を実行する為のツールがある。
[Dokku](http://r7kamura.github.io/2014/02/18/private-paas-beach.html)
の中で同様の仕組みが使われており、
git push時にbuildpacksでアプリをbuildしDockerコンテナの中で動かす、
という機能を実現している。

## 認証機能
gitreceiveはSSH公開鍵登録用インターフェース、
及び公開鍵を利用した簡易的な認証機能を持っているが、
公開鍵を登録したユーザからのPushのみを許可するというもので、
Pushするアプリケーションごとに別々の権限を与えるということは出来ない。

## forced command
gitreceiveはSSHのforced commandと呼ばれる機能を利用している。
forced commandを使うと「SSH接続時に何をするか」という情報を、
クライアント側ではなくサーバ側で指定出来る。
OpenSSHでは、authorized_keysに実行したいコマンドを指定することで実現出来る。
gitreceiveはSSH公開鍵の登録時にforced commandを使い、
git pushによりSSH接続が行われた際に
/home/${GITUSER}/gitreceive を実行している。
Dokkuでは、このタイミングで /user/local/bin/dokku を実行している。

## Receiver
gitreceiveにより実行されるファイルをReceiverと呼ぶ。
Receiverには、Pushされたレポジトリ名、リビジョン、ユーザ名などが引数で渡され、
Pushされたデータの内容は標準入力で受け取れる。
gitreceiveのREADMEでは、git push時にHTTPリクエストを送る例を紹介している。
Receiverの内容を変更することで、
例えばモニタリングに利用したり、
DokkuのようにDockerコンテナにアプリをデプロイしたりということが可能になる。

## gitreceive-next
gitreceiveの次期バージョンとして、現在
[gitreceive-next](https://github.com/flynn/gitreceive-next)
が開発されている。
gitreceiveはSSHのフックを設定するための単純なShellScriptだったが、
gitreceive-nextはGo言語製のSSHサーバとして実装されている。
主な用途はgit pushを待ち受けることではあるものの
Gitに依存する処理はほぼ取り除かれており、
起動時に指定された実行ファイルに対してSSH接続を委譲するための認証機能付きリバースプロキシ、というような存在になっている。
今後は権限やルーティング管理、複数ノード間での設定共有などの機能を追加予定とのこと。
