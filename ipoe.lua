local fs = require "nixio.fs"
local sys = require "luci.sys"

m = Map("ca_setup", "WAN接続設定", "WAN接続の設定をおこないます。")

s = m:section(TypedSection, "ipoe", "WAN設定")
s.addremove = false
s.anonymous = true

choice = s:option(ListValue, "wan_setup", "操作") 
choice:value("dhcp_auto", "DHCP自動")
choice:value("pppoe_ipv4", "PPPoE接続")
choice:value("ipoe_v6plus", "v6プラス")
choice:value("ipoe_ocnvirtualconnect", "OCNバーチャルコネクト")
choice:value("ipoe_ipv6option", "IPv6オプション")
choice:value("ipoe_transix", "transix")
choice:value("ipoe_xpass", "クロスパス")
choice:value("ipoe_v6connect", "v6コネクト")
choice:value("bridge_mode", "ブリッジモード")

function m.on_commit(map)
    local choice_val = m.uci:get("ca_setup", "ipoe", "wan_setup")
    if choice_val == "dhcp_auto" then
        luci.sys.exec("cp /etc/config/network /etc/config/network.old")
       -- luci.sys.exec("/etc/init.d/network restart")
    elseif choice_val == "pppoe_ipv4" then
        -- 実行内容を追加
    elseif choice_val == "ipoe_v6plus" then
        -- 実行内容を追加
        luci.sys.exec("opkg update && opkg install mape")
    elseif choice_val == "ipoe_ocnvirtualconnect" then
        -- 実行内容を追加
        luci.sys.exec("opkg update && opkg install mape")

    elseif choice_val == "ipoe_ipv6option" then
        -- 実行内容を追加
        luci.sys.exec("opkg update && opkg install mape")

    elseif choice_val == "ipoe_transix" then
        -- 実行内容を追加
        luci.sys.exec("opkg update && opkg install ds-lite")
    elseif choice_val == "ipoe_xpass" then
        -- 実行内容を追加
        luci.sys.exec("opkg update && opkg install ds-lite")
    elseif choice_val == "ipoe_v6connect" then
        -- 実行内容を追加
        luci.sys.exec("opkg update && opkg install ds-lite")
    elseif choice_val == "bridge_mode" then
        -- 実行内容を追加
    end
end

return m
