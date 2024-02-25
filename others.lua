local sys = require "luci.sys"

m = Map("network", "WAN接続設定の保存復元") 

-- TypedSection を使用し、例として 'interface' セクションタイプを指定します。
-- これは network 設定ファイル内の実際のセクションタイプに基づくべきです。
s = m:section(TypedSection, "interface", "設定を以下から選んでください")
s.addremove = false -- セクションの追加や削除は不要な場合は false に設定
s.anonymous = true -- セクションの名前を表示しない

local op = s:option(ListValue, "_operation", "操作")
op:value("save", "現在の設定を保存")
op:value("restore", "前回の設定に戻す")

function m.on_commit(map)
    local selected_op = m:formvalue(op:cbid())
    if selected_op == "save" then
        sys.call("cp /etc/config/network /etc/config/network.old")
    elseif selected_op == "restore" then
        sys.call("cp /etc/config/network.old /etc/config/network")
        sys.call("/etc/init.d/network restart")
    end
end

return m
