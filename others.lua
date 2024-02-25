local sys = require "luci.sys"

m = Map("network",, "以下の選択肢を選んで設定を保存または復元")
s = m:section(SimpleSection)

local choice = s:option(ListValue, "_choice", "操作を選択")
choice:value("save", "設定を保存")
choice:value("restore", "設定を復元")

function m.on_commit(map)
    local choice_val = choice:formvalue(s.section)
    if choice_val == "save" then
        luci.sys.exec("cp /etc/config/network /etc/config/network.old")
    elseif choice_val == "restore" then
        luci.sys.exec("cp /etc/config/network.old /etc/config/network")
        luci.sys.exec("/etc/init.d/network restart")
    end
end

return m
