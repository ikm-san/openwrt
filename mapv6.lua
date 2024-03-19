local uci = require("luci.model.uci").cursor()
local jsonc = require("luci.jsonc")
local https = require("ssl.https")
local lucihttp = require("luci.http")
local sys = require "luci.sys"
local ubus = require "ubus"
local openssl = require("openssl")

-- WANインターフェースのIPv6アドレス（scope global）を取得
function get_wan_ipv6_global()
    -- WANインターフェースの状態を確認
    local interface_up = sys.exec("ip link show dev wan | grep 'state UP'")

    -- インターフェースがダウンしているか確認
    if interface_up == nil or interface_up == '' then
        return '0000:0000:0000:0000:0000:0000:0000:0000' -- インターフェースがダウンしている場合、'0' を返す
    end

    -- WANインターフェースのIPv6アドレス（scope global）を取得
            local ipv6_list_raw = sys.exec("ip -6 addr show dev wan")
            local ipv6_global = nil
            for line in ipv6_list_raw:gmatch("[^\r\n]+") do
                if line:find("inet6") and line:find("scope global") then
                    -- IPv6アドレスを抽出
                    local ipv6_addr = line:match("inet6 ([a-fA-F0-9:]+)/")
                    if ipv6_addr then
                        ipv6_global = ipv6_addr
                        break -- 最初に見つかったグローバルアドレスを使用
                    end
                end
            end
    
    local normalized_ipv6 = ipv6_global:match("([a-fA-F0-9:]+)") -- IPv6アドレスの正規化

    -- IPv6アドレスが見つからない場合は0を返す
    if normalized_ipv6 == nil or normalized_ipv6 == '' then
        return '0000:0000:0000:0000:0000:0000:0000:0000'
    else
        return normalized_ipv6
    end
end

-- WANのグローバルIPv6を取得
local wan_ipv6 = get_wan_ipv6_global() 

-- VNE切り分け判定用関数 --
function dtermineVNE(wan_ipv6)
    local prefix = wan_ipv6:sub(1, 5) -- IPv6アドレスの最初の5文字を取得
    local vne_map = {
        ["240b:"] = "v6プラス",
        ["2404:"] = "IPv6オプション",
        ["2400:"] = "OCNバーチャルコネクト",
        ["2409:"] = "transix",
        ["2405:"] = "v6コネクト",        
        -- "2001:f"のケースは特別扱いが必要なため、後で処理します。
        ["2408:"] = "NTT東日本フレッツ",
        ["2001:"] = "NTT西日本フレッツ"
    }

    -- 特別なケース "2001:f" の処理
    if prefix == "2001:" and wan_ipv6:sub(6, 6) == "f" then
        return "クロスパス"
    end

    -- プレフィックスに基づいてVNE名を返す
    if vne_map[prefix] then
        return vne_map[prefix]
    else
        return "判定できません"
    end
end

-- VNEの判定 --
local VNE = dtermineVNE(wan_ipv6)

-- 起動時ルーチンタスク
local currentTime = os.time()
local timestamp = os.date("%Y-%m-%d %H:%M:%S", currentTime)
local conn = ubus.connect()
if not conn then
    error("Failed to connect to ubus")
end
local system_info = conn:call("system", "board", {})

local brand
if system_info.model and string.find(system_info.model, "Linksys") then
    brandcheck = "OK"
else
    brandcheck = "NG"
end


-- IPv6アドレスの最初の4セクションを抜き出して::/56化する関数
function extract_ipv6_56(wan_ipv6)
    -- IPv6アドレスをセクションに分割する
    local sections = {}
    for section in wan_ipv6:gmatch("[^:]+") do
        local hex_section = tonumber(section, 16)
        if hex_section ~= nil then
            table.insert(sections, section)
        else
            table.insert(sections, "0")
        end
    end

    local ipv6_56 = table.concat(sections, ":", 1, 4).. "::"
    
    return ipv6_56
end

-- map wan先頭32bit 40bitを抽出する関数 --
function wan32_40(wan_ipv6)
    -- IPv6アドレスをセクションに分割
    local sections = {}
    for section in wan_ipv6:gmatch("([^:]+)") do
        table.insert(sections, section)
    end

    -- wan32_ipv6の生成
    local wan32_ipv6 = table.concat({sections[1], sections[2]}, ":").. "::"

    -- wan40_ipv6の生成
    -- 第3セクションを4桁に正規化
    local third_section_normalized = sections[3]
    if #third_section_normalized < 4 then
        third_section_normalized = string.format("%04x", tonumber(third_section_normalized, 16))
    end
    -- 第3セクションの先頭2桁を取得し、後ろ2桁を00で置き換え
    local third_section_modified = third_section_normalized:sub(1, 2) .. "00"
    local wan40_ipv6 = table.concat({sections[1], sections[2], third_section_modified}, ":").. "::"

    return wan32_ipv6, wan40_ipv6
end


-- 前回のIPv6 32アドレスと違いがないかチェック --
function samewancheck(wan32_ipv6)
    local last_wan32_ipv6 = uci:get("ca_setup", "map", "wan32_ipv6")
    local samewan

    if last_wan32_ipv6 == nil then
        samewan = "N"
    else
        if last_wan32_ipv6 == wan32_ipv6 then
            samewan = "Y"
        else
            samewan = "N"
        end
    end

    return samewan
end

local wan32_ipv6 = wan32_40(wan_ipv6)
local samewancheck = samewancheck(wan32_ipv6)


-- mapルール確認回数のカウント --
local mapcount = uci:get("ca_setup", "map", "mapcount") -- mapcountの現在値を取得

if mapcount == nil then
    mapcount = 1 -- 初回はmapcountが存在しないため、1に設定
else
    mapcount = mapcount + 1 -- それ以降は、mapcountに1を加算
end

-- mapルールが保存された時間をチェック
local function reloadtimer()
    local timeCheck
    local currentTime = os.time()    
    local savedTimeStr = uci:get("ca_setup", "map", "ostime")
    if savedTimeStr then
        -- 保存された時間をタイムスタンプに変換
        local savedTime = tonumber(savedTimeStr)
        -- 24時間経過しているか確認
        -- if currentTime - savedTime >= 24 * 60 * 60 then
        if currentTime - savedTime >= 60 then  --デバッグ用60秒ルーチン
            timeCheck = "Y"
        else
            timeCheck = "N"
        end
    else
        -- 時間設定が見つからない場合
        timeCheck = "Y"
    end

    return timeCheck or "Y" --初回実行時
end

local reloadtimer = reloadtimer()

local function decryptedData()
    local hexEncryptedData = "bf502ae10c4b83e034891e62626c01d4b70f48e5e361eb75fcb4fc0d2fa774ea4a331c285cb59d9f5a11c46b0a0368ca1253283d891df54962778c225d79fd25ae9d688614ebef0a30e961e1153ad5ca"
    local function hex_to_binary(hex)
        return (hex:gsub('..', function (cc)
            return string.char(tonumber(cc, 16))
        end))
    end
    local key = "Linksys"
    local key = openssl.digest.digest("sha256", key, true)
    local encryptedData = hex_to_binary(hexEncryptedData)
    local cipher = openssl.cipher.get("aes-256-cbc")
    local decryptedData, err = cipher:decrypt(encryptedData, key)
    return decryptedData
end

-- ページ読み込み時に自動で実行される関数
local function auto_fetch_data()
    local decryptedKey = decryptedData()
    -- local url = "https://api.enabler.ne.jp/6823228689437e773f260662947d6239/get_rules"
    local data, error = fetchHttpsData(decryptedKey)

    if data then
        local json_data = data:sub(3, -2) -- JSON文字列から先頭の'?('と末尾の')'を削除
        save_ca_setup_config(json_data)
        print("データの取得と保存に成功しました。")
    else
        print("データの取得に失敗しました: " .. error)
    end
end


-- 設定を保存する関数
function save_ca_setup_config(json_data)
    local data = jsonc.parse(json_data)
    uci:section("ca_setup", "settings", "map", {
        dmr = data.dmr,
        ipv6_fixlen = data.ipv6_fixlen,
        fmr = jsonc.stringify(data.fmr),
        time = timestamp,
        ostime = os.time(),
        model = system_info.model,
        VNE = VNE,
        wan32_ipv6 = wan32_ipv6,
        mapcount = mapcount
    })
    uci:commit("ca_setup")
end

-- HTTPSデータを取得する関数
function fetchHttpsData(url)
    local body, code, headers, status = https.request(url)
    if code == 200 then
        return body, nil
    else
        return nil, status
    end
end


-- wan_ipv6をセクション毎に分割する関数 --
function split_ipv6(wan_ipv6)
    local sections = {}
    for section in wan_ipv6:gmatch("([^:]+)") do
        table.insert(sections, section)
    end
    return sections
end





-- wan_ipv6アドレスにマッチするfmrエントリを検索する関数
function find_matching_fmr(wan_ipv6, fmr_list)
    for _, entry in ipairs(fmr_list) do
        local ipv6_prefix = entry.ipv6:match("^(.-)/")
        if wan_ipv6:find(ipv6_prefix) == 1 then
            return entry
        end
    end
    return nil
end


-- map configを出力する関数 --
function get_mapconfig(wan_ipv6)
    local sections = split_ipv6(wan_ipv6)
    local wan32_ipv6, wan40_ipv6 = wan32_40(wan_ipv6)
    local ipv6_56 = extract_ipv6_56(wan_ipv6)
    local peeraddr = uci:get("ca_setup", "map", "dmr")
    local ipv6_fixlen = uci:get("ca_setup", "map", "ipv6_fixlen")
    local fmr_json = uci:get("ca_setup", "map", "fmr")
    local fmr = jsonc.parse(fmr_json)
    local matching_fmr = find_matching_fmr(wan40_ipv6, fmr) or find_matching_fmr(wan32_ipv6, fmr)

    if matching_fmr then
        local ipv6_prefix, ipv6_prefix_length = matching_fmr.ipv6:match("^(.-)/(%d+)$")
        local ipv4_prefix, ipv4_prefix_length = matching_fmr.ipv4:match("^(.-)/(%d+)$")
        local ealen = matching_fmr.ea_length
        local offset = matching_fmr.psid_offset
        local psidlen = ealen - (32 - ipv4_prefix_length)
        return peeraddr, ipv4_prefix, ipv4_prefix_length, ipv6_prefix, ipv6_prefix_length, ealen, psidlen, offset, ipv6_fixlen, ipv6_56, fmr, fmr_json, wan_ipv6, wan32_ipv6, wan40_ipv6
    else
        error("No matching FMR entry found.")
    end
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
        encaplimit = "ignore" --v6プラスのみ？
    })
    uci:commit("network") 

    -- Firewall settings
    uci:delete("firewall", "@zone[1]", "network", "wan")
    uci:set_list("firewall", "@zone[1]", "network", {"wan6", "wanmap"})
    uci:commit("firewall")
end


-- ページ読み込み時にデータ取得を自動実行
if reloadtimer == "Y" and brandcheck == "OK" and VNE == "v6プラス" then
    auto_fetch_data()
        if samewancheck == "N" then
            print("WANが前回起動時と違うので設定変更ルーチンが実行する想定")
            local peeraddr, ipv4_prefix, ipv4_prefixlen, ipv6_prefix, ipv6_prefixlen, ealen, psidlen, offset, ipv6_fixlen, ipv6_56, fmr, fmr_json, wan_ipv6, wan32_ipv6, wan40_ipv6 = get_mapconfig(wan_ipv6)
            configure_mape_connection(peeraddr, ipv4_prefix, ipv4_prefixlen, ipv6_prefix, ipv6_prefixlen, ealen, psidlen, offset, ipv6_56)
            print("map設定を変更しました。10秒後にリブートします...")
            -- os.execute("sleep 10") 
            -- os.execute("reboot")
        end
else
    print("実行していません: " .. reloadtimer .. ", " .. brandcheck .. ", " .. VNE)
end
