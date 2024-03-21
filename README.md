# CA接続設定ソフトウェア
OpenWrt搭載ルーターを日本のIPoE環境で接続できるようにする簡易map機能を提供するソフトです。  
インストールが済むと、Luciの管理画面にCA接続設定というメニューが追加されます。  
簡易mapデータは https://ipv4.web.fc2.com/map-e.html より参照しました。  

■IPoE設定
* v6プラス（動作検証済）
* OCNバーチャルコネクト
* IPv6オプション
* transix
* クロスパス
* v6コネクト

■その他の設定
* DHCP自動設定
* PPPoE設定
* アクセスポイント・ブリッジモード設定 ※dumb AP化しますので、元に戻したい場合はハードウェアリセットで初期化してください。

# 事前準備
OpenWrtは初期値で192.168.1.1を利用しようとしてほかのルーターと競合する場合が多いので、  
先にOpenWrtルーターのWANはどこにもつながずに、パソコン等の端末から192.168.1.1でLuciの管理画面に入り、  
Interface - LAN を192.168.10.1に変更してほかのルーター下に置けるようにする。  

# ターミナルへのの入り方
Terminalをまず起動する  
Winの場合 - Win + X -> A で立ち上がります  
Macの場合 - CMD + Space -> terminalと入力して立ち上げるのが一番早いかも  

OpenWrtルーターにSSHログインする  
ssh root@192.168.10.1と入力してエンター  
SSHログインできたら、#スクリプトへ進みます。  
もし、警告が出てできない場合は、以下のラインを実行して再度トライすれば入れます。  
初回はyes/no/fingerprintあたりの設問が出ます。  

#Win  
Clear-Content .ssh\known_hosts -Force  

#Mac  
ssh-keygen -R 192.168.10.1  


# スクリプト
以下のコマンドを丸ごとコピペしてterminalに貼り付けてもらえれば順番に実行して数十秒で完了します。  

opkg update  
opkg install luci-lua-runtime  
opkg install luci-proto-ipv6  
opkg install luci-compat  
opkg install map  
opkg install ds-lite  
opkg install luasec  
opkg install ip6tables  
opkg install lua-openssl  
opkg install wpad-mesh-openssl  
mkdir -p /usr/lib/lua/luci/controller/  
mkdir -p /usr/lib/lua/luci/model/cbi/ca_setup/  
wget -O /etc/config/ca_setup https://raw.githubusercontent.com/ikm-san/openwrt/main/ca_setup  
wget -O /usr/lib/lua/luci/controller/ca_setup.lua https://raw.githubusercontent.com/ikm-san/openwrt/main/ca_setup.lua  
wget -O /usr/lib/lua/calib.lua https://raw.githubusercontent.com/ikm-san/openwrt/main/calib.lua  
wget -O /usr/lib/lua/luci/model/cbi/ca_setup/ipoe.lua https://raw.githubusercontent.com/ikm-san/openwrt/main/ipoe.lua  
wget -O /usr/lib/lua/luci/model/cbi/ca_setup/wireless.lua https://raw.githubusercontent.com/ikm-san/openwrt/main/wireless.lua  
wget -O /usr/lib/lua/luci/model/cbi/ca_setup/update.lua https://raw.githubusercontent.com/ikm-san/openwrt/main/update.lua  
rm -rf /tmp/luci-*  
/etc/init.d/uhttpd restart  

# おわりに
再起動したほうが良いです。  
reboot  
当ソフトウェアの利用に関して、当方はいかなる責任も負いかねますのであらかじめ了承の上お使いください。  

