local fs = require "nixio.fs"
local sys = require "luci.sys"

m = Map("network", "WAN設定の復元保存")

s = m:section(TypedSection, "backup", "接続環境のバックアップ")
s.anonymous = true
s.addremove = false

-- ラジオボタンを作成します
local operation = s:option(ListValue, "_operation", "操作を選択")
operation:value("none", "操作を選択してください")
operation:value("save", "現在の設定を保存")
operation:value("restore", "前回の設定に戻す")

function m.on_commit(map)
    local op = operation:formvalue(s.section)
    if op == "save" then
        sys.call("cp /etc/config/network /etc/config/network.config_ipoe.old")
    elseif op == "restore" then
        sys.call("cp /etc/config/network.config_ipoe.old /etc/config/network")
        sys.call("/etc/init.d/network restart")
    end
end

return m
