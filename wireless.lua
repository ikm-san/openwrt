local uci = require "luci.model.uci".cursor()
local sys = require "luci.sys"

m = Map("wireless", _("Wireless Configuration"))
m.apply_on_parse = true -- SAVE&APPLYボタンが押されたときに設定を適用

s = m:section(TypedSection, "wifi-iface", _("Settings"))
s.anonymous = true
s.addremove = false

ssid = s:option(Value, "ssid", _("SSID"))
ssid.datatype = "maxlength(32)"
ssid.default = "OpenWrt"

password = s:option(Value, "key", _("Password"))
password.datatype = "pw"
password.password = true

function m.on_commit(map)
    local devices = {"radio0", "radio1"} -- 2.4GHzと5GHzのデバイス名を指定

    for _, dev in ipairs(devices) do
        -- 国コードと最大送信電力の設定
        uci:set("wireless", dev, "country", "JP")
        uci:set("wireless", dev, "txpower", "10")

        -- インターフェースの設定
        local iface_section = dev .. "_network"
        uci:set("wireless", iface_section, "device", dev)
        uci:set("wireless", iface_section, "mode", "ap")
        uci:set("wireless", iface_section, "ssid", ssid:formvalue(dev))
        uci:set("wireless", iface_section, "encryption", "psk2+ccmp")
        uci:set("wireless", iface_section, "key", password:formvalue(dev))
        uci:set("wireless", iface_section, "disabled", "0") -- Enable wireless
    end

    -- 設定の保存と適用
    uci:commit("wireless")
    sys.call("wifi reload")
end

return m
