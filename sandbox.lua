local uci = require("luci.model.uci").cursor()
local jsonc = require("luci.jsonc")
local calib = require "calib" 

local m, s

m = SimpleForm("ca_setup", translate("CA Setup Configuration"))
m.reset = false
m.submit = false

s = m:section(SimpleSection, translate("Settings"))

local wan_ipv6 = calib.get_wan_ipv6_global()

local peeraddr, ipv4_prefix, ipv4_prefix_length, ipv6_prefix, ipv6_prefix_length, ealen, psidlen, offset, ipv6_fixlen, ipv6_56, fmr, fmr_json, wan_ipv6, wan32_ipv6, wan40_ipv6 = calib.get_mapconfig(wan_ipv6)


    s:option(DummyValue, "_wan_ipv6", translate("wan_ipv6")).value = wan_ipv6
    s:option(DummyValue, "_peeraddr", translate("peeraddr")).value = peeraddr
    s:option(DummyValue, "_ipv6_56", translate("IPv6 56")).value = ipv6_56
    s:option(DummyValue, "_ipv6_fixlen", translate("ipv6_fixlen")).value = ipv6_fixlen
    s:option(DummyValue, "_ipv6_prefix", translate("IPv6 Prefix")).value = ipv6_prefix
    s:option(DummyValue, "_ipv6_prefix_length", translate("IPv6 Prefix Length")).value = ipv6_prefix_length
    s:option(DummyValue, "_ipv4_prefix", translate("IPv4 Prefix")).value = ipv4_prefix
    s:option(DummyValue, "_ipv4_prefix_length", translate("IPv4 Prefix Length")).value = ipv4_prefix_length
    s:option(DummyValue, "_ea_length", translate("EA Length")).value = ealen
    s:option(DummyValue, "_psid_offset", translate("PSID Offset")).value = offset
    s:option(DummyValue, "_wan32", translate("wan32")).value = wan32_ipv6
    s:option(DummyValue, "_wan40", translate("wan40")).value = wan40_ipv6
    s:option(DummyValue, "_fmr_json", translate("fmr_json")).value = fmr_json
    s:option(DummyValue, "_fmr", translate("fmr")).value = fmr


return m
