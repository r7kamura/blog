---
title: Transcode
---

[CircleCIの14,000行のテストコードのフレームワークが、1日で置き換えられた話](http://blog.circleci.com/rewriting-your-test-suite-in-clojure-in-24-hours/)

## まとめ
* Clojureには、Clojureで書かれたソースコードを読み込みデータ構造として解釈する機能がある
* ソースコードを「変換」することで、Midjeからclojure.testへとテストフレームワークを乗り換えた
* 94%のテストは自動で変換できたが、インデントと、残りのテストには手作業による修正が必要だった
