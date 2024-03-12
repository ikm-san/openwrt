local uci = require("luci.model.uci").cursor()
local jsonc = require("luci.jsonc")
local calib = require "calib" 

local m, s

m = SimpleForm("ca_setup", translate("CA Setup Configuration"))
m.reset = false
m.submit = false

s = m:section(SimpleSection, translate("Settings"))

local success, peeraddr, ipv4_prefix, ipv4_prefixlen, ipv6_prefix, ipv6_prefixlen, ealen, psidlen, offset = pcall(calib.get_mapconfig)
if success then
    print("Configuration Loaded Successfully")
    -- Use the variables for your purposes here
else
    print("Error: " .. peeraddr) -- peeraddr will contain the error message if pcall fails
end

-- 該当するfmrエントリの情報を出力



    s:option(DummyValue, "_wan_ipv6", translate("wan_ipv6")).value = wan_ipv6
    s:option(DummyValue, "_peeraddr", translate("peeraddr")).value = peeraddr
    s:option(DummyValue, "_ipv6_fixlen", translate("ipv6_fixlen")).value = ipv6_fixlen
    s:option(DummyValue, "_ipv6_prefix", translate("IPv6 Prefix")).value = ipv6_prefix
    s:option(DummyValue, "_ipv6_prefix_length", translate("IPv6 Prefix Length")).value = ipv6_prefix_length
    s:option(DummyValue, "_ipv4_prefix", translate("IPv4 Prefix")).value = ipv4_prefix
    s:option(DummyValue, "_ipv4_prefix_length", translate("IPv4 Prefix Length")).value = ipv4_prefix_length
    s:option(DummyValue, "_ea_length", translate("EA Length")).value = ealen
    s:option(DummyValue, "_psid_offset", translate("PSID Offset")).value = offset
    s:option(DummyValue, "_psid_len", translate("PSID Length")).value = pisdlen
    s:option(DummyValue, "_wan32", translate("wan32")).value = wan32_ipv6
    s:option(DummyValue, "_wan40", translate("wan40")).value = wan40_ipv6

return m
