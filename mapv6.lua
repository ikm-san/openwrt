local uci = require("luci.model.uci").cursor()
local json = require("luci.jsonc")
local https = require("ssl.https")
local lucihttp = require("luci.http")
local sys = require "luci.sys"
local ubus = require "ubus"

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
        if currentTime - savedTime >= 24 * 60 * 60 then
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


-- ページ読み込み時に自動で実行される関数
local function auto_fetch_data()
    local url = "https://api.enabler.ne.jp/6823228689437e773f260662947d6239/get_rules"
    local data, error = fetchHttpsData(url)

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
    local data = json.parse(json_data)
    uci:section("ca_setup", "settings", "map", {
        dmr = data.dmr,
        ipv6_fixlen = data.ipv6_fixlen,
        fmr = json.stringify(data.fmr),
        time = timestamp,
        ostime = os.time(),
        model = system_info.model,
        VNE = VNE,
        last_ipv6 = wan_ipv6,
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

-- ページ読み込み時にデータ取得を自動実行
if reloadtimer == "Y" and brandcheck == "OK" and VNE == "v6プラス" then
    auto_fetch_data()
else
    print("実行していません: " .. reloadtimer .. ", " .. brandcheck .. ", " .. VNE)
end
