local fs = require "nixio.fs"
local sys = require "luci.sys"

m = Map("ca_setup", "IPoE設定")

-- Dummy Section for IPv4 over IPv6 Packages
s = m:section(TypedSection, "packages", "IPv4 over IPv6パッケージ")
s.anonymous = true
s.addremove = false

-- MAP-Eのインストールをチェックボックスで選択
local mape = s:option(Flag, "mape", "MAP-E", "MAP-Eのインストールを選択")
mape.rmempty = false

-- DS-LITEのインストールをチェックボックスで選択
local dslite = s:option(Flag, "dslite", "DS-LITE", "DS-LITEのインストールを選択")
dslite.rmempty = false

-- Dummy Section for Connection Settings
s = m:section(TypedSection, "connection", "接続設定")
s.anonymous = true
s.addremove = false

-- 接続設定をラジオボタンで選択
local conn = s:option(ListValue, "connection_type", "接続タイプ")
conn:value("none", "選択してください")
conn:value("v6plus", "v6プラス")
conn:value("v6plusB", "v6プラスB")
conn.rmempty = false

function m.on_commit(map)
    local mape_enabled = mape:formvalue(s.section) == "1"
    local dslite_enabled = dslite:formvalue(s.section) == "1"
    local connection_type = conn:formvalue(s.section)

    if mape_enabled then
        sys.call("opkg update && opkg install mape")
    end

    if dslite_enabled then
        sys.call("opkg update && opkg install ds-lite")
    end

    if connection_type == "v6plus" then
        -- v6プラスに関連するコマンドを実行
    elseif connection_type == "v6plusB" then
        -- v6プラスBに関連するコマンドを実行
    end
end

return m
