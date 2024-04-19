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
