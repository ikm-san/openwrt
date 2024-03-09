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
mkdir -p /usr/lib/lua/luci/controller/
mkdir -p /usr/lib/lua/luci/model/cbi/ca_setup/
wget -O /usr/lib/lua/luci/controller/ca_setup.lua https://raw.githubusercontent.com/ikm-san/openwrt/main/ca_setup.lua
wget -O /usr/lib/lua/luci/model/cbi/ca_setup/ipoe.lua https://raw.githubusercontent.com/ikm-san/openwrt/main/ipoe.lua
wget -O /usr/lib/lua/luci/model/cbi/ca_setup/wireless.lua https://raw.githubusercontent.com/ikm-san/openwrt/main/wireless.lua
wget -O /usr/lib/lua/luci/model/cbi/ca_setup/update.lua https://raw.githubusercontent.com/ikm-san/openwrt/main/update.lua
wget -O /usr/lib/lua/luci/model/cbi/ca_setup/sandbox.lua https://raw.githubusercontent.com/ikm-san/openwrt/main/sandbox.lua
wget -O /etc/config/ca_setup https://raw.githubusercontent.com/ikm-san/openwrt/main/ca_setup
rm -rf /tmp/luci-*
/etc/init.d/uhttpd restart

reboot

chmod 755 /usr/lib/lua/luci/controller/ca_setup.lua
chmod -R 755 /usr/lib/lua/luci/model/cbi/ca_setup/
