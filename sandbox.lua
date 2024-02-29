local m, s, o

local ca_lib = require "lib"

m = Map("custom", translate("CA Status"), translate("Display WAN IPv6 to IPv4 Prefix Status."))

s = m:section(TypedSection, "ca_status", translate("Status"))
s.anonymous = true
s.addremove = false

local wan_ipv6 = lib.get_wan_ipv6_global()
local ipv4_prefix = lib.find_ipv4_prefix(wan_ipv6)

o = s:option(DummyValue, "wan_ipv6", translate("WAN IPv6 Address"))
o.value = wan_ipv6

o = s:option(DummyValue, "ipv4_prefix", translate("IPv4 Prefix"))
o.value = ipv4_prefix or translate("No matching IPv4 prefix found.")

return m
