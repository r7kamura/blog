---
title: SQL Translator
---

[SQL::Translator](https://github.com/dbsrgits/sql-translator) という、
SQLの構文解析器 + これを利用した便利なツール群を読んだ。

## なぜSQL::Translatorを読んだのか
winebarrel氏が、
[Ridgepole](https://github.com/winebarrel/ridgepole)
というActiveRecord用のスキーマ管理ツールをつくっていたのを見た。
ActiveRecordのDSLで記述したスキーマ定義を更新すると、自動で差分を生成してくれるというもの。
これは便利そうだけれど、ActiveRecordを利用しているというところが気になっていたので、
ActiveRecordのDSLの代わりにSQLを利用してこれを実現する方法を探すことにした。

## SQL::Translatorの使い方とサンプル
とりあえずSQL Translatorの使い方を知らないことにはどうにもならないので、
使い方を調べて小さな動くコードを書くことに。
まず手元にbefore.sqlとafter.sqlという2つのSQLのファイルを用意した。
before.sqlでusersテーブルを作成し、更にafter.sqlでitemsテーブルを作成している。

```
$ cat before.sql
CREATE TABLE `users` (
  `id` integer(10) unsigned NOT NULL AUTO_INCREMENT,
  `name` char(16) NOT NULL,
  PRIMARY KEY (`id`)
);

$ cat after.sql
CREATE TABLE `users` (
  `id` integer(10) unsigned NOT NULL AUTO_INCREMENT,
  `name` char(16) NOT NULL,
  PRIMARY KEY (`id`)
);

CREATE TABLE `items` (
  `id` integer(10) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` integer(10) unsigned NOT NULL,
  `name` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `user_id` (`user_id`)
);
```

これをtranslate.plに入力して標準出力に差分を表示させる。具体的には以下の三つの工程を踏む。

1. before.sqlとafter.sqlをSQL::Translator::Schemaオブジェクトに変換する
1. 2つのSchemaからSQL::Translator::Diffオブジェクトをつくる
1. SQL::Translator::Diffに差分となるSQLを文字列で出力してもらう

```
#!/usr/bin/env perl
use strict;
use warnings;

use SQL::Translator;
use SQL::Translator::Diff;

sub convert_filename_into_schema {
  my ($filename, $database_type) = @_;
  my $translator = SQL::Translator->new;
  $translator->parser($database_type) or die $translator->error;
  $translator->translate($filename) or die $translator->error;
  my $schema = $translator->schema;
  $schema->name($filename);
  $schema;
}

my $database_type = "MySQL";
my $source_schema = convert_filename_into_schema($ARGV[0], $database_type);
my $target_schema = convert_filename_into_schema($ARGV[1], $database_type);
my $diff = SQL::Translator::Diff->new(
  source_schema => $source_schema,
  source_db => $database_type,
  target_schema => $target_schema,
  target_db => $database_type,
  producer_args => {
    quote_field_names => 1,
  },
);
$diff->compute_differences;
print $diff->produce_diff_sql;
```

実行方法は以下の通り。

1. cpanm (=Perlにおけるパッケージマネージャ) が入っていなければインストールする
1. SQL::Translator を手元のPerlの環境にインストールする
1. 上記のコードを実行する

```
$ curl -L http://cpanmin.us | perl - App::cpanminus
$ cpanm SQL::Translator
$ ./translate.pl before.sql after.sql
-- Convert schema 'before.sql' to 'after.sql':;

BEGIN;

SET foreign_key_checks=0;

CREATE TABLE `items` (
  `id` integer(10) unsigned NOT NULL auto_increment,
  `user_id` integer(10) unsigned NOT NULL,
  `name` varchar(255) NULL DEFAULT NULL,
  INDEX `user_id` (`user_id`),
  PRIMARY KEY (`id`)
);

SET foreign_key_checks=1;


COMMIT;
```

BEGIN ... COMMIT により変更がトランザクションに囲まれていることがわかる。
またforeign_key_checksを変更することで、外部キー制約を一時的に無視している。
外部キー制約が存在するとテーブルの削除と追加の順序で面倒なことになりがちなので、
dumpされたデータを読み込む場合などにはこの手法が取られることが多い。
CREATE TABLEの部分を見ると、after.sqlで追加されたitemsテーブルの定義がきちんと反映されていることが分かる。
今回は原文との差異も無かったが、
方言やALIASなど (integerに対するintなど) を利用しているとここで少し差異が出ることになるだろう。

## "MySQL"という文字列は何のために使われるのか
サンプルコードでは"MySQL"という文字列をSQL::Translator#parserに渡したが、
この情報により、SQL::Translator::Parser::MySQLがParserとして、
SQL::Translator::Producer::MySQLがProducerとして利用されることになる。

## デバッグ用の情報を表示する
SQL::Translator#debuggingに1を与えてデバッグしてほしい旨を伝えておくと、
デバッグ用の情報が標準出力に流れてくるようになる。
SQL::Translatorが内部でどういうデータ構造を扱っているのか、
どういう処理が順に行われているのかの一片を窺い知ることができる。
例えばサンプルスクリプトでこれを有効化してみると、次のような出力が得られる。  
https://gist.github.com/r7kamura/6b965acaba0ec0165f46

## Parse::RecRescent
[Parse::RecRescent](http://perldoc.jp/docs/modules/Parse-RecDescent-1.94/RecDescent.pod)
という再帰下降パーサを生成するためのライブラリがSQL::Translatorの内部で利用されている。
BNF風の構文で定義することができるようになっていて、試しに単純な足し算を行う文法を定義してみた。

```
#!/usr/bin/env perl
use strict;
use warnings;
use Parse::RecDescent;

my $grammar = <<'GRAMMAR';
expression : atom "+" expression
    { $return = $item[1] + $item[3]; }
expression : atom
    { $return = $item[1]; }
atom : /\d+/
    { $return = $item[1]; }
GRAMMAR

# Load $grammar as a grammar definition string
my $parser = Parse::RecDescent->new($grammar);

# Then parse $text into a primitive Perl object
my $text= "5+6";
my $result = $parser->expression($text);

# Print out the result as "5+6=11"
print "$text=$result";
```
