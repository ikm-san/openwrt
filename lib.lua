local sys = require "luci.sys"

local M = {}

-- IPv6からIPv4プレフィックスへの変換マップ
local ruleprefix31 = {
    ["240b0010"] = "106.72",
    ["240b0012"] = "14.8",
    ["240b0250"] = "14.10",
    ["240b0252"] = "14.12",
    ["24047a80"] = "133.200",
    ["24047a84"] = "133.206"
}

local ruleprefix38 = {
    ["24047a8200"] = "125.196.208",
    ["24047a8204"] = "125.196.212",
    ["24047a8208"] = "125.198.140",
    ["24047a820c"] = "125.198.144",
    ["24047a8210"] = "125.198.212"
}

local ruleprefix38_20 = {
    ["2400405000"] = "153.240.0",
    ["2400405004"] = "153.240.16",
    ["2400405008"] = "153.240.32",
    ["240040500c"] = "153.240.48",
    ["2400405010"] = "153.240.64"
}

-- WANインターフェースのIPv6アドレス（scope global）を取得
function M.get_wan_ipv6_global()
    local command = "ip -6 addr show dev wan | awk '/inet6/ && /scope global/ {print $2}' | cut -d'/' -f1 | head -n 1"
    local ipv6_global = sys.exec(command)
    return ipv6_global:match("([a-fA-F0-9:]+)") -- IPv6アドレスの正規化
end

-- IPv6アドレスから対応するIPv4プレフィックスを取得
function M.find_ipv4_prefix(wan_ipv6)
    local segments = {}
    for seg in wan_ipv6:gmatch("[a-fA-F0-9]+") do
        table.insert(segments, string.format("%04x", tonumber(seg, 16)))
    end

    local full_ipv6 = table.concat(segments, ":"):gsub("::", function(s)
        return ":" .. string.rep("0000:", 8 - #segments)
    end)

    local hex_prefix_40 = full_ipv6:gsub(":", ""):sub(1, 10)
    local hex_prefix_32 = full_ipv6:gsub(":", ""):sub(1, 8)

    local ipv4_prefix = ruleprefix38[hex_prefix_40] or ruleprefix38_20[hex_prefix_40] or ruleprefix31[hex_prefix_32]

    if ipv4_prefix then
        local ipv4_parts = {}
        for part in ipv4_prefix:gmatch("(%d+)") do
            table.insert(ipv4_parts, part)
        end
        while #ipv4_parts < 4 do
            table.insert(ipv4_parts, "0")
        end
        return table.concat(ipv4_parts, ".")
    else
        return nil
    end
end

return M
