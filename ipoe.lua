local fs = require "nixio.fs"
local sys = require "luci.sys"

m = Map("network", "WAN接続設定")

-- SimpleSectionを使用して接続設定を表示
s = m:section(SimpleSection, nil, "設定を以下から選んでください")

-- 接続設定をラジオボタンで選択
local conn = s:option(ListValue, "connection_type", "接続タイプ")
conn:value("dhcp", "DHCP自動")
conn:value("pppoe", "PPPoE接続")
conn:value("v6plus", "v6プラス")
conn:value("ds-liteA", "ds-liteA")
conn:value("bridge", "ブリッジモード")

-- 選択された接続タイプを取得するためのキーを保存するフィールド
local key = conn:cbid()

function m.on_after_commit(map)
    local connection_type = m:formvalue(key)

    if connection_type == "dhcp" then
        -- DHCP接続に関する設定を更新
    elseif connection_type == "pppoe" then
        -- PPPoE接続に関する設定を更新
    elseif connection_type == "v6plus" then
        sys.call("opkg update && opkg install mape")
    elseif connection_type == "ds-liteA" then
        sys.call("opkg update && opkg install ds-lite")
    elseif connection_type == "bridge" then
        -- ブリッジモードに関する設定を更新
    end

    -- 変更を適用するためにネットワークサービスを再起動
    sys.call("/etc/init.d/network restart")
end

return m
