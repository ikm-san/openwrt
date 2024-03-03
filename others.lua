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
        fs.copy("/etc/config/network", "/etc/config/network.bk")
        fs.copy("/etc/config/dhcp", "/etc/config/dhcp.bk")
        fs.copy("/etc/config/firewall", "/etc/config/firewall.bk")
    elseif value == "restore" then
        if fs.stat("/etc/config/network.bk") then
        fs.copy("/etc/config/network.bk", "/etc/config/network")
        fs.copy("/etc/config/dhcp.bk", "/etc/config/dhcp")
        fs.copy("/etc/config/firewall.bk", "/etc/config/firewall")
            os.execute("/etc/init.d/network restart")
        else
            -- バックアップファイルが存在しない場合のエラーメッセージ
            m.message = "バックアップファイルが見つかりません。"
        end
    end
end

function m.on_after_commit(self)
    luci.http.redirect(luci.dispatcher.build_url("admin/ca_setup/other"))
end

return m
