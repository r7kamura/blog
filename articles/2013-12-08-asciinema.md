---
title: Asciinema
---

Asciinemaの使い方、使われ方、ソフトウェア品質特性における魅力性について。

## 使い方
[Asciinema](http://asciinema.org/)という、端末上の操作を録画するツールとそのホスティングサービスがある。
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

## 使われ方
例えば、Asciinemaは[DockerのTutorial](http://docs.docker.io/en/latest/examples/hello_world/)で使われている(またDockerか)。
Dockerは自分にとって新しい概念を導入するものだったので、
入力と出力の様子を見ながら外側からシステムの動きを把握していくことで、徐々に理解が深められた。
Dockerは実行環境の用意に少し時間が掛かるので、
Ubuntuのdownloadを行っている間に説明を見ていたおかげで最初の理解がとても早かった。

他人にプログラムの動作を伝えるときに便利に使えるので、
例えば、[こういうやりとり](https://twitter.com/r7kamura/status/409584072998932480)
において物事が少し分かりやすく伝達出来ると思う。
新しいCLIツールを作ったときに、簡単な使い方を録画してリンクをREADMEに貼るみたいな感じで使うのも良いかもしれない。

## 魅力性
昼下がりにTVを付けるとたまたま放送大学で品質評価とリーダビリティについての講義が行われていて、
ISO 9126(ソフトウェア品質の評価に関する国際規格)という規格の中で、
ソフトウェアを品質の観点から整理した ソフトウェア品質特性 という定義があり、
ソフトウェア品質特性を大別した6つのカテゴリの中に、使い勝手や使いやすさといった特性を表す使用性という項目があり、
更に使用性を細かく分類した品質副特性の中で 魅力性 という項目が定義されているということが紹介されていた。
Asciinemaを介した情報伝達は実際やってみると意外とかっこ良くて、
Asciinemaに対してちょっと良いなと感じた理由は、その辺の魅力性が使い勝手への評価に加味されたからじゃないかと思う。
