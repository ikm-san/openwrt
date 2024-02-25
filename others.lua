-- ファイル: /usr/lib/lua/luci/model/cbi/ca_setup/ipoe.lua
local fs = require "nixio.fs"
local sys = require "luci.sys"

m = Map("network", "IPoE設定")

s = m:section(SimpleSection, "backup", "接続環境のバックアップ")

local save_btn = s:option(Button, "_save", "現在の設定を保存")
function save_btn.write()
    sys.call("cp /etc/config/network /etc/config/network.config_ipoe.old")
end

local restore_btn = s:option(Button, "_restore", "前回の設定に戻す")
function restore_btn.write()
    sys.call("cp /etc/config/network.config_ipoe.old /etc/config/network")
    sys.call("/etc/init.d/network restart")
end

return m

