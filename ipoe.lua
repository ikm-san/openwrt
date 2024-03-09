local fs = require "nixio.fs"
local sys = require "luci.sys"
local uci = require "luci.model.uci".cursor()
local calib = require "calib" 

-- basic map-e conversion table based on http://ipv4.web.fc2.com/map-e.html
local ruleprefix31 = calib.getRulePrefix31()
local ruleprefix38 = calib.getRulePrefix38()
local ruleprefix38_20 = calib.getRulePrefix38_20()





local wan_ipv6 = calib.get_wan_ipv6_global() -- WANのグローバルIPv6を取得


-- Pattern to match the first four sections of an IPv6 address
local pattern = "^([0-9a-fA-F]+:[0-9a-fA-F]+:[0-9a-fA-F]+:[0-9a-fA-F]+)"
local ipv6_56 = wan_ipv6:match(pattern)

-- Mape関連の数値を取得する関数、IPv6アドレスから対応するIPv4プレフィックスを取得
local function find_ipv4_prefix(wan_ipv6)
    local segments = {}
    for seg in wan_ipv6:gmatch("[a-fA-F0-9]+") do
        table.insert(segments, string.format("%04x", tonumber(seg, 16)))
    end

    local full_ipv6 = table.concat(segments, ":"):gsub("::", function(s)
        return ":" .. string.rep("0000:", 8 - #segments)
    end)

    -- 40ビットと32ビットのプレフィックスを取得
    local hex_prefix_40 = full_ipv6:gsub(":", ""):sub(1, 10)
    local hex_prefix_32 = full_ipv6:gsub(":", ""):sub(1, 8)

    local ipv4_prefix = ruleprefix38[hex_prefix_40] or ruleprefix38_20[hex_prefix_40] or ruleprefix31[hex_prefix_32]
    local ipv6_prefixlen

    if ipv4_prefix then
        local ipv4_parts = {}
        for part in ipv4_prefix:gmatch("(%d+)") do
            table.insert(ipv4_parts, part)
        end
        while #ipv4_parts < 4 do
            table.insert(ipv4_parts, "0")
        end

        -- 有効なプレフィックス長を判断
        if ruleprefix38[hex_prefix_40] or ruleprefix38_20[hex_prefix_40] then

                     -- ipv6prefixを32ビットもしくは48ビットセクションまで抽出し48ビットフォーマットの場合は00で埋める
                     local function extract_ipv6_prefix(wan_ipv6)
                                    -- IPv6アドレスを":"で分割
                                    local ipv6_sections = {}
                                    for section in wan_ipv6:gmatch("[^:]+") do
                                        table.insert(ipv6_sections, section)
                                    end
                                
                                    -- 先頭から48ビットを取り出し、最後の8ビットを00にする処理を正しく行う
                                    local prefix = ipv6_sections[1]
                                    if #ipv6_sections >= 3 then
                                        -- 3セクション目が存在する場合、先頭2セクションをそのまま使用し、3セクション目の先頭2文字を使用して後ろに00を追加
                                        local full_third = string.format("%04x", tonumber(ipv6_sections[3], 16))
                                        local third_section = string.sub(full_third, 1, 2) -- 3セクション目の２文字を取得

                                            if third_section ~= "00" then
                                                    prefix = prefix .. ":" .. ipv6_sections[2] .. ":" .. third_section .. "00"
                                                    local dec_value = tonumber(third_section, 16)
                                                        -- 10進数値を関数で2進数に変換
                                                    local bin_value = calib.dec_to_bin(dec_value)
                                                        -- ビット数を算出
                                                    ipv6_prefixlen = #bin_value + 32
                                            else
                                                    -- 3セクション目が存在しない場合、先頭2セクションのみを使用
                                                    prefix = prefix .. ":" .. ipv6_sections[2]
                                                    ipv6_prefixlen = 32
                                            end
                
                                    else
                                        -- 3セクション目が存在しない場合、先頭2セクションのみを使用
                                        prefix = prefix .. ":" .. ipv6_sections[2]
                                        ipv6_prefixlen = 32
                                    end
                                
                                    -- 3セクション目が"00"になった場合の処理は、具体的な例に基づいて調整が必要
                                    if prefix:find(":00") then
                                        -- 第3セクションが"00"の場合、省略可能なルールに従い調整
                                        prefix = prefix:gsub(":00", "")
                                    end                
                                    
                            -- 最後にプレフィックスの省略形を生成
                            return prefix .. ":", ipv6_prefixlen
                        end
            
                            function to_binary(n)
                                        if n == 0 then return "0" end
                                        local bin = ""
                                        while n > 0 do
                                            bin = tostring(n % 2) .. bin
                                            n = math.floor(n / 2)
                                        end
                                        return bin
                            end
                local third_octet = tonumber(ipv4_prefix:match("^%d+%.%d+%.(%d+)")) -- 第3セクションを数値として抽出
                local binary_string = to_binary(third_octet)
                ipv4_prefixlen = string.len(binary_string) + 16
                ipv6_prefix , ipv6_prefixlen = extract_ipv6_prefix(wan_ipv6)
                -- ipv6_prefixlen = 33 --デバッグ用
            
        elseif ruleprefix31[hex_prefix_32] then
            ipv6_prefixlen = 32
            ipv4_prefixlen = 16
            ipv6_prefix = wan_ipv6:sub(1, 8) .. ":"
        end

        ealen = 56 - ipv6_prefixlen
        psidlen = ealen - (32 - ipv4_prefixlen)
        
        return table.concat(ipv4_parts, "."), ipv4_prefixlen, ipv6_prefix, ipv6_prefixlen, ealen, psidlen
    else
        return nil, "No matching IPv4 prefix found."
    end
end







m = Map("ca_setup", "WAN接続設定", "下記のリストより適切なものを選んで実行してください。")

s = m:section(TypedSection, "ipoe", "")
s.addremove = false
s.anonymous = true

choice = s:option(ListValue, "wan_setup", "操作")
choice:value("dhcp_auto", "DHCP自動")
choice:value("pppoe_ipv4", "PPPoE接続")
choice:value("ipoe_v6plus", "v6プラス")
choice:value("ipoe_ocnvirtualconnect", "OCNバーチャルコネクト")
choice:value("ipoe_biglobe", "IPv6オプション")
choice:value("ipoe_transix", "transix")
choice:value("ipoe_xpass", "クロスパス")
choice:value("ipoe_v6connect", "v6コネクト")
choice:value("bridge_mode", "ブリッジ・APモード")

-- PPPoEユーザー名とパスワード入力フォームの追加及び、選択された場合のみ、ユーザー名とパスワード欄を表示
username = s:option(Value, "username", "PPPoE ユーザー名")
password = s:option(Value, "password", "PPPoE パスワード")
password.password = true
username:depends("wan_setup", "pppoe_ipv4")
password:depends("wan_setup", "pppoe_ipv4")

-- インターフェース設定を削除する関数
local function deleteInterfaces()
    local interfaces = {"wanmap", "dslite", "map-e"}
    for _, interface in ipairs(interfaces) do
        uci:delete("network", interface)
        uci:commit("network")
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
    uci:commit("network")
    
    -- DHCP関連設定
    uci:set("dhcp", "wan6", "dhcp")
    uci:set("dhcp", "wan6", "interface", "wan6")
    uci:set("dhcp", "wan6", "master", "1")
    uci:set("dhcp", "wan6", "ignore", "1")
    uci:set("dhcp", "wan6", "dhcpv6", "relay")
    uci:set("dhcp", "wan6", "ra", "relay")
    uci:set("dhcp", "wan6", "ndp", "relay")
    uci:commit("dhcp")

    -- DS-LiteインターフェースをWANゾーンに追加
    uci:set_list("firewall", "@zone[1]", "network", {"wan", "wan6"})
    uci:commit("firewall")

end

-- map-e 接続設定関数
function configure_mape_connection(peeraddr, ipv4_prefix, ipv4_prefixlen, ipv6_prefix, ipv6_prefixlen, ealen, psidlen, offset)
    -- DHCP LAN settings
    uci:set("dhcp", "lan", "dhcp")
    uci:set("dhcp", "lan", "dhcpv6", "server")
    uci:set("dhcp", "lan", "ra", "relay")
    uci:set("dhcp", "lan", "ndp", "relay")
    uci:set("dhcp", "lan", "force", "1")

    -- DHCP WAN6 settings
    uci:set("dhcp", "wan6", "dhcp")
    uci:set("dhcp", "wan6", "interface", "wan6")
    uci:set("dhcp", "wan6", "ignore", "1")
    uci:set("dhcp", "wan6", "master", "1")
    uci:set("dhcp", "wan6", "ra", "relay")
    uci:set("dhcp", "wan6", "dhcpv6", "relay")
    uci:set("dhcp", "wan6", "ndp", "relay")
    uci:commit("dhcp")  

    -- WAN settings
    uci:set("network", "wan", "auto", "0")
    
    -- WAN6 settings
    uci:set("network", "wan6", "proto", "dhcpv6")
    uci:set("network", "wan6", "reqaddress", "try")
    uci:set("network", "wan6", "reqprefix", "auto")
    uci:set("network", "wan6", "ip6prefix", ipv6_56 .. "::/56")
    
    -- WANMAP settings
    uci:section("network", "interface", "wanmap", {
        proto = "map",
        maptype = "map-e",
        peeraddr = peeraddr,
        ipaddr = ipv4_prefix,
        ip4prefixlen = ipv4_prefixlen,
        ip6prefix = ipv6_prefix,
        ip6prefixlen = ipv6_prefixlen,
        ealen = ealen,
        psidlen = psidlen,
        offset = offset,
        legacymap = "1",
        mtu = "1460",
        tunlink= "wan6",
        encaplimit = "ignore" --v6プラスのみ？
    })
    uci:commit("network") 

    -- Firewall settings
    uci:delete("firewall", "@zone[1]", "network", "wan")
    uci:set_list("firewall", "@zone[1]", "network", {"wan6", "wanmap"})
    uci:commit("firewall")
end

-- Biglobe用の東西peeraddr切り分け関数
local function set_peeraddr(wan_ipv6)
    local peeraddr
    local target_char = wan_ipv6:sub(9,9)
    if target_char then
        local num = tonumber(target_char, 16)
        if num >= 0 and num < 4 then
            peeraddr = "2001:260:700:1::1:275"
        elseif num >= 4 and num < 8 then
            peeraddr = "2001:260:700:1::1:276"
        end
    end
    return peeraddr
end


--デバッグ表示用

local ipv4_prefix, ipv4_prefixlen, ipv6_prefix, ipv6_prefixlen, ealen, psidlen = find_ipv4_prefix(wan_ipv6)
local offset = 4 -- 実際のオフセットを計算または取得する処理を追加
-- local peeraddr = set_peeraddr(wan_ipv6)

o = s:option(DummyValue, "wan_ipv6", translate("WAN IPv6 Address"))
o.value = wan_ipv6 or translate("Not available")

o = s:option(DummyValue, "ipv4_prefix", translate("MAPE IPv4 Prefix"))
o.value = ipv4_prefix or translate("No matching IPv4 prefix found.")

o = s:option(DummyValue, "ipv4_prefixlen", translate("IPv4 Prefix Length"))
o.value = ipv4_prefixlen or translate("Not available")

o = s:option(DummyValue, "ipv6_prefixlen", translate("IPv6 Prefix Length"))
o.value = ipv6_prefixlen or translate("Not available")

o = s:option(DummyValue, "ipv6_prefix", translate("IPv6 Prefix"))
o.value = ipv6_prefix

o = s:option(DummyValue, "ealen", translate("EA Length"))
o.value = ealen

o = s:option(DummyValue, "psidlen", translate("PSID Length"))
o.value = psidlen

o = s:option(DummyValue, "offset", translate("Offset"))
o.value = offset

o = s:option(DummyValue, "peeraddr", translate("peeraddr"))
o.value = peeraddr or translate("Not BIGLOBE")




--ここまで



-- LuciのSAVE＆APPLYボタンが押された時の動作
-- function m.on_commit(map)
function choice.write(self, section, value)
        deleteInterfaces()
    
    if value == "dhcp_auto" then
        -- DHCP自動設定を適用
        -- wan インターフェースの設定を変更
        uci:set("network", "wan", "ifname", "wan")
        uci:set("network", "wan", "proto", "dhcp")
        
        -- wan6 インターフェースの設定を変更
        uci:set("network", "wan6", "ifname", "wan6")
        uci:set("network", "wan6", "proto", "dhcpv6")
        uci:set("network", "wan6", "reqaddress", "try")
        uci:set("network", "wan6", "reqprefix", "auto")
        uci:commit("network")

        -- Firewall settings
        uci:set_list("firewall", "@zone[1]", "network", {"wan", "wan6"})
        uci:commit("firewall")
        
        
    elseif value == "pppoe_ipv4" then
        
        -- PPPoE設定を適用
        -- user = m.uci:get("ca_setup", "ipoe", "username")
        -- pass = m.uci:get("ca_setup", "ipoe", "password")
         uci:section("network", "interface", "wan", {
            proto = "pppoe",
            username = username:formvalue(section),
            password = password:formvalue(section),
        })
        uci:commit("network") 
        uci:save() 
        
        
        -- WAN settings
        uci:set("network", "wan", "auto", "1")
        uci:set("network", "wan6", "auto", "0")
        uci:commit("network")        

        uci:set_list("firewall", "@zone[1]", "network", {"wan"})     
        uci:commit("firewall")
        
    elseif value == "ipoe_v6plus" then
       
        -- v6プラス
            wan_ipv6 = get_wan_ipv6_global()
            peeraddr = "2404:9200:225:100::64"
            offset = 4
            ipv4_prefix, ipv4_prefixlen, ipv6_prefix, ipv6_prefixlen, ealen, psidlen = find_ipv4_prefix(wan_ipv6)
            configure_mape_connection(peeraddr, ipv4_prefix, ipv4_prefixlen, ipv6_prefix, ipv6_prefixlen, ealen, psidlen, offset)
    
    elseif value == "ipoe_ocnvirtualconnect" then
        
        -- OCNバーチャルコネクト
            peeraddr = "2001:380:a120::9"
            offset = 6 -- OCN要確認
            ipv4_prefix, ipv4_prefixlen, ipv6_prefix, ipv6_prefixlen, ealen, psidlen = find_ipv4_prefix(wan_ipv6)
            configure_mape_connection(peeraddr, ipv4_prefix, ipv4_prefixlen, ipv6_prefix, ipv6_prefixlen, ealen, psidlen, offset)
        -- ここにいれる 細かい設定が違うので、v6プラスと分ける必要がある

    elseif value == "ipoe_biglobe" then
        
        -- BIGLOBE IPv6オプション
            peeraddr = set_peeraddr(wan_ipv6)
            offset = 4    
            ipv4_prefix, ipv4_prefixlen, ipv6_prefix, ipv6_prefixlen, ealen, psidlen = find_ipv4_prefix(wan_ipv6)
            configure_mape_connection(peeraddr, ipv4_prefix, ipv4_prefixlen, ipv6_prefix, ipv6_prefixlen, ealen, psidlen, offset)
        
    elseif value == "ipoe_transix" then
        -- transix (ds-lite)
            gw_aftr = m.uci:get("ca_setup", "ipoe_transix", "gw_aftr")
            configure_dslite_connection(gw_aftr)
    
    elseif value == "ipoe_xpass" then
        -- クロスパス (ds-lite)
            gw_aftr = m.uci:get("ca_setup", "ipoe_xpass", "gw_aftr")
            configure_dslite_connection(gw_aftr)
        
    elseif value == "ipoe_v6connect" then
        -- v6コネクト
            gw_aftr = m.uci:get("ca_setup", "ipoe_v6connect", "gw_aftr")
            configure_dslite_connection(gw_aftr)
        
    elseif value == "bridge_mode" then
        -- ブリッジモード設定の適用
            -- ルーター用のサービス停止
            local services = {"firewall", "dnsmasq", "odhcpd"}
            for _, service in ipairs(services) do
                if sys.init.enabled(service) then
                    sys.init.stop(service)
                    sys.init.disable(service)
                end
            end
            
            -- LANインターフェースをDHCPクライアントに切り替える
            uci:set("network", "lan", "proto", "dhcp")
            uci:delete("network", "wan")
            uci:delete("network", "wan6")
            uci:delete("network", "lan", "ipaddr")
            uci:delete("network", "lan", "netmask")
            
            -- ホスト名を"WifiAP"に変更する
            uci:set("system", "@system[0]", "hostname", "WifiAP")
            
            -- すべての変更をコミットする
            uci:commit()
            
            -- ファイアウォールの設定を削除する
            os.execute("mv /etc/config/firewall /etc/config/firewall.unused")
            
    end


end

function m.on_after_commit(self)
        -- デバイスを再起動する
        luci.sys.reboot()
        luci.http.redirect(luci.dispatcher.build_url("admin/"))
end

return m
