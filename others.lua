local sys = require "luci.sys"
local fs = require "nixio.fs"

-- Mapの初期化、ここでは特定の設定ファイルを操作するわけではないため、ダミーのconfig名を使用
m = Map("dummy", "以下の選択肢を選んで設定を保存または復元",
        "このフォームは実際の設定ファイルを操作しません。")

-- セクションの追加
s = m:section(TypedSection, "dummy", "操作を選択")
s.addremove = false
s.anonymous = true

-- 操作の選択肢を追加
choice = s:option(ListValue, "choice", "操作")
choice:value("save", "設定を保存")
choice:value("restore", "設定を復元")

-- このfunctionを`choice`のwrite属性に割り当て、SAVE&APPLY時に実行されるようにします
function choice.write(self, section, value)
    if value == "save" then
        luci.sys.exec("cp /etc/config/network /etc/config/network.old")
    elseif value == "restore" then
        luci.sys.exec("cp /etc/config/network.old /etc/config/network")
        luci.sys.exec("/etc/init.d/network restart")
    end
end

return m
