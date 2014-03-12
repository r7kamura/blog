---
title: Database Encryption
---

データベースの暗号化界隈の話を調べたのでQ&A形式でまとめた。

## なぜ暗号化を行うのか？
一般的には、以下の様な情報の漏洩を防ぐため。

* 個人が識別できる情報
* 個人の行動履歴
* 財務情報
* 知的財産
* 財産
* その他開示されていない情報

## 最近日本で大きな情報漏洩被害にあった企業例は？
* Sony (PlayStation Network)
* Yahoo! Japan
* LINE
* 2ch
* @PAGES

## データベースの暗号化におけるベストプラクティスは？
StackOverflow等の意見を集めた限り、この辺を全部やるというのがベストプラクティスという雰囲気。

* 通信データの暗号化: SSL
* 格納データの暗号化: FDE + TDE (後述)

## 格納データの暗号化機能を提供しているサービスの例は？
* Amazon RDS for Oracle
* Amazon RDS for SQL Server
* Amazon S3
* Google Cloud Storage
* Oracle Database Storage Service

## 格納データの暗号化手法の例は？
* FDE = Full Disk Encryption
* TDE = Transparent Data Encryption
* アプリケーション側での暗号化

## FDEとは？
データを格納するストレージ全体を暗号化する手法。
自己暗号化ドライブを利用してハードウェア全体を暗号化する方法や、
[TrueCrypt](http://ja.wikipedia.org/wiki/TrueCrypt)を利用して暗号化した仮想ディスクを作成する等の方法がある。

## TDEとは？
データベース内の特定の空間に格納されるデータを透過的に暗号化する手法。
例えばRDBMSでは、指定したテーブル内の全てのデータ、ログ、インデックスが暗号化される。
仮にディスクやファイルが盗まれた場合でも情報漏洩の可能性は低い。

## FDEと比べたTDEの利点は？

OSへの侵入に対する耐性。  
攻撃者がOSへのログインに成功した場合、FDEでは攻撃者は(OSのアクセス制御を受けながら)復号されたデータを読み込める。
一方、TDEではファイルの内容は暗号化されたままの為、攻撃者はデータの内容を解読出来ない。

バックアップ。  
FDEでは、復号されたファイルをコピーするため、コピーされたデータは平文で保存される。
一方、TDEでは暗号化されたファイルをコピーするため、コピーされたデータも暗号化された状態で保存される。

暗号化の処理効率。  
FDEではディスク上の全てのファイルを暗号化する一方、
TDEでは指定されたテーブルやそのインデックスのみ暗号化すれば良く、無駄が少ない。

## アプリケーション側での暗号化と比べたTDEの利点は？
TDEでは、アプリケーション側で暗号化について意識する必要がなく、既存の実装を全く変更する必要がない。
また、アプリケーション側で暗号化に利用するキーの管理を行う必要がない。
DBのキャッシュを利用できる場合においては、SQL文実行のたびにデータを暗号したりする必要が無く、実行効率が良い。
アプリケーション側で暗号化を行った場合、暗号化したデータに対してはインデックスを利用出来ないが、
TDEではこのような制限は無い。そのため、暗号化したデータに対しても現実的に検索処理を行える。

## AES-NIとは？
Intel Xeonプロセッサの5600番台以降に搭載されたx86命令セットへの拡張機能で、
これを搭載したCPU(Ivy BridgeやHaswellなど)でのAES暗号化/復号処理が数倍程度のスループットに向上した事例が確認されている。
TDE等AES暗号化を利用する場合、AES-NIの機能を利用出来るCPUを利用することが望ましい。

## TDEを利用出来るRDBMSは？
代表的なのはOracleとSQL Server、その他参考までに製品レベルのものだとPostgreSQL 9.1ベースのPowerGres Plus等が挙げられる。

* [Oracle](http://docs.oracle.com/cd/E16338_01/network.112/b56286/asotrans.htm)
* [SQL Server](http://msdn.microsoft.com/ja-jp/library/bb934049.aspx)
* [PowerGres Plus](http://powergres.sraoss.co.jp/manual/Plus/V91/linux/tde.html)

## RDSで利用出来るものは？
OracleとSQL ServerはRDSで利用できる。但しライセンスの持ち込みが必要な場合がある。

* [Appendix: Options for Oracle DB Engine - Amazon Relational Database Service](http://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Appendix.Oracle.Options.html#Appendix.Oracle.Options.AdvSecurity)
* [Microsoft SQL Server on Amazon RDS - Amazon Relational Database Service](http://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_SQLServer.html#SQLServer.Concepts.General.Options)
* [Amazon RDS 料金表 | アマゾン ウェブ サービス（AWS 日本語）](http://aws.amazon.com/jp/rds/pricing/)


