local fs = require "nixio.fs"
local sys = require "luci.sys"
local uci = require "luci.model.uci".cursor()

m = Map("ca_setup", "WAN接続設定", "下記のリストより適切なものを選んで実行してください。")

s = m:section(TypedSection, "ipoe", "")
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

-- PPPoEユーザー名とパスワード入力フォームの追加
username = s:option(Value, "username", "PPPoE ユーザー名")
password = s:option(Value, "password", "PPPoE パスワード")
password.password = true

-- PPPoE接続が選択された場合のみ、ユーザー名とパスワードを表示
username:depends("wan_setup", "pppoe_ipv4")
password:depends("wan_setup", "pppoe_ipv4")

-- AFTRアドレスのフォームを追加
aftr = s:option(Value, "AFTR", "AFTRアドレス")
aftr:depends("wan_setup", "ipoe_transix")  -- ipoe_transixが選択されたときのみ表示
aftr:depends("wan_setup", "ipoe_xpass")   
aftr:depends("wan_setup", "ipoe_v6connect")   

-- ipoe_transixまたはipoe_xpassが選択された場合に、対応するgw_aftrの値を取得してデフォルト値として設定
function aftr.cfgvalue(self, section)
    local wan_setup = m.uci:get("ca_setup", "ipoe", "wan_setup")
    if wan_setup == "ipoe_transix" then
        return m.uci:get("ca_setup", "ipoe_transix", "gw_aftr") 
    elseif wan_setup == "ipoe_xpass" then
        return m.uci:get("ca_setup", "ipoe_xpass", "gw_aftr") 
    elseif wan_setup == "ipoe_v6connect" then
        return m.uci:get("ca_setup", "ipoe_v6connect", "gw_aftr") 
    end
end

function m.on_commit(map)
    local choice_val = m.uci:get("ca_setup", "ipoe", "wan_setup")
    local gw_aftr = aftr:formvalue(s.section) or ""

    
    if choice_val == "dhcp_auto" then
        luci.sys.exec("cp /etc/config/network /etc/config/network.old")
        -- luci.sys.exec("/etc/init.d/network restart")
    elseif choice_val == "pppoe_ipv4" then
        -- PPPoE設定を適用
        local user = m.uci:get("ca_setup", "ipoe", "username")
        local pass = m.uci:get("ca_setup", "ipoe", "password")
        uci:set("network", "pppoe_wan", "interface")
        uci:set("network", "pppoe_wan", "proto", "pppoe")
        uci:set("network", "pppoe_wan", "username", user)
        uci:set("network", "pppoe_wan", "password", pass)
        uci:set("network", "pppoe_wan", "ifname", "eth0.2")
        uci:commit("network")
        luci.sys.exec("/etc/init.d/network restart")

    elseif choice_val == "ipoe_v6plus" then
        -- v6プラス
        luci.sys.exec("opkg update && opkg install mape")
    elseif choice_val == "ipoe_ocnvirtualconnect" then
        -- OCNバーチャルコネクト
        luci.sys.exec("opkg update && opkg install mape")

    elseif choice_val == "ipoe_ipv6option" then
        -- BIGLOBE IPv6オプション
        luci.sys.exec("opkg update && opkg install mape")

    elseif choice_val == "ipoe_transix" then
        -- transix (ds-lite)
           local gw_aftr = uci:get("ca_setup", "ipoe_transix", "gw_aftr")
        -- sys.exec("/path/to/your/script.sh '" .. gw_aftr .. "'")
        -- luci.sys.exec("opkg update && opkg install ds-lite")
    
    elseif choice_val == "ipoe_xpass" then
        -- クロスパス (ds-lite)
           local gw_aftr = uci:get("ca_setup", "ipoe_xpass", "gw_aftr")
        -- sys.exec("/path/to/your/script.sh '" .. gw_aftr .. "'")
        -- luci.sys.exec("opkg update && opkg install ds-lite")   
    
    elseif choice_val == "ipoe_v6connect" then
        -- v6コネクト
           local gw_aftr = uci:get("ca_setup", "ipoe_v6connect", "gw_aftr")
        -- sys.exec("/path/to/your/script.sh '" .. gw_aftr .. "'")
        -- luci.sys.exec("opkg update && opkg install ds-lite")   


        
    elseif choice_val == "bridge_mode" then
        -- ブリッジモード設定の適用
        -- uci:set("network", "lan", "type", "bridge")
        -- uci:set("network", "lan", "ifname", "eth0.1 eth0.2")  -- 例としてeth0.1とeth0.2をブリッジ
        -- uci:delete("network", "lan", "proto")  -- DHCPなどの既存設定を削除
        -- uci:commit("network")
        -- luci.sys.exec("/etc/init.d/network restart")
    end
end

return m
