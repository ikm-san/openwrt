local m, s, o

m = Map("ca_setup", translate("CA Setup"), translate("Configure CA Settings."))

s = m:section(TypedSection, "ca_status", translate("Status"))
s.anonymous = true
s.addremove = false

local lib = require "luci.model.cbi.ca_setup.lib"
local wan_ipv6 = lib.get_wan_ipv6_global()
local ipv4_prefix = lib.find_ipv4_prefix(wan_ipv6)

o = s:option(DummyValue, "wan_ipv6", translate("WAN IPv6 Address"))
o.value = wan_ipv6

o = s:option(DummyValue, "ipv4_prefix", translate("IPv4 Prefix"))
o.value = ipv4_prefix or translate("No matching IPv4 prefix found.")

return m

