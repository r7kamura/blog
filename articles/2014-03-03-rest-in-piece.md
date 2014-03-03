---
title: REST in Piece
---

人の手でREST APIをつくるのに少し疲れた。

## Overview
REST API生成用のフレームワークがあればなと思い、少し思考を巡らせる。
Adapter < Module という二層構造で構成されたフレームワーク。
AdapterというDB接続用のアプリを、
Moduleと呼ばれる幾つかのMiddlewareが内包する。

## Adapter
AdapterはDBの為のHTTPラッパーとしての責務を負う。
具体的には、HTTPリクエストを解釈してDBに問い合わせる機能と、
DBからの応答をHTTPレスポンスに変換する機能だけを持つ。
実際に利用するDBと疎結合にするため、Adapterの内部実装も層構造になることが予想される。
Adapterを取り替えることで別のDBも利用出来る。
例えば一般的なRDBを使う代わりに、
更に別のAPIにリクエストを委譲する等の用途が考えられる。
既存のAPIから徐々に移行していきたい場合などに必要になる。

* ActiveRecordAdapter
* MongoidAdapter
* SomeAPIAdapter

## Module
必要に応じてコアの機能をモジュールで拡張する。

* Authentication - OAuth認証やBasic認証を行う
* Caching - HTTPレイヤでのキャッシュ (ETag等)
* HATEOAS - リソース間を遷移するためのリンク情報を提供する
* Interface - インターフェース定義を宣言する
* Logging - リクエスト & レスポンスのログを取る
* MIME - 最適なContent-Typeに変換する
* Validation - 与えられたインターフェース定義を元にリクエストを検閲する

## Examples
* [Eve](http://python-eve.org/index.html) - Python製のREST API用フレームワーク
* [Parse](https://parse.com/docs/rest) - REST APIも提供するMBaaS
* [Restaurant](https://github.com/r7kamura/restaurant/) - MongoDBの単純なRailsラッパー
* [Rack::Spec](https://github.com/r7kamura/rack-spec) - REST APIの為のRack-Middleware
* [Rack::MongoidAdapter](https://github.com/r7kamura/rack-mongoid_adapter) - Rack用のMongoidラッパー

## おわりに
疲れていたので考えたことを思い付くままに書いてみた。
レゴで遊ぶときみたいにあまり難しく考えず、
各自適当に必要になりそうなMiddlewareやAdapterを気が向いたらつくっていって、
最後にせーので合体して完成させられるとかっこ良い。
特に何か新しい発想はなくて、品質の良いパーツがもう少し増えていって、
組み合わせるだけで何か出来るようになったらいいなという話だった。
