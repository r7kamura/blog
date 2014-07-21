---
title: Golang Reverse Proxy
---

## 単一ホスト用のリバースプロキシを実装する
net/http/httputilで、HTTP用のReverse Proxyを実装するためのライブラリが提供されている。
下記のコードで、http://127.0.0.1:3000 から http://127.0.0.1:9292 にHTTPリクエストを委譲するReverse Proxyが動作する。

httputil.NewSingleHostReverseProxyはhttputil.ReverseProxyのインスタンスを返す。
このインスタンスはhttp.Server互換の (.ServeHTTPメソッドに呼応できる) オブジェクトであるため、
http.Serverを利用してHTTPサーバを動作させられる。

```
// main.go
package main

import(
	"net/http"
	"net/http/httputil"
	"net/url"
)

func main() {
	sourceAddress := ":3000"
	destinationUrlString := "http://127.0.0.1:9292"
	destinationUrl, _ := url.Parse(destinationUrlString)
	proxyHandler := httputil.NewSingleHostReverseProxy(destinationUrl)
	server := http.Server{
		Addr: sourceAddress,
		Handler: proxyHandler,
	}
	server.ListenAndServe()
}
```

## 委譲処理を自分で実装する
httputil.NewSingleHostReverseProxyを利用すると、
単一ホスト用のリバースプロキシを提供するhttputil.ReverseProxyのインスタンスが生成できた。
この関数を経由せず自分でこのインスタンスを生成することで、
リクエストを受け取ったときに任意の挙動を実行するインスタンスが生成できる。

httputil.ReverseProxyは、以下の3つのプロパティを持つ。
このうち、Directorが受け取ったHTTPリクエストをプロキシ前に変換するための役割を司る。
他は指定しなければ適宜デフォルトの値が利用される。
NewSingleHostReverseProxyも、
仕組みとしては受け取ったURLからこのDirectorプロパティを組み立てているだけである。

* Director func(*http.Request)
* Transport http.RoundTripper
* FlushInterval time.Duration

NewSingleHostReverseProxyを利用せずに上例のようなReverseProxyを生成するとこんな感じになる。

```
package main

import(
	"net/http"
	"net/http/httputil"
)

func main() {
	sourceAddress := ":3000"
	director := func(request *http.Request) {
		request.URL.Scheme = "http"
		request.URL.Host = ":9292"
	}
	proxy := &httputil.ReverseProxy{Director: director}
	server := http.Server{
		Addr: sourceAddress,
		Handler: proxy,
	}
	server.ListenAndServe()
}
```

## 複数ホスト用のリバースプロキシを実装する
委譲処理を自分で実装する方法が分かったので、
与えた複数のURLに順番にリクエストを委譲する、つまりラウンドロビン方式のロードバランサを実装してみる。
今回は順番にアクセスする機能のために循環リストを使うことにする。
標準ライブラリのcontainer/ringにring.Ringという循環リストのための型が実装されているので、これを利用する。

```
package main

import(
	"container/ring"
	"net/http"
	"net/http/httputil"
	"net/url"
	"sync"
)

func main() {
	sourceAddress := ":3000"

	ports := []string{
		":9293",
		":9292",
	}
	hostRing := ring.New(len(ports))
	for _, port := range ports {
		url, _ := url.Parse("http://127.0.0.1" + port)
		hostRing.Value = url
		hostRing = hostRing.Next()
	}

	mutex := sync.Mutex{}
	director := func(request *http.Request) {
		mutex.Lock()
		defer mutex.Unlock()
		request.URL.Scheme = "http"
		request.URL.Host = hostRing.Value.(*url.URL).Host
		hostRing = hostRing.Next()
	}
	proxy := &httputil.ReverseProxy{Director: director}
	server := http.Server{
		Addr: sourceAddress,
		Handler: proxy,
	}
	server.ListenAndServe()
}
```

これで:3000から:9292と:9393に対して交互にHTTPリクエストを委譲する簡単なリバースプロキシが出来た。
Directorはgoroutineを利用して並列に実行される可能性があるため、
sync.Mutexを利用して循環リストへのアクセスを単純にロックしている。

## etcdを使う
上例ではルーティング情報 (=どのホストにHTTPリクエストを委譲するか) はコード内に記述されていた。
プログラムの外部から動的にルーティング情報を変更するため、etcdというKey-Value Storeにルーティング情報を保存する。
git-clone(1) で手元にダウンロードしてきた後、./buildというシェルスクリプトを実行すれば
./bin/etcd にetcdの実行ファイルがコンパイルされる。

```
$ git clone https://github.com/coreos/etcd
$ cd etcd
$ ./build
$ ./bin/etcd
```

./bin/etcd を実行するとサービスが起動する。
デフォルトでは127.0.0.1:4001でクライアント・サーバ間の通信のためのAPIが提供され、
同時に127.0.0.1:7001でサーバ間の通信のためのAPIが提供される
(Golang製のサービスでは並列化の実現が容易であるため、このように複数のサービスを1つのプログラムで提供することが多い)。

簡単なKey-Value Storeとして利用してみる。
以下の例ではkey1に適当な値を格納したあと、その値を取得している。
wait=trueクエリパラメータを付けると、Long Pollingを利用して該当するキーに変更があるまで応答を待ち続ける。
この機能は、例えばクラスタ内の複数のノードが同じ設定を保ち続けるという処理を実現するのに利用できる。

```
$ curl :4001/v2/keys/key1 -X PUT -d value="value1"
$ curl :4001/v2/keys/key1
$ curl :4001/v2/keys/key1?wait=true
```

下記はGolang用のクライアントライブラリgo-etcdを利用する例。
etcdは値をファイルシステムのディレクトリ構造のようなツリー構造で表現するため、
NodeやRescursiveと言った表現が登場する。

```
package main

import(
	"fmt"
	"github.com/coreos/go-etcd/etcd"
)

func main() {
	endpoints := []string{"http://127.0.0.1:4001"}
	client := etcd.NewClient(endpoints)

	// Set key1 with value1
	response, _ := client.Set("key1", "value1", 0)
	fmt.Println(response.Node.Value)

	// Get key1 with no-sort and no-recursive options
	response, _ = client.Get("key1", false, false)
	fmt.Println(response.Node.Value)
}
```

## ルーティング情報をetcdに保存する
受け取ったHTTPリクエストのHostヘッダの値を元に、
予めetcdに設定された委譲先にリクエストを委譲するリバースプロキシをつくる。
1つのHostヘッダの値に対して複数の委譲先が存在する(つまりロードバランサとしても運用する)
可能性があるため、今回は /hosts/:host/:endpoint というキーを利用することにする。
:hostにはHostヘッダの値 (例: blog.example.com)、:endpointには委譲先のアドレス (例: 123.45.67.89:3000) が入る。
キー名で全ての必要なデータが表現できるため値は利用しない。

net/http/httputilのhttputil.ReverseProxyは、
委譲先を決定するためのロジックをDirectorという関数で外部から注入できるが、
Directorでは受け取ったリクエストの情報を参照できない。
そのため、これを行えるリバースプロキシ用の実装をhttp.Transport等を利用して自前で行う必要がある。

## http.Transport型
標準ライブラリnet/httpで定義されている、http.Transport型。
低レベルなHTTPクライアントの実装であり、例えばnet/http/httputilのhttputil.ReverseProxyから利用されている。
通常、HTTPクライアントが使いたい場合はより高級なhttp.Clientを使うのが一般的である。
クッキーやリダイレクトといった高級な機能を利用する場合はそちらを利用するのが妥当。

## 標準ライブラリのパス
HomebrewでGoをインストールした場合、例えばnet/httpのソースコードは
/usr/local/Cellar/go/1.2.1/libexec/src/pkg/net/http
というパスに配置されている。

## http.Transport#Roundtrip
http.Transport型はhttp.Roundtripインターフェースの実装であり、
http.Roundtripの持つべきメソッドRoundTrip(*http.Request)を実装している。
http.TransportのRoundtripメソッドは、
引数で受け取ったHTTPリクエストのURLとHostヘッダを参照してリクエストを送信する。
特筆すべき点として、keepaliveが有効化されていた場合に同じTCP接続を使い回せるようになっており、
またプロキシを設定できる機能を備えている。
