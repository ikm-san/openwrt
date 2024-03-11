local uci = require("luci.model.uci").cursor()
local jsonc = require("luci.jsonc")

local m, s

m = SimpleForm("ca_setup", translate("CA Setup Configuration"))
m.reset = false
m.submit = false

s = m:section(SimpleSection, translate("Settings"))

-- dmrの表示
local dmr = uci:get("ca_setup", "@settings[0]", "dmr")
s:option(DummyValue, "_dmr", translate("DMR")).value = dmr

-- ipv6_fixlenの表示
local ipv6_fixlen = uci:get("ca_setup", "@settings[0]", "ipv6_fixlen")
s:option(DummyValue, "_ipv6_fixlen", translate("IPv6 FixLen")).value = ipv6_fixlen

-- fmrの表示
local fmr_json = uci:get("ca_setup", "@settings[0]", "fmr")
local fmr = jsonc.parse(fmr_json)
local fmr_string = jsonc.stringify(fmr, true) -- 読みやすい形式でJSONを文字列化
s:option(DummyValue, "_fmr", translate("FMR")).value = fmr_string

return m
