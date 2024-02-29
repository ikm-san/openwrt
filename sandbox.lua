local uci = require "luci.model.uci".cursor()
local sys = require "luci.sys"
local m, s, o

-- WANインターフェースのIPv6アドレス（scope global）を取得
local function get_wan_ipv6_global()
    local command = "ip -6 addr show dev wan | awk '/inet6/ && /scope global/ {print $2}' | cut -d'/' -f1 | head -n 1"
    local ipv6_global = sys.exec(command)
    return ipv6_global:match("([a-fA-F0-9:]+)") -- IPv6アドレスの正規化
end



m = Map("ca_setup", translate("CA Setup"), translate("Configure CA Settings."))

s = m:section(TypedSection, "ca_status", translate("Status"))
s.anonymous = true
s.addremove = false

local lib = require "luci.model.cbi.ca_setup.lib"
local wan_ipv6 = get_wan_ipv6_global()

local ipv4_prefix = lib.find_ipv4_prefix(wan_ipv6)

o = s:option(DummyValue, "wan_ipv6", translate("WAN IPv6 Address"))
o.value = wan_ipv6

o = s:option(DummyValue, "ipv4_prefix", translate("IPv4 Prefix"))
o.value = ipv4_prefix or translate("No matching IPv4 prefix found.")

return m

