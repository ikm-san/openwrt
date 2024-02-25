local fs = require "nixio.fs"
local sys = require "luci.sys"

m = Map("ca_setup", "IPoE設定")

-- IPv4 over IPv6パッケージのセクション
s = m:section(TypedSection, "ipoe", "IPv4 over IPv6パッケージ")
s.anonymous = true

-- MAP-Eのインストールをチェックボックスで選択
local mape = s:option(Flag, "mape", "MAP-E")
function mape.write(self, section, value)
    if value == "1" then
        sys.call("opkg update && opkg install mape")
    end
end

-- DS-LITEのインストールをチェックボックスで選択
local dslite = s:option(Flag, "dslite", "DS-LITE")
function dslite.write(self, section, value)
    if value == "1" then
        sys.call("opkg update && opkg install ds-lite")
    end
end

-- 接続設定のセクション
s = m:section(TypedSection, "ipoe", "接続設定")
s.anonymous = true

-- 接続設定をラジオボタンで選択
local conn = s:option(ListValue, "connection", "接続タイプ")
conn:value("v6plus", "v6プラス")
conn:value("v6plusB", "v6プラスB")

function m.on_commit(map)
    local connection_type = conn:formvalue(s.section)
    if connection_type == "v6plus" then
        sys.call("wget -O /tmp/v6plus.sh https://example.com/v6plus.sh && chmod +x /tmp/v6plus.sh && /tmp/v6plus.sh")
    elseif connection_type == "v6plusB" then
        -- v6プラスB用のスクリプトを実行するコマンドをここに記述
        sys.call("echo 'v6プラスBが選択されました'")
    end
end

return m
