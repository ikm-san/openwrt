local fs = require "nixio.fs"
local sys = require "luci.sys"
local http = require "luci.http"

m = Map("ca_setup", translate("CA Setup"),
        translate("This page allows you to update CA setup files."))

s = m:section(TypedSection, "ca_setup", "Files")
s.anonymous = true

function s.cfgsections()
    return { "_update" }
end

update = s:option(Button, "_update", "Update Files")
update.inputtitle = translate("Update Now")
update.inputstyle = "reload"

function update.write()
        sys.exec("wget -O /usr/lib/lua/luci/controller/ca_setup.lua https://raw.githubusercontent.com/ikm-san/openwrt/main/ca_setup.lua")
        sys.exec("wget -O /usr/lib/lua/calib.lua https://raw.githubusercontent.com/ikm-san/openwrt/main/calib.lua")
        sys.exec("wget -O /usr/lib/lua/luci/model/cbi/ca_setup/ipoe.lua https://raw.githubusercontent.com/ikm-san/openwrt/main/ipoe.lua")
        sys.exec("wget -O /usr/lib/lua/luci/model/cbi/ca_setup/wireless.lua https://raw.githubusercontent.com/ikm-san/openwrt/main/wireless.lua")
        sys.exec("wget -O /usr/lib/lua/luci/model/cbi/ca_setup/update.lua https://raw.githubusercontent.com/ikm-san/openwrt/main/update.lua")
        sys.exec("wget -O /usr/lib/lua/luci/model/cbi/ca_setup/sandbox.lua https://raw.githubusercontent.com/ikm-san/openwrt/main/sandbox.lua")
        sys.exec("wget -O /etc/config/ca_setup https://raw.githubusercontent.com/ikm-san/openwrt/main/ca_setup")
        sys.exec("rm -rf /tmp/luci-*")
        sys.exec("/etc/init.d/uhttpd restart")
        -- デバイスを再起動する
        -- luci.sys.reboot()
end

return m
