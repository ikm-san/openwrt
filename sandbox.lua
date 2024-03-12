local uci = require("luci.model.uci").cursor()
local jsonc = require("luci.jsonc")
local calib = require "calib" 

local m, s

m = SimpleForm("ca_setup", translate("CA Setup Configuration"))
m.reset = false
m.submit = false

s = m:section(SimpleSection, translate("Settings"))


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
        fmr = json.stringify(data.fmr)
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



-- fmrの読み込みと解析
local fmr_json = uci:get("ca_setup", "@settings[0]", "fmr")
local fmr = jsonc.parse(fmr_json)


-- map configを出力する関数 --
function get_mapconfig()
    local wan_ipv6 = calib.get_wan_ipv6_global()
    local sections = calib.split_ipv6(wan_ipv6)
    local wan32_ipv6, wan40_ipv6 = calib.generate_ipv6_prefixes(sections)
    local peeraddr = uci:get("ca_setup", "@settings[0]", "dmr")
    local ipv6_fixlen = uci:get("ca_setup", "@settings[0]", "ipv6_fixlen")
    -- local fmr_json = uci:get("ca_setup", "@settings[0]", "fmr")
    -- local fmr = jsonc.parse(fmr_json)
    local matching_fmr = calib.find_matching_fmr(wan40_ipv6, fmr) or calib.find_matching_fmr(wan32_ipv6, fmr)

    if matching_fmr then
        local ipv6_prefix, ipv6_prefix_length = matching_fmr.ipv6:match("^(.-)/(%d+)$")
        local ipv4_prefix, ipv4_prefix_length = matching_fmr.ipv4:match("^(.-)/(%d+)$")
        local ealen = matching_fmr.ea_length
        local offset = matching_fmr.psid_offset
        local psidlen = ealen - (32 - ipv4_prefix_lenth)
        return peeraddr, ipv4_prefix, ipv4_prefix_length, ipv6_prefix, ipv6_prefix_length, ealen, psidlen, offset
    else
        error("No matching FMR entry found.")
    end
end


local peeraddr, ipv4_prefix, ipv4_prefixlen, ipv6_prefix, ipv6_prefixlen, ealen, psidlen, offset = get_mapconfig()


-- 該当するfmrエントリの情報を出力

    s:option(DummyValue, "_peeraddr", translate("peeraddr")).value = peeraddr
    s:option(DummyValue, "_ipv6_fixlen", translate("ipv6_fixlen")).value = ipv6_fixlen
    s:option(DummyValue, "_ipv6_prefix", translate("IPv6 Prefix")).value = ipv6_prefix
    s:option(DummyValue, "_ipv6_prefix_length", translate("IPv6 Prefix Length")).value = ipv6_prefix_length
    s:option(DummyValue, "_ipv4_prefix", translate("IPv4 Prefix")).value = ipv4_prefix
    s:option(DummyValue, "_ipv4_prefix_length", translate("IPv4 Prefix Length")).value = ipv4_prefix_length
    s:option(DummyValue, "_ea_length", translate("EA Length")).value = ealen
    s:option(DummyValue, "_psid_offset", translate("PSID Offset")).value = offset
    s:option(DummyValue, "_psid_len", translate("PSID Length")).value = psidlen

return m
