---
title: Asciinema
---

## Asciinema
[Asciinema](http://asciinema.org/)というのは、端末上の操作を録画するツールとそのホスティングサービス。
「Record and share your terminal sessions, the right way」とのこと。
ざっくり言うとTerminal版[Gifzo](http://gifzo.net/)みたいなもので、こういう感じで利用できる。

```
# install
sudo easy_install pip
sudo pip install asciinema

# usage - 新しいsessionが立ち上がり、exitするまで記録される
asciinema rec
```

<script type="text/javascript" src="http://asciinema.org/a/6669.js" id="asciicast-6669" data-size="small" async></script>

## 実用途
例えば、Asciinemaは[DockerのTutorial](http://docs.docker.io/en/latest/examples/hello_world/)で使われている。
Dockerは自分にとって新しい概念を導入するものだったので、
入力と出力の様子を見ながら外側から徐々にシステムの動きを把握していくことで、段々と理解が深まっていくのを感じた。
Dockerは実行環境の用意に少し時間が掛かるので、
Ubuntuのdownloadを行っている間に説明を見ていたおかげで最初の理解がとても早かった。

他人にプログラムの動作を伝えるときに便利に使えるので、
例えば、[こういうやりとり](https://twitter.com/r7kamura/status/409584072998932480)
において物事が少し分かりやすく伝達出来ると思う。
新しいCLIツールを作ったときに、簡単な使い方を録画してリンクをREADMEに貼るみたいな感じで使うのも良いかもしれない。
