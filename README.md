OpenWrt搭載ルーターを日本のIPoE環境で接続できるようにする簡易map機能を提供するソフトです。
簡易mapデータは https://ipv4.web.fc2.com/map-e.html より参照しました。

■IPoE設定
v6プラス（動作検証済）
OCNバーチャルコネクト
IPv6オプション
transix
クロスパス
v6コネクト

■その他の設定
DHCP自動設定
PPPoE設定
アクセスポイント・ブリッジモード設定 ※dumb AP化しますので、元に戻したい場合はハードウェアリセットで初期化してください。

当ソフトウェアの利用に関して、当方はいかなる責任も負いかねますのであらかじめ了承の上お使いください。


事前準備
OpenWrtは初期値で192.168.1.1を利用しようとしてほかのルーターと競合する場合が多いので、
先にOpenWrtルーターのWANはどこにもつながずに、パソコン等の端末から192.168.1.1でLuciの管理画面に入り、
Interface - LAN を192.168.10.1に変更してほかのルーター下に置けるようにする。

ターミナルへのの入り方
Winの場合 - Win + X -> A で立ち上がります
Macの場合


#Win
Clear-Content .ssh\known_hosts -Force

#Mac
ssh-keygen -R 192.168.10.1


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
wget -O /usr/lib/lua/luci/model/cbi/ca_setup/sandbox.lua https://raw.githubusercontent.com/ikm-san/openwrt/main/sandbox.lua
wget -O /usr/lib/lua/luci/model/cbi/ca_setup/mapv6.lua https://raw.githubusercontent.com/ikm-san/openwrt/main/mapv6.lua
rm -rf /tmp/luci-*
/etc/init.d/uhttpd restart

reboot

chmod +x /usr/lib/lua/luci/model/cbi/ca_setup/mapv6.lua


chmod 755 /usr/lib/lua/luci/controller/ca_setup.lua
chmod -R 755 /usr/lib/lua/luci/model/cbi/ca_setup/

# ICMPv6フィルタリング設定
ip6tables -A INPUT -p icmpv6 --icmpv6-type echo-request -j ACCEPT
ip6tables -A INPUT -p icmpv6 --icmpv6-type router-advertisement -j ACCEPT
ip6tables -A INPUT -p icmpv6 --icmpv6-type neighbour-solicitation -j ACCEPT
ip6tables -A INPUT -p icmpv6 --icmpv6-type neighbour-advertisement -j ACCEPT
ip6tables -A INPUT -p icmpv6 -j DROP

# すべてのインターフェースに対してプライバシーエクステンションを有効にする
sysctl -w net.ipv6.conf.all.use_tempaddr=2
sysctl -w net.ipv6.conf.default.use_tempaddr=2
