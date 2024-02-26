local sys = require "luci.sys"
local fs = require "nixio.fs"

-- Mapの初期化、'ca_setup' configファイルを使用
m = Map("ca_setup", "ネットワーク設定のバックアップ",
        ネットワーク設定を保存または復元できます。")

-- 'backup'セクションの追加
s = m:section(TypedSection, "backup", "バックアップオプション")
s.addremove = false
s.anonymous = true

-- 'network_config_save'選択肢の追加
choice = s:option(ListValue, "network_config", "操作")
choice:value("save", "設定を保存")
choice:value("restore", "設定を復元")

function m.on_commit(map)
    local choice_val = m.uci:get("ca_setup", "backup", "network_config")
    if choice_val == "save" then
        luci.sys.exec("cp /etc/config/network /etc/config/network.old")
    elseif choice_val == "restore" then
        luci.sys.exec("cp /etc/config/network.old /etc/config/network")
        luci.sys.exec("/etc/init.d/network restart")
    end
end

return m
