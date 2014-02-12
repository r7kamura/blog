---
title: Includable YAML
---

YAMLの定義内で別のファイルに書いたYAMLを参照出来るようにしてみた。

## YAMLに加える変更
YAMLの各要素には任意のタグを埋め込むことができ、またその振る舞いを定義出来る。

```ruby
# test.rb
require "yaml"

YAML.add_domain_type(nil, "include") do |type, val|
  YAML.load_file(val)
end

# 折角なので再度YAMLに加工して出力してみる
puts YAML.load_file("api.yml").to_yaml
```

## Includeする側
例えば、レシピデータを返すREST APIの仕様をYAMLで定義するというユースケースを考える。
レシピのスキーマをrecipe.ymlに書いて、各APIから定義を使い回すことにする。

```
# api.yml
/recipes:
  GET:
    response:
      array: !include recipe.yml

/recipe/{id}:
  GET:
    response: !include recipe.yml
```

## Includeされる側
これがレシピのスキーマ定義。

```
# recipe.yml
id:
  type: integer
  minValue: 1
  description: Unique ID of the Recipe
name:
  type: string
  description: The human-readable name of the Recipe
```

## 実行例
こんな感じで出力されてrecipe.ymlがうまく埋め込まれてることが分かる。

```
$ ruby test.rb
---
/recipes:
  GET:
    response:
      array:
        id:
          type: integer
          minValue: 1
          description: Unique ID of the Recipe
        name:
          type: string
          description: The human-readable name of the Recipe
/recipe:
  GET:
    response:
      id:
        type: integer
        minValue: 1
        description: Unique ID of the Recipe
      name:
        type: string
        description: The human-readable name of the Recipe
```
