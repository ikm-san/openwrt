local uci = require "luci.model.uci".cursor()
local sys = require "luci.sys"
local http = require "luci.http"

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
choice.default = "wifi"

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
msg_text.default = "※メッシュWiFiバックホールつきのDumb APになります。元に戻したい場合は初期化してください。"
msg_text:depends("network_config", "mesh_child")

-- メッシュWiFiバックホール設定
local function configure_meshWifi()
    -- Mesh configuration variables
    local meshName = "meshWiFi"
    local meshPwd = "WiFi_backhaul"
    local meshRadio = "radio0"
    local meshChannel = "1"

    -- Install the wpad mesh package
    os.execute("opkg update")
    os.execute("opkg install --force-overwrite wpad-mesh-openssl")

    -- Configure the mesh WiFi
    uci:section("wireless", "wifi-iface", "wifinet0", {
        device = meshRadio,
        mode = "mesh",
        encryption = "sae",
        mesh_id = meshName,
        mesh_fwding = "1",
        mesh_rssi_threshold = "0",
        key = meshPwd,
        network = "lan"
    })
    uci:set("wireless", meshRadio, "channel", meshChannel)
    uci:delete("wireless", meshRadio, "disabled")

    -- Commit changes and restart WiFi
    uci:commit("wireless")
    sys.call("wifi down")
    sys.call("/etc/init.d/wpad restart")
    sys.call("wifi up")
end



function choice.write(self, section, value)
    
if value == "wifi" then
    -- 特定の無線デバイスに対して設定を適用
    local devices = {"radio0", "radio1", "radio2"}
    for _, dev in ipairs(devices) do
        uci:set("wireless", dev, "country", "JP")
        uci:set("wireless", dev, "disabled", "0")
        
        -- 現存するwifi-ifaceセクションを検索し、設定を更新
        uci:foreach("wireless", "wifi-iface",
            function(s)
                if s.device == dev then
                    -- 既存のセクションを更新
                    uci:set("wireless", s['.name'], "mode", "ap")
                    uci:set("wireless", s['.name'], "ssid", ssid:formvalue(section))
                    uci:set("wireless", s['.name'], "encryption", "sae-mixed")
                    uci:set("wireless", s['.name'], "key", password:formvalue(section))
                    uci:set("wireless", s['.name'], "disabled", "0") -- Enable wireless
                    
                    return false -- 一致する最初のセクションのみを更新
                    
                end
            end)
        uci:commit("wireless")
    -- 設定の保存と適用
    uci:commit("wireless")
    -- ネットワークの再起動をここで行う
    sys.exec("/etc/init.d/network restart")
            
    end
    
      
    elseif value == "mesh_parent" then
        -- メッシュWiFi親機設定を適用する処理
        configure_meshWifi()
    elseif value == "mesh_child" then
        -- メッシュWiFi子機設定を適用する処理
        configure_meshWifi()
    end

end

function m.on_after_commit(self)
    http.write("<script>alert('設定変更が完了しました。再起動します。');</script>")
end

return m
