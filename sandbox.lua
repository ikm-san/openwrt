local uci = require "luci.model.uci".cursor()
local sys = require "luci.sys"

-- MAPE IPv6からIPv4プレフィックスへの変換マップ
local ipv6_prefix_map = {
    ["240b:10::"] = "106.72",
    ["240b:12::"] = "14.8",
    ["240b:250::"] = "14.10",
    ["240b:252::"] = "14.12",
    ["2404:7a80::"] = "133.200",
    ["2404:7a84::"] = "133.206"
}

-- WANインターフェースのIPv6アドレス（scope global）を取得
local function get_wan_ipv6_global()
    local command = "ip -6 addr show dev wan | awk '/inet6/ && /scope global/ {print $2}' | cut -d'/' -f1 | head -n 1"
    local ipv6_global = sys.exec(command)
    return ipv6_global:match("([a-fA-F0-9:]+)") -- IPv6アドレスの正規化
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

-- IPv4プレフィックスから完全なIPv4アドレスを生成する関数
local function complete_ipv4_address(ipv4_prefix)
    local segments = {ipv4_prefix:match("^(%d+)%.(%d*)%.?(%d*)%.?(%d*)$")} 
    if #segments == 0 then
        return nil, "Invalid IPv4 prefix format"
    end
    for i = #segments + 1, 4 do
        segments[i] = "0"
    end
    return table.concat(segments, ".")
end

m = Map("ca_setup", translate("MAPE Configuration"),
        translate("Configure MAPE IPv4 prefix based on WAN IPv6 address."))

s = m:section(TypedSection, "mape_test", translate("Settings"))
s.anonymous = true
s.addremove = false

local wan_ipv6 = get_wan_ipv6_global()
local ipv4_prefix = find_ipv4_prefix(wan_ipv6)

o = s:option(DummyValue, "ipv6_address", translate("WAN IPv6 Address"))
o.value = wan_ipv6

o = s:option(DummyValue, "ipv4_prefix", translate("Calculated IPv4 Prefix"))
o.value = ipv4_prefix or translate("No matching IPv4 prefix found.")

function m.on_commit(map)
    local new_ipv4_prefix = find_ipv4_prefix(get_wan_ipv6_global())
    if new_ipv4_prefix then
        uci:set("ca_setup", "mape_test", "ipv4_prefix", new_ipv4_prefix)
        uci:commit("ca_setup")
    end
end

return m
