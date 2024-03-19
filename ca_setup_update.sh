#!/bin/bash
#network configファイルのバックアップを取る
cp /etc/config/network /etc/config/network.old

# Interface - LAN を192.168.10.1に変更してほかのルーター下に置けるようにする

#必要なソフトウェアのインストール
#CAセットアップメニュー用のファイル、キャッシュのクリア、再起動

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
