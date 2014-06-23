---
title: Discoverd
---

[flynn/discoverd](https://github.com/flynn/discoverd)という、Golang製のService discovery systemを読んだ。

## 何ができるのか
クラスタ内の全ホストでdiscoverd(とetcd)を動作させておくことで、
各ホストのアドレスやメタ情報、クラスタへのホストの追加や削除などの情報が簡単に購読できるようになる。
各ホストは名前ベースで管理されるため、同じ名前を持つホストを群として一律に扱うこともできる。

## 具体的には
discoverdは各ホストから発行されるRegisterイベントとUnregisterイベントを検知し、
discoverdに対してsubscribeしていたクライアントにこれらのイベントを伝える機能を持っている。
例えばdiscoverdを動作させているあるクラスタにsubscribeしているクライアントは、
10.0.0.1と10.0.0.2のホストがこのクラスタに参加(=Register)してきたとき、
これらのイベントを知ることができる。
またホストはRegister時に任意の情報を与えることができ、
subscribeしているクライアントはこの情報も受け取ることができる。

## discoverdとクライアントはどう通信するか
クライアントからのRegister & Unregister要求は単純なリクエスト & レスポンスの通信で実現できる。
Subscribe要求ではイベントを待ち受ける形になるため、ストリーム型のコネクションでdiscoverdに接続する形になる。
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

## Subscribeされたとき何が起こるのか
クライアントがサービス名を渡してSubscribeしてきたとき、
まずサービス名に一致する情報をetcdから探してきて更新情報として返し、
次にそれ以降でサービスの情報に変化があれば随時更新情報を返す
(GoroutineとChannelでブロッキングして待ち受ける)。

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
