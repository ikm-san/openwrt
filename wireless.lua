local uci = require "luci.model.uci".cursor()
local sys = require "luci.sys"

-- 'ca_setup'設定ファイルを扱うMapを作成
m = Map("ca_setup", "WiFi各種設定")

-- 'wifi-iface'セクションを操作するためのSectionを定義
s = m:section(TypedSection, "wifi-iface", "Settings")
s.anonymous = true
s.addremove = false

-- 設定の選択肢を定義
choice = s:option(ListValue, "network_config", "設定の選択")
choice:value("wifi", "WiFi接続設定")
choice:value("mesh_parent", "メッシュWiFi親機設定")
choice:value("mesh_child", "メッシュWiFi子機設定")

-- SSIDとパスワードの設定
ssid = s:option(Value, "ssid", "SSID")
ssid.datatype = "maxlength(32)"
ssid.default = "OpenWrt"

password = s:option(Value, "key", "Password")
password.datatype = "pw"
password.password = true

ssid:depends("network_config", "wifi")
password:depends("network_config", "wifi")


function apply.write(self, section)
    local value = choice:formvalue(section)
    
    if value == "wifi" then
        -- WiFi接続設定を適用する処理
                local devices = {"radio0", "radio1", "radio2"} -- トライバンドまで対応
            
                for _, dev in ipairs(devices) do
                    -- デバイスの存在を確認
                    if uci:get("wireless", dev) ~= nil then
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
                end

            
        -- 設定の保存と適用
        uci:commit("wireless")
        sys.call("wifi reload")
        
    elseif value == "mesh_parent" then
        -- メッシュWiFi親機設定を適用する処理
    elseif value == "mesh_child" then
        -- メッシュWiFi子機設定を適用する処理
    end

end

return m
