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
        if fs.copy("/etc/config/network", "/etc/config/network.old") then
            -- コピーに成功した場合の処理（省略）
        else
            -- コピーに失敗した場合の処理（省略）
        end
    elseif selected_op == "restore" then
        if fs.exists("/etc/config/network.old") then
            if fs.copy("/etc/config/network.old", "/etc/config/network") then
                sys.call("/etc/init.d/network restart")
                -- 復元に成功した場合の処理（省略）
            else
                -- コピーに失敗した場合の処理（省略）
            end
        else
            -- バックアップファイルが存在しない場合の処理（省略）
        end
    end
end

return m
