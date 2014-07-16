---
title: Slugbuilder
---

[flynn/slugbuilder](https://github.com/flynn/slugbuilder)
という、アプリを実行可能な形式にコンパイルするツールを読んだ。

## Slug
ここで言っている実行可能な形式とは、Heroku上で [slug](https://devcenter.heroku.com/articles/platform-api-deploying-slugs)
と呼ばれているもので、ソースコード・依存ライブラリ・実行環境をtar形式にまとめてGzip圧縮したものである。

## 使われ方
flynnでは、コンテナで実行させたいアプリがgit pushされたときにslugbuilderが実行され、
アプリ用のslugが生成され、shelfと呼ばれるファイルサーバ経由で配布され、sluglunnerで実行される。

1. discoverd & flynn-host を使ってコンテナを動かすホスト群のクラスタが形成される
2. gitreceived を使ってGitサーバが git-push(1) を待ち受ける
3. gitreceived が git-push(1) に呼応してflynn-receiveを実行する
4. flynn-receive が slugbuilder を利用してslugを作成する
5. slugrunnerでslugを実行する というジョブを生成する
6. schedulerがホスト群にジョブを配布する

## 使い方
slugbuilderはGo製のコマンドラインツールが付属したDockerイメージとして提供され、
Dockerが動く環境であれば動作する。
git-archive(1) から出力されたtar形式のバイナリデータを標準入力経由で受け取り、
flynn/slugbuilderというDockerイメージから生成したコンテナ上でslugを生成して標準出力する。
使用例は次の通り。

```
$ docker pull flynn/slugbuilder
$ git archive master | docker run -i -a stdin -a stdout flynn/slugbuilder - > myslug.tgz
```

これでカレントディレクトリにmyslug.tgzというファイルが出来上がる。
例えば単純なRuby製のアプリであれば容量は15MB程度。
このslugを解凍すると、
元のGitレポジトリに含まれていたファイルのほか、
vender以下にRuby 2.0.0と依存ライブラリ (=Gem) が追加されていることが分かる。

## Dockerfile
https://github.com/flynn/slugbuilder/blob/master/Dockerfile

docker pull flynn/slugbuilder を実行すると、
[DockerHubのflynn/slugbuilder](https://registry.hub.docker.com/u/flynn/slugbuilder/)
に登録されたDockerイメージを手元に作成する。
イメージ作成時には、必要そうなbuildpacksをgit-clone(1)で/tmp/buildpacksにダウンロードしている。
また、slugbuilderというユーザを作成しており、
コンテナ起動時にはslugbuilderユーザでbuilder/build.shを実行するように設定されている。

## builder/build.sh
https://github.com/flynn/slugbuilder/blob/master/builder/build.sh

docker(1) 経由で実行されるシェルスクリプト build.sh は以下のような挙動をする。

1. 出力方法の選択 (ファイルに出力するか、標準出力を使うか、標準エラー出力は必要か)
2. 標準入力からtarballの受信
3. tarballの解凍
4. buildpacksの適用 (対応するbuildpackの判定→コンパイル→仕上げ)
5. tarballの作成
6. 指定されたURLへのslugのアップロード (URLが指定されていた場合のみ)

## 参考
* Slugの説明 - [Creating slugs from scratch | Heroku Dev Center](https://devcenter.heroku.com/articles/platform-api-deploying-slugs)
* flynnの全体像 - [DockerによるマルチホストのPaaS flynnの概要とそのアーキテクチャー | SOTA](http://deeeet.com/writing/2014/07/07/flynn/)
