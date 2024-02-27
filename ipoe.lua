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

-- PPPoEユーザー名とパスワード入力フォームの追加及び、選択された場合のみ、ユーザー名とパスワード欄を表示
username = s:option(Value, "username", "PPPoE ユーザー名")
password = s:option(Value, "password", "PPPoE パスワード")
password.password = true
username:depends("wan_setup", "pppoe_ipv4")
password:depends("wan_setup", "pppoe_ipv4")

-- インターフェース設定を削除する関数
local function deleteInterfaces()
    local interfaces = {"wan", "wan6", "wanmap", "pppoe_wan", "ds-lite", "map-e"}
    for _, interface in ipairs(interfaces) do
        uci:delete("network", interface)
    end
end

-- ds-lite接続設定関数
local function configure_dslite_connection(gw_aftr)
    -- DHCP LAN設定
    uci:set("dhcp", "lan", "dhcp")
    uci:set("dhcp", "lan", "ra", "relay")
    uci:set("dhcp", "lan", "dhcpv6", "server")
    uci:set("dhcp", "lan", "ndp", "relay")
    uci:set("dhcp", "lan", "force", "1")

    -- WAN設定の無効化
    uci:set("network", "wan", "auto", "0")

    -- DS-Liteインターフェースの設定
    uci:section("network", "interface", "dslite", {
        proto = 'dslite',
        peeraddr = gw_aftr, 
        tunlink = 'wan6',
        mtu = '1460'
    })

    -- DHCP関連設定
    uci:set("dhcp", "wan6", "dhcp")
    uci:set("dhcp", "wan6", "interface", "wan6")
    uci:set("dhcp", "wan6", "master", "1")
    uci:set("dhcp", "wan6", "ignore", "1")
    uci:set("dhcp", "wan6", "dhcpv6", "relay")
    uci:set("dhcp", "wan6", "ra", "relay")
    uci:set("dhcp", "wan6", "ndp", "relay")

    -- DS-LiteインターフェースをWANゾーンに追加
    uci:add_list("firewall", "@zone[1]", "network", "dslite")

    -- 設定のコミット
    uci:commit("dhcp")
    uci:commit("network")
    uci:commit("firewall")

    -- ネットワークサービス、DHCPサービス、ファイアウォールの再起動
    os.execute("/etc/init.d/network restart")
    os.execute("/etc/init.d/dnsmasq restart")
    os.execute("/etc/init.d/firewall restart")
end

-- LuciのSAVE＆APPLYボタンが押された時の動作
function m.on_commit(map)
    local choice_val = m.uci:get("ca_setup", "ipoe", "wan_setup")
    local gw_aftr = m.uci:get("ca_setup", choice_val, "gw_aftr")
    --既存のWAN設定を削除
    deleteInterfaces()
    
    if choice_val == "dhcp_auto" then

        -- DHCP自動設定を適用
        uci:set("network", "wan", "interface")
        uci:set("network", "wan", "proto", "dhcp")
        uci:set("network", "wan6", "interface")
        uci:set("network", "wan6", "proto", "dhcpv6")
        uci:set("network", "wan6", "reqaddress", "try")
        uci:set("network", "wan6", "reqprefix", "auto")
        uci:commit("network")
        luci.sys.exec("/etc/init.d/network restart")
        
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
        -- ここにいれる
    
    elseif choice_val == "ipoe_ocnvirtualconnect" then
        
        -- OCNバーチャルコネクト
        -- ここにいれる

    elseif choice_val == "ipoe_ipv6option" then
        
        -- BIGLOBE IPv6オプション
        -- ここにいれる

    elseif choice_val == "ipoe_transix" then
        -- transix (ds-lite)
           configure_dslite_connection(gw_aftr)
    
    elseif choice_val == "ipoe_xpass" then
        -- クロスパス (ds-lite)
           configure_dslite_connection(gw_aftr)
        
    elseif choice_val == "ipoe_v6connect" then
        -- v6コネクト
           configure_dslite_connection(gw_aftr)
        
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
