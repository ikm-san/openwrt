#!/bin/bash

# Create directories for Luci components
mkdir -p /usr/lib/lua/luci/controller/
mkdir -p /usr/lib/lua/luci/model/cbi/ca_setup/

# Download configuration files and scripts
curl -o /etc/config/ca_setup "https://raw.githubusercontent.com/ikm-san/openwrt/main/ca_setup"
curl -o /usr/lib/lua/luci/controller/ca_setup.lua "https://raw.githubusercontent.com/ikm-san/openwrt/main/ca_setup.lua"
curl -o /usr/lib/lua/calib.lua "https://raw.githubusercontent.com/ikm-san/openwrt/main/calib.lua"
curl -o /usr/lib/lua/luci/model/cbi/ca_setup/ipoe.lua "https://raw.githubusercontent.com/ikm-san/openwrt/main/ipoe.lua"
curl -o /usr/lib/lua/luci/model/cbi/ca_setup/wireless.lua "https://raw.githubusercontent.com/ikm-san/openwrt/main/wireless.lua"

# Clear Luci cache
rm -rf /tmp/luci-*

# Restart uHTTPd server
/etc/init.d/uhttpd restart

