# Linksys Velop WRT Pro 7 専用スクリプト集

Velop WRT Pro 7にて動作検証済みの専用スクリプト集です。ターミナルよりSSH接続し、以下のコマンドを実行するだけで導入できます。

## IPoE自動設定スクリプト
v6プラスやOCNバーチャルコネクトといったIPv4 over IPv6接続を自動設定するVelop WRT専用スクリプトです。導入後はプラグアンドプレイで動作します。  
```
準備中
```
※NTTフレッツ回線でONUに直接ルーターをつないでIPoE接続する場合のみ必要な作業です。ひかり電話ホームゲートウェイが手前にある場合やその他の回線では導入不要です。  
※セットアップ中に「無効なルールを受信しました」等のエラーが出て上手くいかない場合は、ONUとルーターの電源を切って2~3分待ってからオンに戻して再度実行してみてください。  

## 広告ブロック導入スクリプト
ブラウザの広告表示を９割近くブロックします。adblock導入後はスマホ等のすべての接続デバイスで効果を発揮します。  
```
curl -sS -o /tmp/adb_setup.sh https://raw.githubusercontent.com/ikm-san/openwrt/main/adb/adb_setup.sh && sh /tmp/adb_setup.sh -v
```

***

# 関連コマンド集

## Win
```
Clear-Content .ssh\known_hosts -Force
```
## Mac
```
ssh-keygen -R 192.168.10.1
```

## ルーター本体初期化
本体底面のリセットボタンを10秒間長押し、もしくは以下のCLIコマンドを実行。  
```
firstboot && reboot now
```
