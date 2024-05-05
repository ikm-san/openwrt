#!/bin/bash

# Remove downloaded files
rm -f /etc/config/ca_setup
rm -f /usr/lib/lua/luci/controller/ca_setup.lua
rm -f /usr/lib/lua/calib.lua
rm -f /usr/lib/lua/luci/model/cbi/ca_setup/ipoe.lua
rm -f /usr/lib/lua/luci/model/cbi/ca_setup/wireless.lua

# Remove created directories (and their contents)
rm -rf /usr/lib/lua/luci/controller/
rm -rf /usr/lib/lua/luci/model/cbi/ca_setup/

# Clear Luci cache
rm -rf /tmp/luci-*

# Optionally restart uHTTPd server if needed
/etc/init.d/uhttpd restart
