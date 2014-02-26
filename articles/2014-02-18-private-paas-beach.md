---
title: Private PaaS Beach
---

## Dokku
[https://github.com/progrium/dokku/](https://github.com/progrium/dokku/)  
Dokkuを使えばmini-Herokuのような環境を簡単に構築出来る。
Dokkuを利用して構築したホストに対してgit pushでコードをデプロイすると、
HerokuのBuildpacksの仕組みを利用して環境が構築され、
Dockerのコンテナ上でアプリが起動し、nginxの設定が更新される。
Dokkuのホスト上でnginxがHTTPリクエストを待ち受けており、
サブドメインを元に適切なコンテナにリクエストを渡すという仕組みになっている。

## Digital Ocean
[https://www.digitalocean.com/](https://www.digitalocean.com/?refcode=3eaa05dda32a)  
Dokkuを試しに使ってみるにはDigital Oceanを利用するのが便利。
最初からDokkuがインストールされた状態のイメージが用意されていること、
1時間毎の都度課金なので使わないときには停止しておけば良いこと、
月5$で安い割にSSDが付いていて性能が良いこと、日本に近いシンガポールリージョンがあること、
10$分無料のクーポンコード(SSD2014)があること、Dokkuの構築完了まで全てブラウザだけで完結すること、
などがDigital Oceanが便利な部分。以下の手順で環境構築は完了、好きなアプリをデプロイし放題です。

1. Sign Upする
2. クレカ情報を登録する
3. SSH公開鍵を登録する
4. Dokkuインストール済みのDroplet(=インスタンス)を作成する
5. DropletのIPアドレス(=Dokkuの初期設定画面)をブラウザで開く

## デプロイ
HerokuのBuildpackに対応している形式のアプリであれば何でもデプロイできる。
以下の例では、試しにRackアプリを置いてみている。
Rackアプリをつくる場合には、Gemfile、Gemfile.lock、config.ruがあれば良い。
`dokku@<DropletのIPアドレス>:<任意のアプリ名>`にgit pushすればデプロイされる。
今回独自ドメインを設定していないのでIPアドレスとポート番号になっているけれど、
自分でドメインを設定すればアプリごとに別々のサブドメインが割り振られるようになる。

```
$ mkdir tinyrack
$ cd tinyrack
$ echo 'source "https://rubygems.org"' >> Gemfile
$ echo 'gem "rack"' >> Gemfile
$ echo 'run ->(*) { [200, {}, ["Hello, world\\n"]] }' >> config.ru
$ bundle install
$ git init
$ git add .
$ git commit -m "Initial commit"
$ git push dokku@127.199.238.184:tinyrack master
$ curl http://127.199.238.184:49156
Hello, world
```

## DockerUI
[https://github.com/crosbymichael/dockerui](https://github.com/crosbymichael/dockerui)  
DockerUIというDocker管理用のアプリをDokku上にデプロイしておくと、Dockerの様子がブラウザで確認出来て便利。
DockerのプロセスはREST APIを持ったHTTPサーバを起動させており、HTTP経由でDockerを操作することが出来る。
DockerUIはHTML/CSS/JavaScriptで作られていて、JavaScriptからDockerのAPIにアクセスすることで管理画面を実現している。
認証機能が無いので、インターネットからアクセス出来る場所に置く場合は自分で設定する必要がある。
DockerUIの他には[Shipyard](https://github.com/shipyard/shipyard)などのツールがある。

```
$ ssh root@127.199.238.184
> echo 'DOCKER_OPTS="-H unix:///var/run/docker.sock -H tcp://0.0.0.0:4243 -api-enable-cors"' >> /etc/default/docker
> restart docker
> exit
$ git clone git@github.com:crosbymichael/dockerui.git
$ cd dockerui
$ git push dokku@127.199.238.184:dockerui master
$ ssh dokku@127.199.238.184 config:set dockerui DOCKER_ENDPOINT=http://127.199.238.184:4243
$ open http://127.199.238.184:49154
```

![](/images/2014-02-18/dockerui.png)

## 最初から動く環境
最初は手元のMac OSX上でDokkuを動かそうとしたのだけど、
久しぶりにMacでDockerを動かそうとして、そもそも最近DockerがMacをサポートしたという件について調べたり、
その件についてドキュメントが少なくて困ったり、実際にやってみたところ上手く動かせなかったり、
Vagrantを入れ直してDockerが動くUbuntuのイメージを取得し直したり、
Dokkuのセットアップ用のコードが上手く動かなかったり、
MacとVagrantとDockerの間のPort Forwardingが問題なのか自分のやっていることが問題なのか分からなかったりした。
人生は短い。
