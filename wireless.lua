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
password.default = "SmartWiFi123-/"
password.datatype = "rangelength(8,63)" -- WPA/WPA2パスワードの一般的な長さ要件
password.password = true

ssid:depends("network_config", "wifi")
password:depends("network_config", "wifi")

-- mesh backhaulのSSIDとパスワードの設定
mesh_id = s:option(Value, "ssid", "Mesh WiFi")
mesh_id.datatype = "maxlength(32)"
mesh_id.default = "WiFi_backhaul"

mesh_password = s:option(Value, "key", "Password")
mesh_password.default = "G>P~``4*!^oqxP4"
mesh_password.datatype = "rangelength(8,63)" -- WPA/WPA2パスワードの一般的な長さ要件
mesh_password.password = true

mesh_id:depends("network_config", "mesh_parent")
mesh_password:depends("network_config", "mesh_parent")
mesh_id:depends("network_config", "mesh_child")
mesh_password:depends("network_config", "mesh_child")

-- メッシュWiFi子機設定
msg_text = s:option(DummyValue, "smg_text", "【取扱注意】")
msg_text.default = "完全なブリッジモードとなり管理画面にアクセスできなくなるため、元に戻したい場合は初期化してください。"
msg_text:depends("network_config", "mesh_child")

-- メッシュWiFiバックホール設定
local function configure_meshWifi()
    -- Mesh configuration variables
    local meshChannels = {radio0 = "1", radio1 = "36"} 

    -- Install the wpad mesh package
    os.execute("opkg update")
    os.execute("opkg install --force-overwrite wpad-mesh-openssl")

    for radio, channel in pairs(meshChannels) do
        -- Configure the mesh WiFi for each radio
        uci:section("wireless", "wifi-iface", "wifinet_" .. radio, {
            device = radio,
            mode = "mesh",
            encryption = "sae",
            mesh_id = mesh_id:formvalue(section),
            mesh_fwding = "1",
            mesh_rssi_threshold = "0",
            key = mesh_password:formvalue(section),
            network = "lan"
        })
        uci:set("wireless", radio, "channel", channel)
        uci:delete("wireless", radio, "disabled")
    end

    -- Commit changes and restart WiFi
    uci:commit("wireless")
    sys.call("wifi down")
    sys.call("/etc/init.d/wpad restart")
    sys.call("wifi up")
end


-- ブリッジモード設定の適用
local function dumb_ap()

        -- ルーター用のサービス停止
            local services = {"firewall", "dnsmasq", "odhcpd"}
            for _, service in ipairs(services) do
                if sys.init.enabled(service) then
                    sys.init.stop(service)
                    sys.init.disable(service)
                end
            end
            
            -- LANインターフェースをDHCPクライアントに切り替える
            uci:set("network", "lan", "proto", "dhcp")
            uci:delete("network", "wan")
            uci:delete("network", "wan6")
            uci:delete("network", "lan", "ipaddr")
            uci:delete("network", "lan", "netmask")
            
            -- ホスト名を"WifiAP"に変更する
            uci:set("system", "@system[0]", "hostname", "WifiAP")
            
            -- すべての変更をコミットする
            uci:commit()
            
            -- ファイアウォールの設定を削除する
            os.execute("mv /etc/config/firewall /etc/config/firewall.unused")
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
        http.write("<script>alert('設定変更が完了しました。再起動後は子機モードになります。');</script>")
        dumb_ap()
    end

end

function m.on_after_commit(self)
    http.write("<script>alert('設定変更が完了しました。再起動します。');</script>")
end

return m
