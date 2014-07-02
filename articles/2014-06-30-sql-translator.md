---
title: SQL Translator
---

[SQL::Translator](https://github.com/dbsrgits/sql-translator) という、
SQLの構文解析器 + これを利用した便利なツール群を読んだ。

## SQL::Translatorの使い方
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
  target_schema => $target_schema,
  output_db => $database_type,
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

## MySQL Adapter
サンプルコードでは"MySQL"という文字列をSQL::Translator#parserに渡したが、
この情報により、SQL::Translator::Parser::MySQLがParserとして、
SQL::Translator::Producer::MySQLがProducerとして利用されることになる。
名前から察せられる通り、Parserは入力された定義を解析するためのクラス、
Producerは解析結果を出力するためのクラスである。
MySQLの他にも、Oracle、SQLite、Excel、JSONなど多くの構文用のファイルが存在している。

## デバッグ用の情報を表示する
SQL::Translator#debuggingに1を与えてデバッグしてほしい旨を伝えておくと、
デバッグ用の情報が標準出力に流れてくるようになる。
SQL::Translatorが内部でどういうデータ構造を扱っているのか、
どういう処理が順に行われているのかの一片を窺い知ることができる。
例えばサンプルスクリプトでこれを有効化してみると、次のような出力が得られる。  
https://gist.github.com/r7kamura/6b965acaba0ec0165f46

## Parse::RecDescent
[Parse::RecDescent](http://perldoc.jp/docs/modules/Parse-RecDescent-1.94/RecDescent.pod)
という再帰下降パーサを生成するためのライブラリがSQL::Translatorの内部で利用されている。
BNF風の構文で文法を定義でき、各所でPerlのコードを実行できるようになっている。
試しに、正の整数の足し算を行う単純な文法を定義してみた。

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
my $text= "1+2";
my $result = $parser->expression($text);

# Print out the result as "1+2=3"
print "$text=$result\n";
```

```
$ cpanm Parse::RecDescent
$ ./parse.pl
1+2=3
```

## MySQL用の文法
SQL::Translatorでは、例えばMySQL用の文法が
[このように](https://github.com/dbsrgits/sql-translator/blob/master/lib/SQL/Translator/Parser/MySQL.pm#L152-L892)
定義されている。
一部分だけ取り上げて見ることにする。
先頭の中括弧内に囲われた部分では、構文解析中のどの部分からもグローバルに扱える変数を用意している。
startruleの定義では、startruleがstatement(s)とeoffileの二つの部分からなることが定義されている。
ここがMySQLの構文の唯一の開始地点であり、$parser->startrule($text) のような呼出により、
database_name、tables、views、proceduresという4つのプロパティを持ったHashが得られることが分かる。

```
{
    my (
      $database_name,
      $proc_order,
      $table_order,
      $view_order,
      %procedures,
      %tables,
      %views,
      @table_comments,
    );
    my $delimiter = ';';
}
startrule : statement(s) eofile {
  {
    database_name => $database_name,
    tables        => \%tables,
    views         => \%views,
    procedures    => \%procedures,
  }
}
```

[Gistに載せたさっきのデバッグ用の出力](https://gist.github.com/r7kamura/6b965acaba0ec0165f46)
を見れば、この構文解析結果が出力されていることが確認できる。
例えばbefore.sqlの解析結果では、
idカラムとnameカラムを持ったusersというテーブルが1つ定義されており、
database_name、views、proceduresは空である、という解析結果が得られている。

## SQL::Translator::Diff#compute_differences
SQL::Translator::Diffは2つのSchemaを見比べ、変更後のスキーマに存在する各テーブルについて以下の情報を収集する
(変更前のスキーマにしか存在しないテーブルについては、テーブル名変更が行われた場合を除いては消してしまえば良い)。
ちなみに、これらの情報は内部では単純なHashとArrayで表現されている。

* constraints_to_create
* constraints_to_drop
* fields_to_alter
* fields_to_create
* fields_to_drop
* fields_to_rename
* indexes_to_create
* indexes_to_drop
* table_options
* table_renamed_from
* tables_to_create
* tables_to_drop

## SQL::Translator::Diff#produce_diff_sql
compute_differencesで収集した差分データを元に、そのSQL表現を生成する。
勿論出力すべきフォーマットは言語ごとに異なるので、ここでユーザの指定した種類のProducerを利用することになる。
今回のサンプルではMySQLを指定しているので、SQL::Translator::Producer::MySQLが利用される。

さて、SQL::Translator::Diffには以下のようなMapping用のHashが定義されており、
これは「compute_differencesで収集したこの差分に対してはProducerのこの名前のメソッドを利用する」
という情報を表現している。

```
{
  constraints_to_create => "alter_create_constraint",
  constraints_to_drop   => "alter_drop_constraint",
  fields_to_alter       => "alter_field",
  fields_to_create      => "add_field",
  fields_to_drop        => "drop_field",
  fields_to_rename      => "rename_field",
  indexes_to_create     => "alter_create_index",
  indexes_to_drop       => "alter_drop_index",
  table_options         => "alter_table",
  table_renamed_from    => "rename_table",
}
```

例えば、table_renamed_fromという差分データに対してはrename_tableメソッドでSQLを生成することになる。
table_renamed_fromの実装はこういう感じになる (理解しやすくするために少し加筆修正した)。
これにより、AからBへのテーブル名変更という差分情報から
"ALTER TABLE A RENAME TO B"というSQL表現での文字列が得られている。

```
sub rename_table {
  my ($old_table, $new_table, $options) = @_;
  return "ALTER TABLE $old_table_name RENAME TO $new_table_name";
}
```

差分からSQLを生成するこの一連の処理は、
恐らく慎重に設計されたであろう順序に従って粛々と進められ、
結果として差分データのSQL表現を集めた配列が出来上がる。
最後に仕上げとしてこの配列の前後にトランザクション用の処理を加え、
改行とセミコロンで連結すれば、おめでとう、2つのスキーマの差分を表現したSQLの完成である。

## まとめ
1. SQL::Translator::Translator にスキーマが渡される
1. SQL::Translator::Parser が Parse::RecRescent を利用してスキーマを解析する
1. SQL::Translator::Schema の形で解析したデータが表現される
1. SQL::Translator::Diff が2つのスキーマを比較し差分データを収集する
1. SQL::Translator::Producer により差分データが変換され、以下のようなSQLが生成される

```
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
