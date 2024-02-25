local fs = require "nixio.fs"
local sys = require "luci.sys"

m = Map("network", "WAN接続設定の保存復元")
s = m:section(SimpleSection, nil, "設定を以下から選んでください")

local op = s:option(ListValue, "_operation", "操作")
op:value("save", "現在の設定を保存")
op:value("restore", "前回の設定に戻す")

function m.on_commit(map)
    local selected_op = m:formvalue(op:cbid())
    if selected_op == "save" then
        local res = sys.call("cp /etc/config/network /etc/config/network.old")
        if res ~= 0 then
            -- コピーに失敗した場合の処理
            m.message = "設定の保存に失敗しました。"
        end
    elseif selected_op == "restore" then
        local res = sys.call("cp /etc/config/network.config_ipoe.old /etc/config/network")
        if res == 0 then
            sys.call("/etc/init.d/network restart")
        else
            -- コピーに失敗した場合の処理
            m.message = "設定の復元に失敗しました。"
        end
    end
end

return m
