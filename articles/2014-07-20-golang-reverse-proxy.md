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

## Hostベースのリバースプロキシを実装する
net/http/httputilのhttputil.ReverseProxyは、
委譲先を決定するためのロジックをDirectorという関数で外部から注入できるが、
Directorでは受け取ったリクエストの情報を参照できない。
そのため、これを行えるリバースプロキシ用の実装をhttp.Transport等を利用して自前で行う必要がある。

今回は [r7kamura/entoverse](https://github.com/r7kamura/entoverse) を使う。
entoverseはHostベースのリバースプロキシを生成するためのライブラリであり、
受け取ったHostを委譲先のHostに変換するロジックを与えるとリバースプロキシが出来上がるようになっている。
以下の例は最も単純な例の一つで、3000番ポートで受け取ったHTTPリクエストを4000番ポートに委譲する。

```
package main

import(
    "net/http"
    "github.com/r7kamura/entoverse"
)

func main() {
    // Please implement your host converter function.
    // This example always delegates HTTP requests to localhost:4000.
    hostConverter := func(originalHost string) string {
        return "localhost:4000"
    }

    // Creates an entoverse.Proxy object as an HTTP handler.
    proxy := entoverse.NewProxy(hostConverter)

    // Runs a reverse-proxy server on http://localhost:3000/
    http.ListenAndServe("localhost:3000", proxy)
}
```

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
可能性があるため、今回は /hosts/:host/:upstream というキーを利用することにする。
:hostにはHostヘッダの値 (例: blog.example.com)、:upstreamには委譲先のアドレス (例: 123.45.67.89:3000) が入る。
キー名で全ての必要なデータが表現できるため値は利用しない。

```
package main

import(
	"math/rand"
	"net/http"
	"strings"

	"github.com/coreos/go-etcd/etcd"
	"github.com/r7kamura/entoverse"
)

func main() {
	// Set-up a connection to an etcd server.
	upstreams := []string{"http://127.0.0.1:4001"}
	client := etcd.NewClient(upstreams)

	// Loads all hosts data from etcd.
	hosts := make(map[string][]string)
	response, _ := client.Get("/hosts", false, true)
	for _, hostNode := range response.Node.Nodes {
		host := strings.Split(hostNode.Key, "/")[2]
		hosts[host] = []string{}
		for _, upstreamNode := range hostNode.Nodes {
			upstream := strings.Split(upstreamNode.Key, "/")[3]
			hosts[host] = append(hosts[host], upstream)
		}
	}

	// Returns one of registered upstream hosts randomly
	hostConverter := func(originalHost string) string {
		upstreams := hosts[originalHost]
		if len(upstreams) == 0 {
			return ""
		}
		return upstreams[rand.Intn(len(upstreams))]
	}

	// Runs a reverse-proxy server on http://localhost:3000/
	proxy := entoverse.NewProxy(hostConverter)
	http.ListenAndServe("localhost:3000", proxy)
}
```

試しに /hosts/blog.example.com/127.0.0.1:4000 に適当な値 (何でも良い) を入れておくと、
curl :3000 -H "Host: blog.example.com" にアクセスしたときに:4000にリクエストを委譲するようになる。

## 複数ホストで動くリバースプロキシへ
起動時にのみetcdから値を読み取っているが、
etcdの変更を監視するためのGoroutineを別途立てておけば動的にルーティングが切り替えれるようになる。
また複数のetcdでクラスタを構成することで、リバースプロキシも複数ホストで動作させられるようになるだろう。
