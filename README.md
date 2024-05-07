# IPoE IPv4 over IPv6接続設定ソフトウェア
OpenWrt搭載ルーターを日本のNTTフレッツ網のIPoE環境でIPv4 over IPv6接続を実現するソフトウェアです。  
インストールが済むと、Luciの管理画面にCA接続設定というメニューが追加されます。  
NTTフレッツ網を利用していない電力系やケーブルテレビ系列等のプロバイダではDHCP自動で動く場合が多く、IPoEの特別な設定は不要です。  

■ IPoE設定
* v6プラス（動作検証済）
* OCNバーチャルコネクト
* IPv6オプション
* transix
* クロスパス
* v6コネクト

■ その他の設定
* DHCP自動(AUTO)設定  
* PPPoE設定
* アクセスポイント・ブリッジモード設定  

## 事前準備と全体の流れ
OpenWrtは初期値で`192.168.1.1`です。  
このままでは、ほかのルーターと競合する場合が多いです。  
そのため、先にOpenWrtルーターのWANはどこにもつながずに、パソコン等の端末から`192.168.1.1`でLuciの管理画面に入り、  
Interface - LAN を`192.168.10.1`に変更してほかのルーター下に置けるようにすることを推奨します。  
その後、ターミナルから必要なファイルをローディングして、Luciの管理画面で設定するとIPoEで繋がります。

## ターミナルへの入り方
Terminalをまず起動する  
* Winの場合 - Win + X -> A で立ち上がります  
* Macの場合 - CMD + Space -> terminalと入力して立ち上げるのが一番早いかも  

OpenWrtルーターにSSHログインする  
`ssh root@192.168.10.1`と入力してエンター  
SSHログインできたら、#スクリプトへ進みます。  
もし、警告が出てできない場合は、以下のラインを実行して再度トライすれば入れます。  
初回はyes/no/fingerprintあたりの設問が出ます。  

#Win 
```
Clear-Content .ssh\known_hosts -Force  
```
#Mac
```
ssh-keygen -R 192.168.10.1  
```
## スクリプト
以下のコマンドを丸ごとコピペしてterminalに貼り付けてもらえれば順番に実行して数十秒で完了します。  
```
opkg update  
opkg install curl  
opkg remove wpad-basic-mbedtls  
opkg install luci-lua-runtime  
opkg install luci-proto-ipv6  
opkg install luci-compat  
opkg install map  
opkg install ds-lite  
opkg install luasec  
opkg install luasocket  
opkg install lua-openssl  
opkg remove wpad-basic-mbedtls  
opkg install wpad-mesh-openssl  
opkg install luci-proto-batman-adv  
mkdir -p /usr/lib/lua/luci/controller/  
mkdir -p /usr/lib/lua/luci/model/cbi/ca_setup/  
wget -O /etc/config/ca_setup https://raw.githubusercontent.com/ikm-san/openwrt/main/ca_setup  
wget -O /usr/lib/lua/luci/controller/ca_setup.lua https://raw.githubusercontent.com/ikm-san/openwrt/main/ca_setup.lua  
wget -O /usr/lib/lua/calib.lua https://raw.githubusercontent.com/ikm-san/openwrt/main/calib.lua  
wget -O /usr/lib/lua/luci/model/cbi/ca_setup/ipoe.lua https://raw.githubusercontent.com/ikm-san/openwrt/main/ipoe.lua  
wget -O /usr/lib/lua/luci/model/cbi/ca_setup/wireless.lua https://raw.githubusercontent.com/ikm-san/openwrt/main/wireless.lua  
rm -rf /tmp/luci-*  
/etc/init.d/uhttpd restart  
```
念のため再起動したほうが良いかもしれません。  
```
reboot  
```

## CA設定メニュー
ブラウザから192.168.10.1と入力してLuciの管理画面からCA接続設定メニューを選びます。  
IPoE接続については、必ずOpenWrtルーターをONU直下に接続した状態で、適切なものを選んで実行してください。  
Luciの画面を表示した状態で接続環境を変更するとブラウザに残ったキャッシュが誤作動を起こす可能性があるので、  
接続環境を例えばルーター下からONU下に途中で繋ぎ直したりした場合は一旦ブラウザを閉じてから設定を行なってください。  
設定完了後再起動したらIPoEで使えるようになります。  

## 動作検証に使用したハードウェア
以下のモデルにて動作検証を行いました。
* Linksys E8450-JP
* Linksys MX5300-JP (SNAPSHOT)

## Luciからインストールできるopkgファイル形式
ターミナルからSSHでrootログインはちょっと・・・という方向けのLuci管理画面からインストールできる[opkgファイル](https://github.com/ikm-san/openwrt/raw/main/opkg/luci-app-jpoe_1.0_all.ipk)用意しました。  

## Map系接続がよりスムーズに動く更新スクリプト
そのままでも動きますが、ポートセットを有効活用できていないため通称ニチバンベンチ等でひっかかる現象が発生します。  
以下のfakemanhk氏とsite_u氏によってv6プラス仕様にカスタマイズされた下記map.shスクリプトに差し替えると、ニチバンベンチもスムーズにクリアします。
```
wget --no-check-certificate -O /lib/netifd/proto/map.sh https://raw.githubusercontent.com/site-u2023/map-e/main/map.sh.new
```

## おわりに
すべてのVNEでの検証はできておりませんので、動作報告や不具合報告はGitHubかXでご連絡いただけると嬉しいです。  
性能改善につながるスクリプトの改修提案もお待ちしております。  
本ソフトウェアのmapデータは https://ipv4.web.fc2.com/map-e.html より参照した簡易mapデータです。  
その他の情報についても有志のweb情報をもとに組み込みを行っています。実際の仕様とは異なる可能性があります。  

当ソフトウェアの利用に関して、当方はいかなる責任も負いかねますのであらかじめ了承の上お使いください。  

## スペシャルサンクス
https://ipv4.web.fc2.com/map-e.html -- 簡易マップの道を切り開いてくれた偉人  
https://qiita.com/site_u -- 日本のOpenWrtコミュニティに多大な貢献をされている偉人、心の師匠  
https://github.com/fakemanhk/openwrt-jp-ipoe -- map.shを日本の実装環境合わせてカスタマイズしてくれたすばらしき偉人  
https://utakamo.com/article/openwrt/beginner/intro01.html -- うたカモ技術ブログでOpenWrtソフト開発の基礎を学びました、知恵の偉人
