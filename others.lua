local fs = require "nixio.fs"
local sys = require "luci.sys"

m = Map("network", "WAN設定バックアップ", "設定の保存と復元")
s = m:section(SimpleSection, nil, "WAN接続環境のバックアップと復元を以下から選択してください。")

local op = s:option(ListValue, "_operation", "操作")
op:value("", "-")
op:value("save", "現在の設定を保存")
op:value("restore", "前回の設定に戻す")

function m.on_commit(map)
    local selected_op = op:formvalue(s.section)
    if selected_op == "save" then
        sys.call("cp /etc/config/network /etc/config/network.config_ipoe.old")
    elseif selected_op == "restore" then
        sys.call("cp /etc/config/network.config_ipoe.old /etc/config/network")
        sys.call("/etc/init.d/network restart")
    end
end

return m
