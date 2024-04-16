local fs = require "nixio.fs"
local sys = require "luci.sys"
local uci = require "luci.model.uci".cursor()
local calib = require "calib" 
local json = require("luci.jsonc")
local http = require "luci.http"
local ubus = require "ubus"

-- IPv6_56アドレスとprefixの取得 --
local function getIPv6PrefixInfo()
    local handle = io.popen("ubus call network.interface.wan6 status")
    local result = handle:read("*a")
    handle:close()

    local data = json.parse(result)
    local ipv6Prefix, prefixLength = "not found", "not found"
    
    if data["route"] and data["route"][1] then
        ipv6Prefix = data["route"][1].target or ipv6Prefix
        prefixLength = data["route"][1].mask or prefixLength
    end

    return ipv6Prefix, prefixLength
end
   
local ipv6Prefix, prefixLength = getIPv6PrefixInfo()



-- WANのグローバルIPv6を取得 --
local wan_ipv6 = calib.get_wan_ipv6_global() 
-- local wan_ipv6 = ipv6Prefix



-- VNEの判定 --
local VNE = calib.dtermineVNE(wan_ipv6)

-- BRANDの判定 --
local brandcheck = calib.brandcheck()

-- トレーサートの最初のホップのIPアドレスを取得
local function get_first_hop_ip()
    local traceroute_output = sys.exec("traceroute -m 1 8.8.8.8")
    -- 最初のホップのIPアドレスを抽出する正規表現を調整
    local ip = traceroute_output:match(" 1%s+(%d+%.%d+%.%d+%.%d+)")
    return ip
end

-- 最初のホップがプライベートIPかどうかをチェック
local function check_under_router()
    local first_hop_ip = get_first_hop_ip()
    if first_hop_ip and (first_hop_ip:match("^192%.168%.") or first_hop_ip:match("^10%.") or first_hop_ip:match("^172%.(1[6-9]|2[0-9]|3[0-1])%.")) then
        return true
    else
        return false
    end
end

-- NTTのHGWの存在を確認
local function check_ntt_hgw()
    local ntturls = {
        "http://192.168.1.1:8888/t/",
        "http://ntt.setup:8888/t/"
    }

    for _, url in ipairs(ntturls) do
        local command = string.format("curl -m 5 --silent --head %s", url)
        local result = sys.call(command)
        if result == 0 then
            return true
        end
    end

    return false
end



-- WAN設定選択リスト --
m = Map("ca_setup", "WAN接続設定", "下記のリストより選んでください。IPoE接続の場合は、ONUに直接つないでから実行してください。")

s = m:section(TypedSection, "ipoe")
s.addremove = false
s.anonymous = true

choice = s:option(ListValue, "wan_setup", "WAN設定")
choice:value("dhcp_auto", "DHCP自動")
choice:value("pppoe_ipv4", "PPPoE接続")
choice:value("ipoe_v6plus", "v6プラス")
choice:value("ipoe_ocnvirtualconnect", "OCNバーチャルコネクト")
choice:value("ipoe_biglobe", "IPv6オプション")
choice:value("ipoe_transix", "transix")
choice:value("ipoe_xpass", "クロスパス")
choice:value("ipoe_v6connect", "v6コネクト")
choice:value("bridge_mode", "ブリッジ・APモード")

msg_text = s:option(DummyValue, "smg_text", "【注意】")
msg_text.default = "元に戻したい場合はハードウェアリセットで初期化してください。"
msg_text:depends("wan_setup", "bridge_mode")

-- PPPoEユーザー名とパスワード入力フォームの追加及び、選択された場合のみ、ユーザー名とパスワード欄を表示
username = s:option(Value, "username", "PPPoE ユーザー名")
password = s:option(Value, "password", "PPPoE パスワード")
password.password = true
username:depends("wan_setup", "pppoe_ipv4")
password:depends("wan_setup", "pppoe_ipv4")


-- mapデータのフォーム表示用
if VNE == "v6プラス" or VNE == "OCNバーチャルコネクト" or VNE == "IPv6オプション" then
    local ipv4_prefix, ipv4_prefixlen, ipv6_prefix, ipv6_prefixlen, ealen, psidlen, offset, ipv6_56, peeraddr = calib.find_ipv4_prefix(wan_ipv6)

        -- IPv6_56
        fipv6_56 = s:option(Value, "ipv6_56", translate("IPv6 Address"))
        if ipv6_56 ~= nil then
            fipv6_56.default = ipv6_56
        else
            fipv6_56.default = "認識できません"
        end
        fipv6_56:depends("wan_setup", "ipoe_v6plus")
        fipv6_56:depends("wan_setup", "ipoe_ocnvirtualconnect")
        fipv6_56:depends("wan_setup", "ipoe_biglobe")

        -- IPV6 Prefix
        fipv6_prefix = s:option(Value, "ipv6_prefix", translate("IPv6 Prefix"))
        if ipv6_prefix ~= nil then
            fipv6_prefix.default = ipv6_prefix
        else
            fipv6_prefix.default = "認識できません"
        end
        fipv6_prefix:depends("wan_setup", "ipoe_v6plus")
        fipv6_prefix:depends("wan_setup", "ipoe_ocnvirtualconnect")
        fipv6_prefix:depends("wan_setup", "ipoe_biglobe")
        
        -- IPV6 Prefix Length
        fipv6_prefixlen = s:option(Value, "ipv6_prefixlen", translate("IPv6 Prefix Length"))
        if ipv6_prefixlen ~= nil then
            fipv6_prefixlen.default = ipv6_prefixlen
        else
            fipv6_prefixlen.default = "認識できません"
        end
        fipv6_prefixlen:depends("wan_setup", "ipoe_v6plus")
        fipv6_prefixlen:depends("wan_setup", "ipoe_ocnvirtualconnect")
        fipv6_prefixlen:depends("wan_setup", "ipoe_biglobe")
        
    
        -- IPV4 Prefix
        fipv4_prefix = s:option(Value, "ipv4_prefix", translate("IPv4 Prefix"))
        if ipv4_prefix ~= nil then
            fipv4_prefix.default = ipv4_prefix
        else
            fipv4_prefix.default = "認識できません"
        end
        fipv4_prefix:depends("wan_setup", "ipoe_v6plus")
        fipv4_prefix:depends("wan_setup", "ipoe_ocnvirtualconnect")
        fipv4_prefix:depends("wan_setup", "ipoe_biglobe")
        
        -- IPV4 Prefix Length
        fipv4_prefixlen = s:option(Value, "ipv4_prefixlen", translate("IPv4 Prefix Length"))
        if ipv4_prefixlen ~= nil then
            fipv4_prefixlen.default = ipv4_prefixlen
        else
            fipv4_prefixlen.default = "認識できません"
        end
        fipv4_prefixlen:depends("wan_setup", "ipoe_v6plus")
        fipv4_prefixlen:depends("wan_setup", "ipoe_ocnvirtualconnect")
        fipv4_prefixlen:depends("wan_setup", "ipoe_biglobe")
      
        -- EA Length
        fealen = s:option(Value, "ealen", translate("EA Length"))
        if ealen ~= nil then
            fealen.default = ealen
        else
            fealen.default = "認識できません"
        end
        fealen:depends("wan_setup", "ipoe_v6plus")
        fealen:depends("wan_setup", "ipoe_ocnvirtualconnect")
        fealen:depends("wan_setup", "ipoe_biglobe")
        
        -- PSID Length
        fpsidlen = s:option(Value, "psidlen", translate("PSID Length"))
        if psidlen ~= nil then
            fpsidlen.default = psidlen
        else
            fpsidlen.default = "認識できません"
        end
        fpsidlen:depends("wan_setup", "ipoe_v6plus")
        fpsidlen:depends("wan_setup", "ipoe_ocnvirtualconnect")
        fpsidlen:depends("wan_setup", "ipoe_biglobe")
        
        -- Offset
        foffset = s:option(Value, "offset", translate("Offset"))
        if offset ~= nil then
            foffset.default = offset
        else
            foffset.default = "認識できません"
        end
        foffset:depends("wan_setup", "ipoe_v6plus")
        foffset:depends("wan_setup", "ipoe_ocnvirtualconnect")
        foffset:depends("wan_setup", "ipoe_biglobe")

        -- Peer Addr
        fpeeraddr = s:option(Value, "peeraddr", translate("Peer Address"))
        if peeraddr ~= nil then
            fpeeraddr.default = peeraddr
        else
            fpeeraddr.default = "認識できません"
        end
        fpeeraddr:depends("wan_setup", "ipoe_v6plus")
        fpeeraddr:depends("wan_setup", "ipoe_ocnvirtualconnect")
        fpeeraddr:depends("wan_setup", "ipoe_biglobe")

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

    os.execute([[sed -i -e 's/mtu:-1280/mtu:-1460/g' /lib/netifd/proto/dslite.sh]])

    -- DS-LiteインターフェースをWANゾーンに追加
    uci:set_list("firewall", "@zone[1]", "network", {"wan", "wan6"})

end

-- map-e v6 plus 接続設定関数
function configure_mape_connection(peeraddr, ipv4_prefix, ipv4_prefixlen, ipv6_prefix, ipv6_prefixlen, ealen, psidlen, offset, ipv6_56)
              
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

    -- WAN settings
    uci:set("network", "wan", "auto", "0")
    
    -- WAN6 settings
    uci:set("network", "wan6", "proto", "dhcpv6")
    uci:set("network", "wan6", "reqaddress", "try")
    uci:set("network", "wan6", "reqprefix", "auto")
    uci:set("network", "wan6", "ip6prefix", ipv6_56 .. "/56")
    
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
        encaplimit = "ignore"
    })

    -- Firewall settings
    uci:delete("firewall", "@zone[1]", "network", "wan")
    uci:set_list("firewall", "@zone[1]", "network", {"wan6", "wanmap"})

end

-- map-e OCN Virtual Connect 接続設定関数
function configure_mape_ocn(peeraddr, ipv4_prefix, ipv4_prefixlen, ipv6_prefix, ipv6_prefixlen, ealen, psidlen, offset, ipv6_56)
      
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

    -- WAN settings
    uci:set("network", "wan", "auto", "0")
    
    -- WAN6RA settings
    uci:section("network", "interface", "map6ra", {
        device = "wan",
        proto = "static",
        ip6gw = ipv6_56 .. "1",
        ip6prefix = ipv6_56 .. "/56",
        ip6addr = ipv6_56 .. "1001"
    })
    
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
        mtu = "1460"
    })


    -- Firewall settings
    uci:delete("firewall", "@zone[1]", "network", "wan")
    uci:set_list("firewall", "@zone[1]", "network", {"wan6", "wanmap", "map6ra"})

end

-- clean wan 関数 dsliteからmapへ戻す可能性があるとき用 --
local function clean_wan_configuration()
    -- 指定された設定が存在するかどうかを確認し、存在する場合は削除する関数
    local function delete_config(config, section, option, value)
        if option then
            uci:delete(config, section, option)
        else
            uci:delete(config, section)
        end
        if value then
            for _, v in ipairs(value) do
                uci:delete(config, section, option, v)
            end
        end
    end

    -- map, dslite, map6ra設定が存在するかチェック
    local mapExists = uci:get("network", "wanmap") or uci:get("network", "map6ra") or uci:get("network", "dslite")

    if mapExists then
        -- 存在する場合、指定された設定を削除
        delete_config("dhcp", "lan", "ndp")
        delete_config("dhcp", "lan", "force")
        delete_config("dhcp", "wan6")
        delete_config("network", "wan", "auto")
        delete_config("network", "wan6", "reqaddress")
        delete_config("network", "wan6", "reqprefix")
        delete_config("network", "wan6", "ip6prefix")
        delete_config("network", "map6ra")
        delete_config("network", "wanmap")
        delete_config("network", "dslite")
        delete_config("firewall", "@zone[1]", "network", {"wanmap", "map6ra"})
    
        -- DHCP関連設定の適用
        uci:set("network", "wan", "proto", "dhcp")
        uci:set("network", "wan6", "proto", "dhcpv6")
        uci:set("dhcp", "lan", "interface", "lan")
        uci:set("dhcp", "lan", "dhcpv6", "server")
        uci:set("dhcp", "lan", "ra", "server")
        uci:set_list("firewall", "@zone[1]", "network", {"wan", "wan6"})
                   
    end
end

-- mapやdsliteの状態から、DHCP自動に戻すためのUCI設定関数 --
local function apply_dhcp_configuration()
    -- 指定された設定が存在するかどうかを確認し、存在する場合は削除する関数
    local function delete_config(config, section, option, value)
        if option then
            uci:delete(config, section, option)
        else
            uci:delete(config, section)
        end
        if value then
            for _, v in ipairs(value) do
                uci:delete(config, section, option, v)
            end
        end
    end

    -- map, dslite, map6ra設定が存在するかチェック
    local mapExists = uci:get("network", "wanmap") or uci:get("network", "map6ra") or uci:get("network", "dslite")

    if mapExists then
        -- 存在する場合、指定された設定を削除
        delete_config("dhcp", "lan", "ndp")
        delete_config("dhcp", "lan", "force")
        delete_config("dhcp", "wan6")
        delete_config("network", "wan", "auto")
        delete_config("network", "wan6", "reqaddress")
        delete_config("network", "wan6", "reqprefix")
        delete_config("network", "wan6", "ip6prefix")
        delete_config("network", "map6ra")
        delete_config("network", "wanmap")
        delete_config("network", "dslite")
        delete_config("firewall", "@zone[1]", "network", {"wanmap", "map6ra"})
    
        -- DHCP関連設定の適用
        uci:set("network", "wan", "proto", "dhcp")
        uci:set("network", "wan6", "proto", "dhcpv6")
        uci:set("dhcp", "lan", "interface", "lan")
        uci:set("dhcp", "lan", "dhcpv6", "server")
        uci:set("dhcp", "lan", "ra", "server")
        uci:set_list("firewall", "@zone[1]", "network", {"wan", "wan6"})
    
    end
end





-- LuciのSAVE＆APPLYボタンが押された時の動作
function choice.write(self, section, value)
    
    if value == "pppoe_ipv4" then        
        -- PPPoE設定を適用
        clean_wan_configuration()
         uci:section("network", "interface", "wan", {
            proto = "pppoe",
            username = username:formvalue(section),
            password = password:formvalue(section),
        })

              
        -- WAN settings
        uci:set("network", "wan", "auto", "1")
        uci:set("network", "wan6", "auto", "0")     
        uci:set_list("firewall", "@zone[1]", "network", {"wan"})     

    elseif value == "dhcp_auto" then
        -- DHCP自動であるべきなので、関係ないWAN設定の確認と削除、DHCP自動に戻す設定動作
        apply_dhcp_configuration()
    
    elseif value == "ipoe_v6plus" then
        -- v6プラス
        clean_wan_configuration()
        local ipv4_prefix = fipv4_prefix:formvalue(section)
        local ipv4_prefixlen = fipv4_prefixlen:formvalue(section)
        local ipv6_prefix = fipv6_prefix:formvalue(section)
        local ipv6_prefixlen = fipv6_prefixlen:formvalue(section)
        local ealen = fealen:formvalue(section)
        local psidlen = fpsidlen:formvalue(section)
        local offset = foffset:formvalue(section)
        local ipv6_56 = fipv6_56:formvalue(section)
        local peeraddr = fpeeraddr:formvalue(section)

        configure_mape_connection(peeraddr, ipv4_prefix, ipv4_prefixlen, ipv6_prefix, ipv6_prefixlen, ealen, psidlen, offset, ipv6_56)
    
    elseif value == "ipoe_ocnvirtualconnect" then
        -- OCNバーチャルコネクト
        clean_wan_configuration()
        local ipv4_prefix = fipv4_prefix:formvalue(section)
        local ipv4_prefixlen = fipv4_prefixlen:formvalue(section)
        local ipv6_prefix = fipv6_prefix:formvalue(section)
        local ipv6_prefixlen = fipv6_prefixlen:formvalue(section)
        local ealen = fealen:formvalue(section)
        local psidlen = fpsidlen:formvalue(section)
        local offset = foffset:formvalue(section)
        local ipv6_56 = fipv6_56:formvalue(section)
        local peeraddr = fpeeraddr:formvalue(section)

        configure_mape_ocn(peeraddr, ipv4_prefix, ipv4_prefixlen, ipv6_prefix, ipv6_prefixlen, ealen, psidlen, offset, ipv6_56)
    
    elseif value == "ipoe_biglobe" then
        -- BIGLOBE IPv6オプション
        clean_wan_configuration()
        local ipv4_prefix = fipv4_prefix:formvalue(section)
        local ipv4_prefixlen = fipv4_prefixlen:formvalue(section)
        local ipv6_prefix = fipv6_prefix:formvalue(section)
        local ipv6_prefixlen = fipv6_prefixlen:formvalue(section)
        local ealen = fealen:formvalue(section)
        local psidlen = fpsidlen:formvalue(section)
        local offset = foffset:formvalue(section)
        local ipv6_56 = fipv6_56:formvalue(section)
        local peeraddr = fpeeraddr:formvalue(section)

        configure_mape_connection(peeraddr, ipv4_prefix, ipv4_prefixlen, ipv6_prefix, ipv6_prefixlen, ealen, psidlen, offset, ipv6_56)
    
    elseif value == "ipoe_transix" then
            -- transix (ds-lite)
            clean_wan_configuration()
            gw_aftr = m.uci:get("ca_setup", "ipoe_transix", "gw_aftr")
            configure_dslite_connection(gw_aftr)
    
    elseif value == "ipoe_xpass" then
            -- クロスパス (ds-lite)
            clean_wan_configuration()
            gw_aftr = m.uci:get("ca_setup", "ipoe_xpass", "gw_aftr")
            configure_dslite_connection(gw_aftr)
        
    elseif value == "ipoe_v6connect" then
            -- v6コネクト
            clean_wan_configuration()
            gw_aftr = m.uci:get("ca_setup", "ipoe_v6connect", "gw_aftr")
            configure_dslite_connection(gw_aftr)
        
    elseif value == "bridge_mode" then
            -- ブリッジモード設定の適用
            clean_wan_configuration()

            -- /etc/config/dhcp の設定変更
            uci:delete("dhcp", "lan", "ra_slaac")
            uci:set("dhcp", "lan", "ignore", "1")
            
            -- /etc/config/network の設定変更
            uci:delete("network", "lan", "ipaddr")
            uci:delete("network", "lan", "netmask")
            uci:delete("network", "lan", "ip6assign")
            uci:set("network", "lan", "proto", "dhcp")
    
            -- /etc/config/dhcp の設定変更
            uci:delete("dhcp", "wan")

            uci:delete("network", "wan")
            uci:delete("network", "wan6")
        
            -- wanインターフェースをbr-lanに接続
            uci:set("network", "@device[0]", "ports", "lan1 lan2 lan3 lan4 wan")
        
            -- ホスト名を"WifiAP"に変更する
            uci:set("system", "@system[0]", "hostname", "WifiAP")

    end
end

function m.on_after_commit(self)
    -- LuciのSAVE＆APPLYボタンで設定の反映およびネットワークサービスを再起動する
end

return m
