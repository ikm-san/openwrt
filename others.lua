local sys = require "luci.sys"
local fs = require "nixio.fs"

-- SimpleFormの初期化
f = SimpleForm("network", "以下の選択肢を選んで設定を保存または復元")
f.submit = "実行"
f.reset = false

-- フォームのセクションを作成
s = f:section(SimpleSection)

-- 操作の選択肢を定義
local choice = s:option(ListValue, "_choice", "操作を選択")
choice:value("save", "設定を保存")
choice:value("restore", "設定を復元")

-- フォームのコミット時の動作を定義
function f.handle(self, state, data)
    if state == FORM_VALID then
        if data._choice == "save" then
            luci.sys.exec("cp /etc/config/network /etc/config/network.old")
        elseif data._choice == "restore" then
            luci.sys.exec("cp /etc/config/network.old /etc/config/network")
            luci.sys.exec("/etc/init.d/network restart")
        end
    end
    return true
end

return f
