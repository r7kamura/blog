---
title: Flynn Overview
---

![](/images/2014-07-17/flynn-overview.png)

[Flynn](https://flynn.io/) という、コンテナを複数ホストで動作させるPaaS実装の全体像。
ここには記載していないが、全てのノードでetcdとdiscoverdというPubSub機能を持ったKVSが動作しており、
あるノードに変更があった場合 (ノードの追加や設定の変更など) に他のノードはそれを知ることができ、
また他のノードのアドレスを名前から検索できるようになっている。
