local uci = require "luci.model.uci".cursor()
local sys = require "luci.sys"

-- IPv6からIPv4プレフィックスへの変換マップ
local ruleprefix31 = {
    ["240b0010"] = "106.72",
    ["240b0012"] = "14.8",
    ["240b0250"] = "14.10",
    ["240b0252"] = "14.12",
    ["24047a80"] = "133.200",
    ["24047a84"] = "133.206"
}

-- WANインターフェースのIPv6アドレス（scope global）を取得
local function get_wan_ipv6_global()
    local command = "ip -6 addr show dev wan | awk '/inet6/ && /scope global/ {print $2}' | cut -d'/' -f1 | head -n 1"
    local ipv6_global = sys.exec(command)
    return ipv6_global:match("([a-fA-F0-9:]+)") -- IPv6アドレスの正規化
end

local wan_ipv6 = get_wan_ipv6_global()

-- IPv6アドレスから対応するIPv4プレフィックスを取得
local function find_ipv4_prefix(wan_ipv6)
    -- IPv6アドレスをセグメントに分割
    local segments = {}
    for seg in wan_ipv6:gmatch("[a-fA-F0-9]+") do
        table.insert(segments, string.format("%04x", tonumber(seg, 16)))
    end

    -- IPv6アドレスの正規化（省略されたセグメントの補完）
    local full_ipv6 = table.concat(segments, ":"):gsub("::", function(s)
        return ":" .. string.rep("0000:", 8 - #segments) -- 足りない分の0000を補う
    end)

    -- 正規化されたIPv6アドレスから先頭の32ビットを取得
    local hex_prefix = full_ipv6:gsub(":", ""):sub(1, 8)
    local ipv4_prefix = ruleprefix31[hex_prefix]

    if ipv4_prefix then
        local ipv4_parts = {}
        for part in ipv4_prefix:gmatch("(%d+)") do
            table.insert(ipv4_parts, part)
        end
        -- 不足しているセクションを0で埋める
        while #ipv4_parts < 4 do
            table.insert(ipv4_parts, "0")
        end
        local ipv4_full = table.concat(ipv4_parts, ".")
        return ipv4_full -- 例: "106.72.0.0"
    else
        return nil, "No matching IPv4 prefix found."
    end
end

-- Luaスクリプトでマップやルーチング設定を行う部分
m = Map("ca_setup", translate("MAPE Configuration"),
        translate("Configure MAPE IPv4 prefix based on WAN IPv6 address."))

s = m:section(TypedSection, "mape_test", translate("Settings"))
s.anonymous = true
s.addremove = false

local ipv4_prefix = find_ipv4_prefix(wan_ipv6)

o = s:option(DummyValue, "wan_ipv6", translate("WAN IPv6 Address"))
o.value = wan_ipv6 or translate("Not available")

o = s:option(DummyValue, "ipv4_prefix", translate("MAPE IPv4 Prefix"))
o.value = ipv4_prefix or translate("No matching IPv4 prefix found.")

function m.on_commit(map)
    local new_ipv4_prefix = find_ipv4_prefix(get_wan_ipv6_global())
    if new_ipv4_prefix then
        uci:set("ca_setup", "mape_test", "ipv4_prefix", new_ipv4_prefix)
        uci:commit("ca_setup")
    end
end

return m
