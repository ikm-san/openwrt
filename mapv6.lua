local uci = require("luci.model.uci").cursor()
local json = require("luci.jsonc")
local https = require("ssl.https")
local lucihttp = require("luci.http")
local sys = require "luci.sys"
local ubus = require "ubus"
local calib = require "calib"


-- フォームの初期化
local f = SimpleForm("fetchdata", "データ取得")
f.reset = false
f.submit = false

-- WANのグローバルIPv6を取得
local wan_ipv6 = calib.get_wan_ipv6_global() 

-- VNEの判定 --
local VNE = calib.dtermineVNE(wan_ipv6)

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
        f.message = "データの取得と保存に成功しました。"
    else
        f.errmessage = "データの取得に失敗しました: " .. error
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
        VNE = VNE
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
    f.errmessage = "実行していません" .. reloadtimer .. brandcheck .. VNE
end

return f
