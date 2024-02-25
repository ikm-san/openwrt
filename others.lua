local fs = require "nixio.fs"
local sys = require "luci.sys"

m = Map("network", "WAN接続設定の保存復元")
s = m:section(SimpleSection, nil, "設定を以下から選んでください")

local op = s:option(ListValue, "_operation", "操作")
op:value("", "-") -- デフォルトの選択肢を追加
op:value("save", "現在の設定を保存")
op:value("restore", "前回の設定に戻す")

function m.on_commit(map)
    local selected_op = m:formvalue(op:cbid())
    if selected_op == "save" then
        sys.call("cp /etc/config/network /etc/config/network.config_ipoe.old")
    elseif selected_op == "restore" then
        sys.call("cp /etc/config/network.config_ipoe.old /etc/config/network")
        sys.call("/etc/init.d/network restart")
    end
end

return m
