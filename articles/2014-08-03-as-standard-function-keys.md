---
title: As standard function keys
---

![](http://cdn-ak.f.st-hatena.com/images/fotolife/r/r7kamura/20140803/20140803033436.png)

Macの環境構築を自動化するコードを書いている途中で、ファンクションキーの設定に関する情報を得た。

## tl;dr
OSXのファンクションキーの設定をプログラムから変更するには、defaults(1)を利用すれば良い。
defaultsを利用する方法では再ログインするまで変更が反映されないが、
defaultsの代わりにSQLite3とAppleScriptを利用する方法を取れば即時反映される。

## defaults
以下はdefaultsを利用してファンクションキーの設定を変更する例。

```
defaults write -g com.apple.keyboard.fnState -bool true
```

## AppleScirpt
ファンクションキーの設定を反映させる方法は二通りしか判明していない。
再ログインするか、もしくはGUI経由で設定を変更するかのどちらかだ。
AppleScriptを使った場合はGUI経由での設定変更と同等に扱われるため、設定が即時反映される。

AppleScriptからシステム環境設定にアクセスする場合、
これを実行するアプリケーションがアクセシビリティの項目で許可されている必要がある。
/Library/Application Support/com.apple.TCC/TCC.db
のSQLite3のDBに対して変更を加えればこれをプログラムから許可できる。
accessという名前のテーブルに許可対象のアプリケーションを表すレコードが格納される形式になっている。
なお、アプリケーションごとのアクセシビリティ管理機構が導入されたのはMarvericksからだ。

以下のコードでは、SQLite3のインターフェース経由でアクセシビリティに変更を加えたあと、
AppleScriptを利用してファンクションキーの設定を変更する。

```
sudo sqlite3 /Library/Application\ Support/com.apple.TCC/TCC.db \
  "INSERT OR REPLACE INTO access VALUES('kTCCServiceAccessibility','com.googlecode.iterm2',0,1,0,NULL);"

osascript <<< '
tell application "System Preferences"
    reveal anchor "keyboardTab" of pane "com.apple.preference.keyboard"
end tell
tell application "System Events" to tell process "System Preferences"
    set functionStateCheckbox to checkbox 1 of tab group 1 of window 1
    tell functionStateCheckbox
        if not (its value as boolean) then click functionStateCheckbox
    end tell
end tell
quit application "System Preferences"
'
```
