local http = require "luci.http"
local jsonc = require "luci.jsonc"

local m, s, o

m = SimpleForm("fetchdata", "自動データ取得")
m.reset = false
m.submit = false

function fetch_data()
    local url = "https://api.enabler.ne.jp/6823228689437e773f260662947d6239/get_rules"
    local response, code = http.request(url)
    if code ~= 200 then
        return nil, "HTTPリクエストが失敗しました。ステータスコード: " .. tostring(code)
    end

    -- JSONP応答からJSON部分を抽出（API応答がJSONP形式と仮定）
    local jsonStr = response:match("%((.+)%)")
    if not jsonStr then
        return nil, "JSONP応答からJSONを抽出できませんでした。"
    end

    local status, data = pcall(jsonc.parse, jsonStr)
    if not status then
        return nil, "JSONの解析に失敗しました。"
    end

    return data, nil
end

local data, err = fetch_data()

if data then
    m.message = "データの取得に成功しました: <pre>" .. jsonc.stringify(data, true) .. "</pre>"
else
    m.message = "データの取得に失敗しました: " .. err
end

return m
