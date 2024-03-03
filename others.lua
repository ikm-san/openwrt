local sys = require "luci.sys"
local fs = require "nixio.fs"
local uci = require "luci.model.uci".cursor()

-- Mapの初期化、'ca_setup' configファイルを使用
m = Map("ca_setup", "ネットワーク設定のバックアップ",
        "下記のリストより選んで実行してください。") 

-- 'backup'セクションの追加
s = m:section(TypedSection, "backup")
s.addremove = false
s.anonymous = true

-- 'network_config'選択肢の追加 
choice = s:option(ListValue, "network_config", "バックアップオプション")
choice:value("save", "設定を保存")
choice:value("restore", "設定を復元")

function choice.write(self, section, value)
    if value == "save" then
        sys.call("cp /etc/config/network /etc/config/network_bk")
    elseif value == "restore" then
        sys.call("cp /etc/config/network_bk /etc/config/network")
        sys.call("/etc/init.d/network reload")
    end
end

function m.on_after_commit(self)
    luci.http.redirect(luci.dispatcher.build_url("admin/ca_setup/other"))
end

return m
