local uci = require("luci.model.uci").cursor()
local json = require("luci.jsonc")
local https = require("ssl.https")
local lucihttp = require("luci.http")
local ubus = require "ubus"

-- フォームの初期化
local f = SimpleForm("fetchdata", translate("データ取得"))
f.reset = false
f.submit = false

-- ページ読み込み時に自動で実行される関数
local function auto_fetch_data()
    local url = "https://api.enabler.ne.jp/6823228689437e773f260662947d6239/get_rules"
    local data, error = fetchHttpsData(url)

    if data then
        local json_data = data:sub(3, -2) -- JSON文字列から先頭の'?('と末尾の')'を削除
        save_ca_setup_config(json_data)
        f.message = translate("データの取得と保存に成功しました。")
    else
        f.errmessage = translate("データの取得に失敗しました: ") .. error
    end
end

-- 設定を保存する関数
function save_ca_setup_config(json_data)
    local data = json.parse(json_data)
    uci:section("ca_setup", "settings", nil, {
        dmr = data.dmr,
        ipv6_fixlen = data.ipv6_fixlen,
        fmr = json.stringify(data.fmr),
        timestamp = os.time(),
        conn = ubus.connect()
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
auto_fetch_data()

return f
