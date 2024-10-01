# IPoE IPv4 over IPv6接続設定スクリプト
OpenWrtでv6プラス、OCNバーチャルコネクトといった日本のNTT IPoE接続(IPv4 over IPv6)を実現するためのスクリプトです。  
インストール後、Luci管理画面にCA接続設定というメニューが追加されるためブラウザから設定可能です。  
NTTフレッツのプロバイダではないau光、eo光、nuro光、そのほか電力系やケーブルテレビ系列等のプロバイダでは手前にホームゲートウェイが設置されているため、OpenWrtルーターはNTT向けのややこしい設定は不要です。DHCP自動のままで動きます。  
※ Linksys Velop WRT Pro 7(QSDK 19.07)専用スクリプトは近日公開します。  

![ipoe_ntt_1](https://github.com/user-attachments/assets/77ee0cf2-4be2-4bfb-9f78-2eb65786b6c8)

  
## 対応するWAN接続設定リスト
■ IPoE設定（NTTフレッツ NGN網）
* v6プラス
* OCNバーチャルコネクト
* IPv6オプション
* transix
* クロスパス
* v6コネクト

■ その他の設定
* DHCP自動(AUTO)設定  
* PPPoE接続
* IPoE/PPPoE同時接続（IPv6はIPoE、IPv4はPPPoEで接続するおすすめの設定です。）
* アクセスポイント・ブリッジモード設定  

## 事前準備と全体の流れ
OpenWrtルーターの初期ＩＰアドレスは`192.168.1.1`です。  
このままでは、NTTひかり電話ホームゲートウェイと競合する場合が多いです。  
そのため、先にOpenWrtルーターのWANはどこにもつながずに、パソコン等の端末から`192.168.1.1`でLuciの管理画面に入り、  
Interface - LAN を`192.168.10.1`に変更してほかのHGWやルーター下に置けるようにすることを推奨します。  
その後、ターミナルから以下の必要なファイルを取得して、Luciの管理画面で設定するとIPoEで繋がります。  
※手前にルーターが無く、競合しない場合はもちろん変更する必要はありません。

## ターミナルへの入り方
Terminalをまず起動する  
* Winの場合 - Win + X -> A で立ち上がります  
* Macの場合 - CMD + Space -> terminalと入力して立ち上げるのが一番早いかも  

OpenWrtルーターにSSHログインする  
`ssh root@192.168.10.1`と入力してエンター  
SSHログインできたら、#スクリプトへ進みます。  
もし、警告が出てログインできない場合は、以下のコマンドを実行して再度トライすれば入れます。  
初回はyes/no/fingerprintあたりの設問が出ます。yesで進んでください。  

#Win 
```
Clear-Content .ssh\known_hosts -Force  
```
#Mac
```
ssh-keygen -R 192.168.10.1  
```
## スクリプト
terminalでルーターにssh接続し、以下のコマンドを丸ごとコピペして貼り付けてもらえれば順番に実行して数十秒で完了します。  
NTTフレッツのIPoE環境では、IPv4通信の設定がまだの状態でもIPv6通信は使えますので、このページをあらかじめ開いておけばIPv6経由でダウンロードも実行可能です。
```
opkg update  
opkg install curl  
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

## スクリプトの導入が済んだら、LuciでCA設定メニューへ進む
ブラウザから192.168.10.1と入力してLuciの管理画面に入り、CA接続設定メニューを選びます。  
IPoE接続については、必ずOpenWrtルーターをONU直下に接続した状態で、適切なものを選んで実行してください。  
Luciの画面を表示した状態で接続環境を変更するとブラウザに残ったキャッシュが誤作動を起こす可能性があるので、  
接続環境を例えばルーター下からONU下に途中で繋ぎ直したりした場合は一旦ブラウザを閉じてから設定を行なってください。  
設定完了後再起動したらIPoEで使えるようになります。  

## 動作検証に使用したハードウェア
以下のモデルにて動作検証をしています。
* Linksys Velop WRT Pro7 (MBE70 / LN6001-JP) ※別途専用スクリプト用意しました
* Linksys WHW03v2
* Linksys E8450-JP
  
## Luciからインストールできるopkgファイル形式
ターミナルではなくLuci管理画面からインストールしたい方向けの[opkgファイル](https://github.com/ikm-san/openwrt/raw/main/opkg/luci-app-jpoe_1.0_all.ipk)。  

## map.sh for nftables / OpenWrt ver 23以降
最新のOpenWrtでは差し替え不要でそのままでもmap-eが動作しますが、パケット詰まりが発生しやすく、通称ニチバンベンチ等でひっかかる現象が発生する場合があります。  
以下のfakemanhk氏とsite_u氏によってv6プラス仕様にカスタマイズされたnftablesを利用する下記map.shスクリプトに差し替えると、ニチバンベンチもスムーズにクリアします。
```
wget --no-check-certificate -O /lib/netifd/proto/map.sh https://raw.githubusercontent.com/site-u2023/map-e/main/map.sh.new
```

## map.sh for Velop WRT Pro 7 / QSDK 19.07
Linksys Velop WRT Pro 7用にカスタマイズしたmap.shです。オートセットアップを利用された方はすでに導入済みです。
```    
wget --no-check-certificate -O /lib/netifd/proto/map.sh https://raw.githubusercontent.com/ikm-san/openwrt/main/map.sh/map.sh1907o　　 
```
map-eはそもそもにポート数を節約して複数エンドユーザーで1つのIPv4アドレスをシェアする側面があります。まさにライドシェア状態。  
利用可能なポート数はv6プラスは240個、OCNバーチャルコネクトは1024個という厳しい制限があります。ds-liteは細かな設定不要ですが1024個提供されているようです。    
v6プラスは240個と本当に割り当てポート数が少ないので、少人数でも全ポートを使い切ってダウン状態が発生する可能性があります。 そのため、法人向けのmap-e固定IPサービスはもっとたくさんのポートが利用可能です。   
PPPoE接続ではそのようなポート制限がないため、IPv6だけIPoEで接続し、IPv4はPPPoEが使える環境ならPPPoEで接続するのがベストかもしれません。  
既存のIPv4サイトもそのうちIPv6へと移行しますので、これが正解な気もします。  

## おわりに
すべてのVNEでの検証はできておりませんので、動作報告や不具合報告はGitHubかXでご連絡いただけると嬉しいです。  
性能改善につながるスクリプトの改修提案もお待ちしております。  
本スクリプトのmapデータは https://ipv4.web.fc2.com/map-e.html より参照した簡易mapデータです。  
その他の情報についても有志のweb情報をもとに組み込みを行っています。実際の仕様とは異なる可能性があります。  

当スクリプトの利用に関して、当方はいかなる責任も負いかねますのであらかじめ了承の上お使いください。  

## スペシャルサンクス
https://ipv4.web.fc2.com/map-e.html -- 簡易マップの道を切り開いてくれた偉人  
https://qiita.com/site_u -- 日本のOpenWrtコミュニティに多大な貢献をされている偉人、心の師匠  
https://github.com/fakemanhk/openwrt-jp-ipoe -- map.shを日本の実装環境に合わせてカスタマイズしてくれたすばらしき偉人  
https://utakamo.com/article/openwrt/beginner/intro01.html -- うたカモ技術ブログでOpenWrtソフト開発の基礎を学びました、知恵の偉人  
  
ほかにも、map-e通信を実現するにあたり、様々な方のブログ記事を参考に改善を重ねていきました。  
これらの情報なしでは実現し得ることがなかったのが事実です。本当に感謝しています。  
日本のOpenWrtコミュニティの発展に今後も貢献できれば幸いです。
