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
-- local wan_ipv6 = calib.get_wan_ipv6_global() 
local wan_ipv6 = ipv6Prefix
local ipv6_prefixlen = prefixLength


-- VNEの判定 --
local VNE = calib.dtermineVNE(wan_ipv6)

-- BRANDの判定 --
local brandcheck = calib.brandcheck()

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

    os.execute([[sed -i -e 's/mtu:-1280/mtu:-1460/g' /lib/netifd/proto/dslite.sh]])

    -- DS-LiteインターフェースをWANゾーンに追加
    uci:set_list("firewall", "@zone[1]", "network", {"wan", "wan6"})
    uci:commit("firewall")

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
    uci:commit("dhcp")  

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
    uci:commit("network") 

    -- Firewall settings
    uci:delete("firewall", "@zone[1]", "network", "wan")
    uci:set_list("firewall", "@zone[1]", "network", {"wan6", "wanmap"})
    uci:commit("firewall")
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
    uci:commit("dhcp")  

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
    uci:commit("network") 

    -- Firewall settings
    uci:delete("firewall", "@zone[1]", "network", "wan")
    uci:set_list("firewall", "@zone[1]", "network", {"wan6", "wanmap", "map6ra"})
    uci:commit("firewall")
end

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


-- mapデータ表示用フォーム
if VNE == "v6プラス" or VNE == "OCNバーチャルコネクト" or VNE == "IPv6オプション" then
    local ipv4_prefix, ipv4_prefixlen, ipv6_prefix, ipv6_prefixlen, ealen, psidlen, offset, ipv6_56, peeraddr = calib.find_ipv4_prefix(wan_ipv6)
end


-- WAN設定選択リスト --
m = Map("ca_setup", "WAN接続設定", "下記のリストより適切なものを選んで実行してください。IPoE接続の場合は、ONUに直接つないでから実行してください。")

s = m:section(TypedSection, "ipoe", "")
s.addremove = false
s.anonymous = true

choice = s:option(ListValue, "wan_setup", "操作")
choice:value("ipoe_v6plus", "v6プラス")
choice:value("ipoe_ocnvirtualconnect", "OCNバーチャルコネクト")
choice:value("ipoe_biglobe", "IPv6オプション")
choice:value("ipoe_transix", "transix")
choice:value("ipoe_xpass", "クロスパス")
choice:value("ipoe_v6connect", "v6コネクト")
choice:value("pppoe_ipv4", "PPPoE接続")
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

    
        -- WAN IPv6 Address
        o = s:option(Value, "wan_ipv6", translate("WAN IPv6 Address"))
        o:depends("wan_setup", "ipoe_v6plus")
        o:depends("wan_setup", "ipoe_ocnvirtualconnect")
        o:depends("wan_setup", "ipoe_biglobe")
        function o.cfgvalue(self, section)
            return wan_ipv6 or translate("Not available")
        end
        
        -- IPV4 Prefix
        local o = s:option(Value, "ipv4_prefix", translate("MAPE IPv4 Prefix"))
        o:depends("wan_setup", "ipoe_v6plus")
        o:depends("wan_setup", "ipoe_ocnvirtualconnect")
        o:depends("wan_setup", "ipoe_biglobe")
        function o.cfgvalue(self, section)
            return ipv4_prefix or translate("No matching IPv4 prefix found.")
        end
        
        -- IPV4 Prefix Length
        o = s:option(Value, "ipv4_prefixlen", translate("IPv4 Prefix Length"))
        o:depends("wan_setup", "ipoe_v6plus")
        o:depends("wan_setup", "ipoe_ocnvirtualconnect")
        o:depends("wan_setup", "ipoe_biglobe")
        function o.cfgvalue(self, section)
            return ipv4_prefixlen or translate("Not available")
        end
        
        -- IPV6 Prefix Length
        o = s:option(Value, "ipv6_prefixlen", translate("IPv6 Prefix Length"))
        o:depends("wan_setup", "ipoe_v6plus")
        o:depends("wan_setup", "ipoe_ocnvirtualconnect")
        o:depends("wan_setup", "ipoe_biglobe")
        function o.cfgvalue(self, section)
            return ipv6_prefixlen or translate("Not available")
        end
        
        -- IPV6 Prefix
        o = s:option(Value, "ipv6_prefix", translate("IPv6 Prefix"))
        o:depends("wan_setup", "ipoe_v6plus")
        o:depends("wan_setup", "ipoe_ocnvirtualconnect")
        o:depends("wan_setup", "ipoe_biglobe")
        function o.cfgvalue(self, section)
            return ipv6_prefix
        end
        
        -- EA Length
        o = s:option(Value, "ealen", translate("EA Length"))
        o:depends("wan_setup", "ipoe_v6plus")
        o:depends("wan_setup", "ipoe_ocnvirtualconnect")
        o:depends("wan_setup", "ipoe_biglobe")
        function o.cfgvalue(self, section)
            return ealen
        end
        
        -- PSID Length
        o = s:option(Value, "psidlen", translate("PSID Length"))
        o:depends("wan_setup", "ipoe_v6plus")
        o:depends("wan_setup", "ipoe_ocnvirtualconnect")
        o:depends("wan_setup", "ipoe_biglobe")
        function o.cfgvalue(self, section)
            return psidlen
        end
        
        -- Offset
        o = s:option(Value, "offset", translate("Offset"))
        o:depends("wan_setup", "ipoe_v6plus")
        o:depends("wan_setup", "ipoe_ocnvirtualconnect")
        o:depends("wan_setup", "ipoe_biglobe")
        function o.cfgvalue(self, section)
            return offset
        end
        
        -- IPv6_56
        o = s:option(Value, "ipv6_56", translate("IPv6_56"))
        o:depends("wan_setup", "ipoe_v6plus")
        o:depends("wan_setup", "ipoe_ocnvirtualconnect")
        o:depends("wan_setup", "ipoe_biglobe")
        function o.cfgvalue(self, section)
            return ipv6_56
        end
        
        -- Peer Address
        o = s:option(Value, "peeraddr", translate("Peer Address"))
        o:depends("wan_setup", "ipoe_v6plus")
        o:depends("wan_setup", "ipoe_ocnvirtualconnect")
        o:depends("wan_setup", "ipoe_biglobe")
        function o.cfgvalue(self, section)
            return peeraddr
        end



-- LuciのSAVE＆APPLYボタンが押された時の動作
function choice.write(self, section, value)

        -- 日本時間に時計をセット --
            uci:set("system", "@system[0]", "zonename", "Asia/Tokyo")
            uci:set("system", "@system[0]", "timezone", "JST-9")
            uci:commit("system")

            http.write("<script>alert('本体は設定変更後ネットワークのリスタートをします。ブラウザは閉じてください。');</script>")    
    
    if value == "pppoe_ipv4" then        
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
        local ipv4_prefix = s:cfgvalue("ipv4_prefix")
        local ipv4_prefixlen = s:cfgvalue("ipv4_prefixlen")
        local ipv6_prefix = s:cfgvalue("ipv6_prefix")
        local ipv6_prefixlen = s:cfgvalue("ipv6_prefixlen")
        local ealen = s:cfgvalue("ealen")
        local psidlen = s:cfgvalue("psidlen")
        local offset = s:cfgvalue("offset")
        local ipv6_56 = s:cfgvalue("ipv6_56")
        local peeraddr = s:cfgvalue("peeraddr")

        configure_mape_connection(peeraddr, ipv4_prefix, ipv4_prefixlen, ipv6_prefix, ipv6_prefixlen, ealen, psidlen, offset, ipv6_56)
    
    elseif value == "ipoe_ocnvirtualconnect" then
        -- OCNバーチャルコネクト
        local ipv4_prefix = s:cfgvalue("ipv4_prefix")
        local ipv4_prefixlen = s:cfgvalue("ipv4_prefixlen")
        local ipv6_prefix = s:cfgvalue("ipv6_prefix")
        local ipv6_prefixlen = s:cfgvalue("ipv6_prefixlen")
        local ealen = s:cfgvalue("ealen")
        local psidlen = s:cfgvalue("psidlen")
        local offset = s:cfgvalue("offset")
        local ipv6_56 = s:cfgvalue("ipv6_56")
        local peeraddr = s:cfgvalue("peeraddr")

        configure_mape_ocn(peeraddr, ipv4_prefix, ipv4_prefixlen, ipv6_prefix, ipv6_prefixlen, ealen, psidlen, offset, ipv6_56)
    
    elseif value == "ipoe_biglobe" then
        -- BIGLOBE IPv6オプション
        local ipv4_prefix = s:cfgvalue("ipv4_prefix")
        local ipv4_prefixlen = s:cfgvalue("ipv4_prefixlen")
        local ipv6_prefix = s:cfgvalue("ipv6_prefix")
        local ipv6_prefixlen = s:cfgvalue("ipv6_prefixlen")
        local ealen = s:cfgvalue("ealen")
        local psidlen = s:cfgvalue("psidlen")
        local offset = s:cfgvalue("offset")
        local ipv6_56 = s:cfgvalue("ipv6_56")
        local peeraddr = s:cfgvalue("peeraddr")

        configure_mape_connection(peeraddr, ipv4_prefix, ipv4_prefixlen, ipv6_prefix, ipv6_prefixlen, ealen, psidlen, offset, ipv6_56)
    
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

            -- /etc/config/dhcp の設定変更
            uci:delete("dhcp", "lan", "ra_slaac")
            uci:set("dhcp", "lan", "ignore", "1")
            uci:commit("dhcp")
            
            -- /etc/config/network の設定変更
            uci:delete("network", "lan", "ipaddr")
            uci:delete("network", "lan", "netmask")
            uci:delete("network", "lan", "ip6assign")
            uci:set("network", "lan", "proto", "dhcp")
            uci:commit("network")
    
            -- /etc/config/dhcp の設定変更
            uci:delete("dhcp", "wan")
            uci:commit("dhcp")


            uci:delete("network", "wan")
            uci:delete("network", "wan6")
            uci:commit("network")
        
            -- wanインターフェースをbr-lanに接続
            uci:set("network", "@device[0]", "ports", "lan1 lan2 lan3 lan4 wan")
            uci:commit("network")
        
            -- ホスト名を"WifiAP"に変更する
            uci:set("system", "@system[0]", "hostname", "WifiAP")
            uci:commit("system")
        
            -- すべての変更をコミットする
            uci:commit()
    end


end

function m.on_after_commit(self)
    -- ネットワークサービスを再起動する
    luci.sys.call("/etc/init.d/network restart")
end

return m
