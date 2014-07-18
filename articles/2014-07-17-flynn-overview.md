---
title: Flynn Overview
---

![](/images/2014-07-17/flynn-overview.png)

[Flynn](https://flynn.io/) という、コンテナを複数ホストで動作させるPaaS実装の全体像。

## strowger
リバースプロキシ。  
ユーザからTCP/UDPリクエストを受け付けて適切なホスト (の中で動いているDockerコンテナ) に委譲する。
HAProxyやNginxのようなものだが、再起動や設定ファイルの再読込無しで動的に設定が変更できるという特徴がある。
controllerからHTTP経由でリクエストを受けて、ルーティング情報を表示したり変更したりする。

## gitreceived
git-push(1) を受け付けて適当な処理を行うためのSSHサーバ実装。  
受け取ったコードをslugbuilderというツールで実行可能な形式 (=slug)
にコンパイルしたあと、Shelfと呼ばれるファイルサーバにslugをアップロードする。
アップロード後、controllerに対してアプリがpushされた旨を伝える。

* [Gitreceived - r7km/s](/2014/06/29/gitreceived.html)
* [Slugbuilder - r7km/s](/2014/07/16/slugbuilder.html)

## controller
各種ノードを管理するための汎用APIサーバ。  
REST APIを提供しており、アプリの追加やコンテナの追加など、
アプリ開発者や各種ツールからHTTPリクエストを受けて様々な処理を行う。
PostgreSQLを利用してアプリに関する情報を永続化している。

## scheduler
アプリサーバにコンテナを配置するためのシステム。  
PostgreSQLのPubSub機能 (LISTEN & NOTIFY) を利用して変更を監視し、コンテナの状態
(=実行するコマンドやコンテナ数など) が常に理想的であるように、クラスタ内のリーダーホストに命令を送って調整を行う。

## host
Dockerコンテナを動かすマネージャ。  
全てのhostノードの中から自動的にリーダーノードが選出され、
リーダーノードがAPI経由でリクエストを受け取って他のhostノードに命令を行う。
例えばschedulerからあるジョブを動かすように命じられると、
リーダーノードはhostノードの内から1つ選んでコンテナ内でジョブを動作させる。

* [Flynn Host - r7km/s](/2014/06/26/flynn-host.html)

## etcd & discoverd
全てのノードで同じ設定を参照するための仕組み。  
図には記載していないが、全てのノードでetcdとdiscoverdというPubSub機能を持ったKVSが動作しており、
あるノードに変更があった場合 (ノードの追加や設定の変更など) に他のノードはそれを知ることができ、
また他のノードのアドレスを名前から検索できるようになっている。
またCluster内のホストの中からリーダーを選出する用途にもetcdが使われている。

* [Etcd - r7km/s](/2014/02/26/etcd.html)
* [Discoverd - r7km/s](/2014/06/24/discoverd.html)
