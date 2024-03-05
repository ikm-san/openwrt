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
password.datatype = "rangelength(8,63)" -- WPA/WPA2パスワードの一般的な長さ要件
password.password = true

ssid:depends("network_config", "wifi")
password:depends("network_config", "wifi")


-- メッシュWiFi子機設定
msg_text = s:option(DummyValue, "smg_text", "取扱注意")
msg_text.default = "※メッシュWiFiバックホールつきのDumb APになります。元に戻したい場合は初期化。"
msg_text:depends("network_config", "mesh_child")

function choice.write(self, section, value)
    
if value == "wifi" then
    -- 特定の無線デバイスに対して設定を適用
    local devices = {"radio0", "radio1", "radio2"}
    for _, dev in ipairs(devices) do
        uci:set("wireless", dev, "country", "JP")
        uci:set("wireless", dev, "txpower", "10")
        uci:set("wireless", dev, "disabled", "0")
        
        -- 現存するwifi-ifaceセクションを検索し、設定を更新
        uci:foreach("wireless", "wifi-iface",
            function(s)
                if s.device == dev then
                    -- 既存のセクションを更新
                    uci:set("wireless", s['.name'], "mode", "ap")
                    uci:set("wireless", s['.name'], "ssid", ssid:formvalue(section))
                    uci:set("wireless", s['.name'], "encryption", "psk2+ccmp")
                    uci:set("wireless", s['.name'], "key", password:formvalue(section))
                    uci:set("wireless", s['.name'], "disabled", "0") -- Enable wireless
                    return false -- 一致する最初のセクションのみを更新
                end
            end)
    end
    
    -- 設定の保存と適用
    uci:commit("wireless")
    sys.exec("/etc/init.d/network restart")

       
    elseif value == "mesh_parent" then
        -- メッシュWiFi親機設定を適用する処理
    elseif value == "mesh_child" then
        -- メッシュWiFi子機設定を適用する処理
    end

end

function m.on_after_commit(self)
    luci.http.redirect(luci.dispatcher.build_url("admin/"))
end

return m
