---
title: Hello world
date: 2013-11-10
tags: diary
---

技術関係の小ネタを書くために新しくブログを作った。

## ブログどれ使うか問題
[tumblr](http://tumblr.com)、
[medium](https://medium.com/)、
[hatenablog](http://hatenablog.com)、
[scriptogr.am](http://scriptogr.am) などを検討した後、
今回は[Middleman](http://middlemanapp.com/)とGitHub Pagesを利用することにした。
tumblrは、手軽に使えて、無料で広告が出ず、HTMLテンプレートは全て自分で編集できるが、記事編集画面が少し使いづらい。
mediumはオシャレだけど、表参道みたいな息苦しさがある。
はてなブログは、はてなスターや通知、編集画面が便利で最高だけど、
無料だと広告が出るし、HTMLテンプレート全体を自由に編集できない。
scriptogr.amはDropboxに記事を置くと公開されるという仕組みが面白いけれど、まだBeta版品質という感じがする。

## Middlemanについて
MiddlemanはWebサイトに必要な静的ファイルを生成するためのツールで、
SassやMarkdown等のテンプレートを元に、HTMLやCSS、Javascriptといったファイルを生成してくれる。
Middlemanは初期設定と学習に少し手間が掛かるけど、数時間程度だし、結局自分が好きなように設定出来るのが良い。
データが全て手元にあるということに安心感がある。静的ファイルを返すだけなので応答速度は速い。
手元で確認するためのWebサーバが同梱されていて、Live-Relaod機能も付いているので非常に便利。
Previewボタンをポチポチ押して確認しなくて良い。
使う前に想像していたほど大きなシステムでは無かった。
Webアプリでも部分的に静的ファイルに置き換えられる箇所は多いので、そういう場面で簡単に適用出来ると良いかもしれない。

## 公開作業の単純化
![](/images/2013-11-10-hello-world/build-pipeline.png)
ブログは書きたいときにすぐ書けるようにしておかないと途端に腐るので、
GitHubとTravisCIとDropboxを使って、エディタで記事を書いてフォルダに入れるだけで公開されるようにした。
GitHubでは、username.github.ioレポジトリのmasterブランチにファイルを置くと、
http://username.github.io からファイルを配信してくれる。
Markdownで書いた記事をMiddlemanでHTMLに変換し、これをmasterブランチにpushする。
Middlemanにはブログを作るための拡張機能があるので、これを使えば簡単に雛形を生成できる。
静的ファイルの生成を自分で行うのは面倒なので、これはTravis-CIに任せる。
GitHubのPersonal Access Tokenを利用すれば、Travis-CIからGitHubにpushできる。
不具合があってbuildにfailするとTravisがメールを投げてくれるので、所謂一般的なCIの役割も兼ねていて便利。
記事編集のたびにGitHubにPushするのも面倒なので、レポジトリをDropbox内に置き、
VPSで動かしているプログラムにDropboxを監視させ、代わりにGitHubにPushさせている。
この辺VPSとか使わずにもう少し便利な仕組みがあると良いと思う。
このブログのソースコードは[ここ](https://github.com/r7kamura/r7kamura.github.io/)に置いてある。
