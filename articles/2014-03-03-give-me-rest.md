---
title: Give me REST
---

人の手でREST APIをつくるのに疲れたので、
REST API生成用のフレームワークについて思いを少し巡らせた。
フレームワークはConnector < Module という二層構造で構成する。
ConnectorというDB接続用のアプリを、
Moduleと呼ばれる幾つかのMiddlewareで内包する形。
例えばDBにはMySQLやMongoDB、WAFにはRackなどが使える。

## Connector
ConnectorはDBの為のHTTPラッパーとしての責務を負う。
具体的には、HTTPリクエストを解釈してDBに問い合わせる機能と、
DBからの応答をHTTPレスポンスに変換する機能だけを持つ。
実際に利用するDBと疎結合にするため、Connectorの内部実装も層構造になることが予想される。
Connectorを取り替えることで別のDBも利用出来る。
例えば一般的なRDBを使う代わりに、
更に別のAPIにリクエストを委譲する等の用途が考えられる。
既存のAPIから徐々に移行していきたい場合などに必要になる。

## Module
* Validation
* OAuth
* Logging
* Caching
* MIME
* HATEOAS
* Interface

必要に応じてコアの機能をモジュールで拡張する。
OAuthモジュールは、リクエストのAuthorizationヘッダからアクセストークンを取り出し、ユーザ認証を行う(違反していればエラーを返す)。
Validationモジュールは、予め与えられたインターフェース定義に沿ってリクエストの型や内容を検閲する(違反していればエラーを返す)。
Loggingモジュールは、リクエストとレスポンスの結果を指定された場所に書き込む。
CachingモジュールはレスポンスをHTTPレイヤでキャッシュする。
MIMEモジュールはレスポンスデータを適切なフォーマットに変換する。
HATEOASモジュールはリソース間を遷移するためのリンク情報を提供する。
InterfaceモジュールはAPIのインターフェース仕様を表現し、
サーバ・クライアント間でAPIの知識を共有する(クライアントコードの自動生成等に利用する)。
任意のAPIへのリクエストを許す代わりに、ValidationモジュールやInterfaceモジュールでリクエストを制限出来る。

## Eve
[Eve](http://python-eve.org/index.html)
というPython製でWSGIベースのREST API用フレームワークがあり、
少なからず影響を受けている。

## Parse
MBaaSを提供する [Parse](https://parse.com/docs/rest)
も近い機能を有している。

## Restaurant
MongoDBの単純なRailsラッパーとして
[Restaurant](https://github.com/r7kamura/restaurant/)
という試作品を以前に一度つくっている。

## Rack::Spec
REST APIの為のRack-Middlewareとして [rack-spec](https://github.com/r7kamura/rack-spec) というのを作ったことがある。

## おわりに
疲れていたので考えたことを思い付くままに書いてみたけど、レゴで遊ぶときみたいにあまり難しく考えず、
各自適当に必要になりそうなMiddlewareやConnectorを気が向いたらつくっていって、
最後にせーので合体して完成させられるとかっこ良さそう。
