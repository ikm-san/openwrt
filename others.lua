-- ファイル: /usr/lib/lua/luci/model/cbi/ca_setup/ipoe.lua
local fs = require "nixio.fs"
local sys = require "luci.sys"

m = Map("network", "IPoE設定")

-- ここではTypedSectionの種類や名前が特に関係ないため、'ipoe'としていますが、
-- 実際にはnetwork設定に合わせて適切なセクションを選択する必要があります。
-- ただし、このスクリプトの主目的はボタンによるアクションなので問題ありません。
s = m:section(TypedSection, "ipoe", "接続環境のバックアップ")
s.anonymous = true

local save_btn = s:option(Button, "_save", "現在の設定を保存")
function save_btn.write(self, section)
    sys.call("cp /etc/config/network /etc/config/network.config_ipoe.old")
end

local restore_btn = s:option(Button, "_restore", "前回の設定に戻す")
function restore_btn.write(self, section)
    sys.call("cp /etc/config/network.config_ipoe.old /etc/config/network")
    sys.call("/etc/init.d/network restart")
end

return m

s = m:section(TypedSection, "ipoe", "IPv4 over IPv6パッケージ")
s.anonymous = true

s:option(Button, "_mape", "MAP-E").write = function()
    sys.call("opkg update && opkg install mape")
end

s:option(Button, "_dslite", "DS-LITE").write = function()
    sys.call("opkg update && opkg install ds-lite")
end

s = m:section(TypedSection, "ipoe", "接続設定")
s.anonymous = true

-- ここに接続設定のためのボタンを追加します。
-- 例:
s:option(Button, "_v6plus", "v6プラス").write = function()
    sys.call("wget -O /tmp/v6plus.sh https://raw.githubusercontent.com/ikm-san/openwrt/main/sample.sh && chmod +x /tmp/v6plus.sh && /tmp/v6plus.sh")
end

-- 他の接続設定ボタンも同様に追加

s = m:section(TypedSection, "ipoe", "その他の設定")
s.anonymous = true

s:option(Button, "_reboot", "ルーターを再起動する").write = function()
    sys.call("reboot")
end

return m
