local sys = require "luci.sys"

-- Mapの定義
m = Map("network", "WAN接続設定の保存復元", "以下の選択肢を選んで設定を保存または復元")

-- SimpleSectionを使用してセクションを定義
s = m:section(TypedSection, "WAN6")

-- ラジオボタンのような選択肢
local choice = s:option(ListValue, "_choice", "操作を選択")
choice:value("save", "設定を保存")
choice:value("restore", "設定を復元")

-- 実際の処理はMapのcommitトリガーで行う
function m.on_commit(map)
    local choice_val = choice:formvalue(s.section)
    if choice_val == "save" then
        luci.sys.call("cp /etc/config/network /etc/config/network.old")
    elseif choice_val == "restore" then
        luci.sys.call("cp /etc/config/network.old /etc/config/network")
        luci.sys.call("/etc/init.d/network restart")
    end
end

return m
