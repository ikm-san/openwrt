local uci = require "luci.model.uci".cursor()
local ip = require "luci.ip"
local sys = require "luci.sys"


-- WANインターフェースのIPv6アドレスを取得
local function get_wan_ipv6()
    local wan_ipv6 = sys.exec("ubus call network.interface.wan status | jsonfilter -e '@[\"ipv6-address\"][0][\"address\"]'")
    return wan_ipv6:match("([a-fA-F0-9:]+)") -- IPv6アドレスの正規化
end

-- IPv6アドレスから対応するIPv4プレフィックスを取得
local function find_ipv4_prefix(ipv6_addr)
    for prefix, ipv4 in pairs(ipv6_prefix_map) do
        if ipv6_addr:match("^" .. prefix) then
            return ipv4
        end
    end
    return nil
end

m = Map("ca_setup", translate("MAPE Configuration"),
        translate("Configure MAPE IPv4 prefix based on WAN IPv6 address."))

s = m:section(TypedSection, "mape_test", translate("Settings"))
s.anonymous = true
s.addremove = false

local wan_ipv6 = get_wan_ipv6()
local ipv4_prefix = find_ipv4_prefix(wan_ipv6)

o = s:option(DummyValue, "ipv6_address", translate("WAN IPv6 Address"))
o.value = wan_ipv6

o = s:option(DummyValue, "ipv4_prefix", translate("Calculated IPv4 Prefix"))
o.value = ipv4_prefix or translate("No matching IPv4 prefix found.")

function m.on_commit(map)
    local new_ipv4_prefix = find_ipv4_prefix(get_wan_ipv6())
    if new_ipv4_prefix then
        uci:set("ca_setup", "mape_test", "ipv4_prefix", new_ipv4_prefix)
        uci:commit("ca_setup")
    end
end

-- MAPE IPv6からIPv4プレフィックスへの変換マップ
local ipv6_prefix_map = {
    ["240b:10::"] = "106.72",
    ["240b:12::"] = "14.8",
    ["240b:250::"] = "14.10",
    ["240b:252::"] = "14.12",
    ["2404:7a80::"] = "133.200",
    ["2404:7a84::"] = "133.206"
}


return m
