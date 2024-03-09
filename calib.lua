local fs = require "nixio.fs"
local sys = require "luci.sys"
local uci = require "luci.model.uci".cursor()
local json = require("luci.jsonc")
local io = require("io")

local M = {}

-- WANインターフェースのIPv6アドレス（scope global）を取得
function M.get_wan_ipv6_global()
    local ipv6_global = sys.exec("ip -6 addr show dev wan | awk '/inet6/ && /scope global/ {print $2}' | cut -d'/' -f1 | head -n 1")
    local normalized_ipv6 = ipv6_global:match("([a-fA-F0-9:]+)") -- IPv6アドレスの正規化

    -- IPv6アドレスが見つからない場合は0を返す
    if normalized_ipv6 == nil or normalized_ipv6 == '' then
        return '0'
    else
        return normalized_ipv6
    end
end

function M.fetchRules()
    local command = "curl -s 'https://api.enabler.ne.jp/6823228689437e773f260662947d6239/get_rules'"
    local handle = io.popen(command, "r")
    local result = handle:read("*a")
    handle:close()
    
    -- JSONP形式のレスポンスからJSON部分のみを抽出
    local jsonStr = result:match("%((.+)%)")
    if not jsonStr then
        error("JSONPからJSONを抽出できませんでした。")
    end
    
    local status, map_rule = pcall(json.parse, jsonStr)
    if not status then
        error("JSONの解析に失敗しました。")
    end

    return map_rule
end

-- basic map-e conversion table based on http://ipv4.web.fc2.com/map-e.html
function M.getRulePrefix31()
    local ruleprefix31 = {
        ["240b0010"] = "106.72",
        ["240b0012"] = "14.8",
        ["240b0250"] = "14.10",
        ["240b0252"] = "14.12",
        ["24047a80"] = "133.200",
        ["24047a84"] = "133.206"
    }
    return ruleprefix31
end

return M
