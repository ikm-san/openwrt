local uci = require("luci.model.uci").cursor()
local jsonc = require("luci.jsonc")
local wan_ipv6 = '240b:10:af40:100:6a:48af:4000:100' -- 例としてのIPv6アドレス

-- ca_setup設定からdmr, ipv6_fixlen, およびfmrの値を読み込む
local dmr = uci:get("ca_setup", "@settings[0]", "dmr")
local ipv6_fixlen = uci:get("ca_setup", "@settings[0]", "ipv6_fixlen")
local fmr_json = uci:get("ca_setup", "@settings[0]", "fmr")
local fmr = jsonc.parse(fmr_json)

-- IPv6アドレスにマッチするfmrエントリを探す
local function find_matching_fmr(wan_ipv6, fmr_list)
    for _, entry in ipairs(fmr_list) do
        local ipv6_prefix = entry.ipv6:match("^(.-)/")
        if wan_ipv6:find(ipv6_prefix) == 1 then
            return entry
        end
    end
    return nil
end

local matching_fmr = find_matching_fmr(wan_ipv6, fmr)

-- 結果を表示
if matching_fmr then
    print("IPv6 Prefix: " .. matching_fmr.ipv6)
    print("IPv4 Prefix: " .. matching_fmr.ipv4)
    print("PSID Offset: " .. tostring(matching_fmr.psid_offset))
    print("EA Length: " .. tostring(matching_fmr.ea_length))
    print("DMR: " .. dmr)
    print("IPv6 FixLen: " .. ipv6_fixlen)
else
    print("該当するFMRエントリが見つかりません。")
end
