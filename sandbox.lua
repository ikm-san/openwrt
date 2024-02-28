local uci = require "luci.model.uci".cursor()
local sys = require "luci.sys"

-- IPv6からIPv4プレフィックスへの変換マップ（修正版）
local ruleprefix31 = {
    [0x240b0010] = "106.72",
    [0x240b0012] = "14.8",
    [0x240b0250] = "14.10",
    [0x240b0252] = "14.12",
    [0x24047a80] = "133.200",
    [0x24047a84] = "133.206"
}

-- WANインターフェースのIPv6アドレス（scope global）を取得
local function get_wan_ipv6_global()
    local command = "ip -6 addr show dev wan | awk '/inet6/ && /scope global/ {print $2}' | cut -d'/' -f1 | head -n 1"
    local ipv6_global = sys.exec(command)
    return ipv6_global:match("([a-fA-F0-9:]+)") -- IPv6アドレスの正規化
end

local wan_ipv6 = get_wan_ipv6_global()

-- IPv6アドレスから対応するIPv4プレフィックスを取得（修正版）
local function find_ipv4_prefix(wan_ipv6)
    
        -- IPv6アドレスを正規化して、省略された0を補う
    local full_ipv6 = wan_ipv6:gsub("::", function(s)
        return ":" .. string.rep("0000:", 8 - select(2, ipv6_addr:gsub(":", "")) - 1)
    end)
    full_ipv6 = full_ipv6:gsub(":(%x):", ":0%1:"):gsub(":(%x)$", ":0%1"):gsub("^:(%x):", "0%1:")

    -- 正規化されたIPv6アドレスから先頭の32ビットを取得
    local hex_prefix = full_ipv6:gsub(":", ""):sub(1, 8)
    local ipv6_prefix_32bit = tonumber(hex_prefix, 16)

    -- 変換マップから対応するIPv4プレフィックスを探す
    local ipv4_prefix = ruleprefix31[ipv6_prefix_32bit]
    if ipv4_prefix then
            local segments = {ipv4_prefix:match("^(%d+)%.(%d*)%.?(%d*)%.?(%d*)$")} 
            if #segments == 0 then
                return nil, "Invalid IPv4 prefix format"
            end
            for i = #segments + 1, 4 do
                segments[i] = "0"
            end
            return table.concat(segments, ".")
        return ipv4_prefix
    else
        return nil, "No matching IPv4 prefix found."
    end

end

m = Map("ca_setup", translate("MAPE Configuration"),
        translate("Configure MAPE IPv4 prefix based on WAN IPv6 address."))

s = m:section(TypedSection, "mape_test", translate("Settings"))
s.anonymous = true
s.addremove = false



o = s:option(DummyValue, "ipv6_prefix_32bit", translate("WAN IPv6 Prefix"))
o.value = ipv6_prefix_32bit

o = s:option(DummyValue, "hex_prefix", translate("hex_prefix"))
o.value = hex_prefix or translate("No matching IPv4 prefix found.")

o = s:option(DummyValue, "wan_ipv6", translate("ipv6 addr"))
o.value = wan_ipv6 or translate("No matching IPv4 prefix found.")

o = s:option(DummyValue, "ipv4_prefix", translate("Map-E IPv4 Prefix"))
o.value = ipv4_prefix or translate("No matching IPv4 prefix found.")

function m.on_commit(map)
    local new_ipv4_prefix = find_ipv4_prefix(get_wan_ipv6_global())
    if new_ipv4_prefix then
        uci:set("ca_setup", "mape_test", "ipv4_prefix", new_ipv4_prefix)
        uci:commit("ca_setup")
    end
end

return m
