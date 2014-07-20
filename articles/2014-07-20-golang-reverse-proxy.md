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

	hosts := []string{
		":9292",
		":9293",
	}
	hostRing := ring.New(len(hosts))
	for _, host := range hosts {
		url, _ := url.Parse("http://127.0.0.1" + host)
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
