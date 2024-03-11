local uci = require("luci.model.uci").cursor()
local json = require("luci.jsonc")
local https = require("ssl.https")
local lucihttp = require("luci.http")

-- フォームとセクションの定義
local f, s, o

f = SimpleForm("fetchdata", translate("データ取得"))
s = f:section(SimpleSection, nil, translate("下のボタンをクリックしてデータを取得してください。"))

-- 実行ボタン
o = s:option(Button, "_fetch", translate("データ取得"))
o.inputstyle = "apply"

function o.write(self, section)
    local url = "https://api.enabler.ne.jp/6823228689437e773f260662947d6239/get_rules"
    local data, error = fetchHttpsData(url)

    if data then
        local json_data = data:sub(3, -2) -- JSON文字列から先頭の'?('と末尾の')'を削除
        save_ca_setup_config(json_data)
        f.message = translate("データの取得と保存に成功しました。")
        -- 処理が成功したら、同じページにリダイレクト
        lucihttp.redirect(lucihttp.getenv("REQUEST_URI"))
    else
        f.errmessage = translate("データの取得に失敗しました: ") .. error
    end
end

function save_ca_setup_config(json_data)
    local data = json.parse(json_data)
    uci:section("ca_setup", "settings", nil, {
        dmr = data.dmr,
        id = data.id,
        ipv6_fixlen = data.ipv6_fixlen,
        fmr = json.stringify(data.fmr)
    })
    uci:commit("ca_setup")
end

function fetchHttpsData(url)
    local body, code, headers, status = https.request(url)
    if code == 200 then
        return body, nil
    else
        return nil, status
    end
end

return f
