local uci = require("luci.model.uci").cursor()
local json = require("luci.jsonc")

-- 与えられたIPv6アドレス
local wan_ipv6 = '240b:10:af40:100:6a:48af:4000:100'

-- ca_setupの設定を取得
local settings = uci:get_all("ca_setup", "settings")

-- dmrとipv6_fixlenを取得
local dmr = settings.dmr
local ipv6_fixlen = settings.ipv6_fixlen

-- fmrのJSONデータを取得し、解析
local fmr_data = json.parse(settings.fmr)

-- IPv6アドレスを確認する関数
local function find_matching_fmr(wan_ipv6, fmr_data)
    for _, fmr in ipairs(fmr_data) do
        local ipv6_prefix = fmr.ipv6:match("^(.-)/")
        if wan_ipv6:find(ipv6_prefix) == 1 then
            return fmr
        end
    end
    return nil
end

-- 該当するfmrを探す
local matching_fmr = find_matching_fmr(wan_ipv6, fmr_data)

if matching_fmr then
    local ipv6prefix, ipv6prefix_length = matching_fmr.ipv6:match("^(.-)/(%d+)$")
    local ipv4prefix, ipv4prefix_length = matching_fmr.ipv4:match("^(.-)/(%d+)$")
    print("IPv6 Prefix: " .. ipv6prefix)
    print("IPv6 Prefix Length: " .. ipv6prefix_length)
    print("IPv4 Prefix: " .. ipv4prefix)
    print("IPv4 Prefix Length: " .. ipv4prefix_length)
    print("PSID Offset: " .. matching_fmr.psid_offset)
    print("EA Length: " .. matching_fmr.ea_length)
    print("DMR: " .. dmr)
    print("IPv6 FixLen: " .. ipv6_fixlen)
else
    print("該当するFMRエントリが見つかりません。")
end
