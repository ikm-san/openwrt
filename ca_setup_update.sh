#!/bin/bash

wget -O /usr/lib/lua/luci/controller/ca_setup.lua https://raw.githubusercontent.com/ikm-san/openwrt/main/ca_setup.lua
wget -O /usr/lib/lua/luci/model/cbi/ca_setup/ipoe.lua https://raw.githubusercontent.com/ikm-san/openwrt/main/ipoe.lua
chmod +x /usr/lib/lua/luci/controller/ca_setup.lua
chmod +x /usr/lib/lua/luci/model/cbi/ca_setup/*.lua

rm -rf /tmp/luci-*
/etc/init.d/uhttpd restart
