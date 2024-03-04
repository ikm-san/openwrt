#!/bin/bash
#network configファイルのバックアップを取る
cp /etc/config/network /etc/config/network.old

#不足している場合に備え、必要なソフトウェアのインストール
opkg update
opkg install luci-lua-runtime
opkg install luci-app-uhttpd
opkg install luci-proto-ipv6 
opkg install map
opkg install ds-lite 

#CAセットアップメニュー用のファイル、キャッシュのクリア、Luciサービス再起動
wget -O /usr/lib/lua/luci/controller/ca_setup.lua https://raw.githubusercontent.com/ikm-san/openwrt/main/ca_setup.lua
wget -O /usr/lib/lua/luci/model/cbi/ca_setup/ipoe.lua https://raw.githubusercontent.com/ikm-san/openwrt/main/ipoe.lua
wget -O /usr/lib/lua/luci/model/cbi/ca_setup/sandbox.lua https://raw.githubusercontent.com/ikm-san/openwrt/main/sandbox.lua
wget -O /etc/config/ca_setup https://raw.githubusercontent.com/ikm-san/openwrt/main/ca_setup
rm -rf /tmp/luci-*
/etc/init.d/uhttpd restart

?
opkg install lua luci-base
opkg install liblucihttp-lua
