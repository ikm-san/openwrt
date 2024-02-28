-- mape_test.lua
require "luci.model.uci"
require "luci.sys"

local uci = luci.model.uci.cursor()
local ipv6_prefix_map = {
    [0x240b0010] = {106, 72},
    [0x240b0012] = {14, 8},
    [0x240b0250] = {14, 10},
    [0x240b0252] = {14, 12},
    [0x24047a80] = {133, 200},
    [0x24047a84] = {133, 206}
}

function ipv6_to_ipv4_prefix(ipv6_address)
    local prefix = ipv6_address:match("^([a-fA-F0-9]+):"):gsub(":", "")
    local prefix_number = tonumber(prefix, 16)

    local ipv4_pair = ipv6_prefix_map[prefix_number]
    if ipv4_pair then
        return table.concat({ipv4_pair[1], ipv4_pair[2]}, ".")
    else
        return nil
    end
end

-- WANインターフェースからIPv6アドレスを取得
local wan_ipv6_address = luci.sys.exec("ubus call network.interface.wan status | jsonfilter -e '@[\"ipv6-address\"][0][\"address\"]'")

-- IPv6アドレスからIPv4プレフィックスを計算
local ipv4_prefix = ipv6_to_ipv4_prefix(wan_ipv6_address)

if ipv4_prefix then
    -- 計算されたIPv4プレフィックスをca_setupのmape_testセクションに保存
    uci:set("ca_setup", "mape_test", "ipv4_prefix", ipv4_prefix)
    uci:commit("ca_setup")
    print("IPv4 Prefix: " .. ipv4_prefix)
else
    print("No valid IPv4 prefix found for the given IPv6 address.")
end
