local fs = require "nixio.fs"
local sys = require "luci.sys"

m = Map("ca_setup", "IPoE設定")

-- Dummy Section for Connection Settings
s = m:section(TypedSection, "connection", "接続設定")
s.anonymous = true
s.addremove = false

-- 接続設定をラジオボタンで選択
local conn = s:option(ListValue, "connection_type", "接続タイプ")
conn:value("dhcp", "DHCP自動")
conn:value("pppoe", "PPPoE接続")
conn:value("v6plus", "v6プラス")
conn:value("ds-liteA", "ds-liteA")
conn:value("bridge", "ブリッジモード")
conn.rmempty = false

function m.on_commit(map)
    local connection_type = conn:formvalue(s.section)

    if connection_type == "v6plus" then
        sys.call("opkg update && opkg install mape")
    elseif connection_type == "ds-liteA" then
        sys.call("opkg update && opkg install ds-lite")
    elseif connection_type == "dhcp" then
        -- DHCP自動に関連するコマンドを実行
    elseif connection_type == "bridge" then
        -- ブリッジモードに関連するコマンドを実行
    elseif connection_type == "pppoe" then
        -- PPPoEに関連するコマンドを実行
    end
end

return m
