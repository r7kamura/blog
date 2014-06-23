---
title: Discoverd
---

[flynn/discoverd](https://github.com/flynn/discoverd)という、Golang製のService discovery systemを読んだ。

## discoverdとは
discoverdは、etcdというKVSをバックエンドに利用して動作し、RPC経由でAPIを提供する。
各ホストでetcdとdiscoverdを動作させておくことで、
全てのホストがお互いの状態を把握している状態を作り出すことができる。
複数のホストをまとめたクラスタを管理する用途に利用されることが想定される。

## 何ができるのか
discoverdは各ホストから発行されるRegisterイベントとUnregisterイベントを検知し、
discoverdに対してsubscribeしていたクライアントにこれらのイベントを伝える機能を持っている。
例えばdiscoverdを動作させているあるクラスタにsubscribeしているクライアントは、
10.0.0.1と10.0.0.2のホストがこのクラスタに参加(=Register)してきたとき、
これらのイベントを知ることができる。
またホストはRegister時に任意の情報を与えることができ、
subscribeしているクライアントはこの情報も受け取ることができる。

## discoverdとクライアントはどう通信するか
イベントは不定期に発生するため、
クライアントはストリーム型のコネクションでdiscoverdに接続する形になる。
この辺りの実装はRPC用のライブラリを利用して実現されている。

## etcdには何が保存されるのか
discoverdはKVSとしてetcdを利用するが、
このときkeyには「/discover/services/{name}/{addr}」というパターンの文字列を、
valueには「文字列を値に持つObjectをJSONでエンコードした文字列」を利用する。
{name} にはRegisterやUnregisterのイベントと共に送られるサービス名が利用される。
{addr} には各サービスのアドレスが利用される。
JSONエンコードされるのは、Registerイベントと共に送られた任意の情報を表現したObjectである。
つまりサービスがRegisterされているとき、そのサービスの情報がetcdに保存されることになる。

## Register/Unregisterされたとき何が起こるのか
Registerリクエストを受け取ると、discoverdはetcdに値を書き込んでレスポンスを返す。
Unregisterはその逆で、etcdから値を消してレスポンスを返す。

## Subscribeされたときにdiscoverdでは何が起こるのか
クライアントがサービス名を渡してSubscribeしてきたとき、以下の処理が行われる。

1. 以下LoopとChannelとGoroutineを使って更新情報を待ち受ける
1. そのサービス名に一致するサービスの情報をetcdから複数件探して更新情報として返す
1. 空の更新情報を返す (2と4を区別するために空の情報を送っているのだろうか?)
1. それ以降でサービスの情報に変化があれば随時更新情報を返す

## まとめ
まとめると、discoverdは次の3つの機能を持っている。

* Register - ホストの登録
* Unregister - ホストの削除
* Subscribe - サービス名ベースでのホストの更新情報の待受

そしてdiscoverdの機能は、etcdの持つ次のような機能の上に成り立っている。

* KVS
* クラスタリング
* 更新通知の待受
* 再帰的な値の探索
