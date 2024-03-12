local uci = require("luci.model.uci").cursor()
local jsonc = require("luci.jsonc")
local calib = require "calib" 

local m, s

m = SimpleForm("ca_setup", translate("CA Setup Configuration"))
m.reset = false
m.submit = false

s = m:section(SimpleSection, translate("Settings"))

-- WANのグローバルIPv6を取得
local wan_ipv6 = calib.get_wan_ipv6_global()
local wan32_ipv6, wan40_ipv6 = calib.wan32_40(wan_ipv6)

local peeraddr = uci:get("ca_setup", "@settings[0]", "dmr")
local ipv6_fixlen = uci:get("ca_setup", "@settings[0]", "ipv6_fixlen")

-- fmrの読み込みと解析
local fmr_json = uci:get("ca_setup", "@settings[0]", "fmr")
local fmr = jsonc.parse(fmr_json)

-- wan_ipv6アドレスにマッチするfmrエントリを検索する関数
local function find_matching_fmr(wan_ipv6, fmr_list)
    for _, entry in ipairs(fmr_list) do
        local ipv6_prefix = entry.ipv6:match("^(.-)/")
        if wan_ipv6:find(ipv6_prefix) == 1 then
            return entry
        end
    end
    return nil
end

-- 第3セクションまでを考慮したパターンで検索
local matching_fmr = find_matching_fmr(wan40_ipv6, fmr)
-- 見つからなければ、第2セクションまでのパターンで検索
if not matching_fmr then
    matching_fmr = find_matching_fmr(wan32_ipv6, fmr)
end

-- 該当するfmrエントリの情報を出力
if matching_fmr then
    local ipv6_prefix, ipv6_prefix_length = matching_fmr.ipv6:match("^(.-)/(%d+)$")
    local ipv4_prefix, ipv4_prefix_length = matching_fmr.ipv4:match("^(.-)/(%d+)$")

    s:option(DummyValue, "_wan_ipv6", translate("wan_ipv6")).value = wan_ipv6
    s:option(DummyValue, "_peeraddr", translate("peeraddr")).value = peeraddr
    s:option(DummyValue, "_ipv6_fixlen", translate("ipv6_fixlen")).value = ipv6_fixlen
    s:option(DummyValue, "_ipv6_prefix", translate("IPv6 Prefix")).value = ipv6_prefix
    s:option(DummyValue, "_ipv6_prefix_length", translate("IPv6 Prefix Length")).value = ipv6_prefix_length
    s:option(DummyValue, "_ipv4_prefix", translate("IPv4 Prefix")).value = ipv4_prefix
    s:option(DummyValue, "_ipv4_prefix_length", translate("IPv4 Prefix Length")).value = ipv4_prefix_length
    s:option(DummyValue, "_ea_length", translate("EA Length")).value = matching_fmr.ea_length
    s:option(DummyValue, "_psid_offset", translate("PSID Offset")).value = matching_fmr.psid_offset
    s:option(DummyValue, "_wan32", translate("wan32")).value = wan32_ipv6
    s:option(DummyValue, "_wan40", translate("wan40")).value = wan40_ipv6
else
    s:option(DummyValue, "_error", translate("Error")).value = translate("No matching FMR entry found.")
        s:option(DummyValue, "_wan32", translate("wan32")).value = wan32_ipv6
    s:option(DummyValue, "_wan40", translate("wan40")).value = wan40_ipv6
end

return m
