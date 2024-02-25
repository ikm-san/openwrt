local sys = require "luci.sys"

-- Mapの定義
m = Map("network", "WAN接続設定の保存復元", "以下のボタンをクリックして設定を保存または復元")

-- SimpleSectionを使用してセクションを定義
s = m:section(SimpleSection)

-- 保存ボタン
local save = s:option(Button, "_save", "設定を保存")
function save.write(self.SimpleSection)
    sys.call("cp /etc/config/network /etc/config/network.old")
end

-- 復元ボタン
local restore = s:option(Button, "_restore", "設定を復元")
function restore.write()
    sys.call("cp /etc/config/network.old /etc/config/network")
    sys.call("/etc/init.d/network restart")
end

return m
