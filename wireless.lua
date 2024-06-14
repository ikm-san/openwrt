local uci = require "luci.model.uci".cursor()
local fs = require "nixio.fs"
local sys = require "luci.sys"
local http = require "luci.http"

-- 'ca_setup'設定ファイルを扱うMapを作成
m = Map("ca_setup", "WiFi各種設定")

s = m:section(TypedSection, "wifi-iface")
s.addremove = false
s.anonymous = true

-- 設定の選択肢を定義
choice = s:option(ListValue, "network_config", "設定の選択")
choice:value("wifi", "WiFi接続設定")
choice:value("mesh_parent", "WiFi+メッシュ親機設定")
choice:value("mesh_child", "WiFi+メッシュ子機設定")
choice.default = "wifi"


-- UCIから現在のSSIDとパスワードを取得する関数
function getCurrentWifiSettings()
    local uci = require "luci.model.uci".cursor()
    local ssid = uci:get("wireless", "@wifi-iface[0]", "ssid")
    local password = uci:get("wireless", "@wifi-iface[0]", "key")
    return ssid, password
end

-- 現在のSSIDとパスワードを取得
local current_ssid, current_password = getCurrentWifiSettings()

-- SSIDとパスワードの設定
ssid = s:option(Value, "ssid", "SSID")
ssid.datatype = "maxlength(32)"
if current_ssid ~= nil then
    ssid.default = current_ssid
else
    ssid.default = "OpenWrt"
end

password = s:option(Value, "key", "Password")
if current_password ~= nil then
    password.default = current_password
else
    password.default = "SmartWiFi123-/"
end
password.datatype = "rangelength(8,63)"
password.password = true


ssid:depends("network_config", "wifi")
password:depends("network_config", "wifi")
ssid:depends("network_config", "mesh_parent")
password:depends("network_config", "mesh_parent")
ssid:depends("network_config", "mesh_child")
password:depends("network_config", "mesh_child")

-- mesh backhaulのSSIDとパスワードの設定
mesh_id = s:option(Value, "mesh_id", "Mesh WiFi")
mesh_id.datatype = "maxlength(32)"
mesh_id.default = "WiFi_backhaul"

mesh_password = s:option(Value, "mesh_password", "Password")
mesh_password.default = "G>P~``4*!^oqxP4"
mesh_password.datatype = "rangelength(8,63)" -- WPA/WPA2パスワードの一般的な長さ要件
mesh_password.password = true

mesh_id:depends("network_config", "mesh_parent")
mesh_password:depends("network_config", "mesh_parent")
mesh_id:depends("network_config", "mesh_child")
mesh_password:depends("network_config", "mesh_child")


--WiFiの設定用関数 --
local function configure_WiFi(section)
    -- 初期設定の削除
    uci:delete("wireless", "default_radio0")
    uci:delete("wireless", "default_radio1")
    uci:delete("wireless", "default_radio2")

    local devices = {"radio0", "radio1", "radio2"}
    for index, dev in ipairs(devices) do
        local wifinet = "wifinet" .. index - 1 -- wifinet0 と wifinet1 を作成

        -- 無線デバイスの基本設定を設定
        uci:set("wireless", dev, "country", "JP")
        uci:set("wireless", dev, "disabled", "0")
        
        -- 既存のセクションを確認または新規作成
        local section_exists = false
        uci:foreach("wireless", "wifi-iface", function(s)
            if s['.name'] == wifinet then
                section_exists = true -- セクションが存在する
            end
        end)

        -- セクションが存在しない場合は新規作成
        if not section_exists then
            uci:section("wireless", "wifi-iface", wifinet, {})
        end

        -- セクションの設定を更新
        uci:set("wireless", wifinet, "device", dev)
        uci:set("wireless", wifinet, "mode", "ap")
        -- uci:set("wireless", wifinet, "channel", "auto")
        uci:set("wireless", wifinet, "ssid", ssid:formvalue(section))
        uci:set("wireless", wifinet, "encryption", "sae-mixed")
        uci:set("wireless", wifinet, "key", password:formvalue(section))
        uci:set("wireless", wifinet, "disabled", "0")
        uci:set("wireless", wifinet, "network", "lan")
        uci:set("wireless", wifinet, "ieee80211r", "1")
        uci:set("wireless", wifinet, "mobility_domain", "1234")
        uci:set("wireless", wifinet, "ft_over_ds", "0")
        uci:set("wireless", wifinet, "ft_psk_generate_local", "1")
        uci:set("wireless", wifinet, "wps_pushbutton", "1")
    end
        uci:set("wireless", "radio0", "channel", "11")
        uci:set("wireless", "radio1", "channel", "36")
        uci:set("wireless", "radio0", "channels", "1 6 11")
        uci:set("wireless", "radio1", "channels", "36 40 44 48 52 56 60 64")
end


-- メッシュWiFiバックホール設定
local function configure_meshWiFi(section)
    local devices = {"radio0", "radio1"}
    for index, radio in ipairs(devices) do
        -- Configure the mesh WiFi for each radio
        local wifinet = "wifinet" .. tostring(9 + index)
        uci:section("wireless", "wifi-iface", wifinet, {
            device = radio,
            mode = "mesh",
            encryption = "sae",
            mesh_id = mesh_id:formvalue(section),
            mesh_fwding = "1",
            mesh_rssi_threshold = "0",
            key = mesh_password:formvalue(section),
            network = "lan"
        })
        -- uci:set("wireless", radio, "channel", "auto")
        -- uci:delete("wireless", radio, "disabled")
    end
end

-- batmesh親機設定
local function configure_bat_parent(setion)
        
        -- B.A.T.M.A.N.の設定
        uci:section("network", "interface", "bat0", {
            proto = "batadv",
            routing_algo = "BATMAN_IV",
            bridge_loop_avoidance = "1",
            gw_mode = "server",
            hop_penalty = "30"
        })
        -- uci:commit("network")
    
        -- メッシュインターフェイスの設定
        uci:section("network", "interface", "batmesh", {
            proto = "batadv_hardif",
            master = "bat0"
        })
        -- uci:commit("network")

        -- firewallのzone[0]のnetworkオプションに'lan'と'batmesh'を設定
        uci:set_list("firewall", "@zone[0]", "network", {"lan", "batmesh"})
        -- uci:commit("firewall")

    
        -- ワイヤレス設定
        uci:set("wireless", "wifinet10", "mesh_fwding", "0")
        uci:set("wireless", "wifinet10", "network", "batmesh")
        uci:set("wireless", "wifinet11", "mesh_fwding", "0")
        uci:set("wireless", "wifinet11", "network", "batmesh")
        -- uci:commit("wireless")

        -- LANポートとB.A.T.M.A.N.インターフェイスのブリッジ設定
        uci:set("network", "batmesh", "device", "br-lan")
        uci:set("network", "@device[0]", "ports", "lan1 lan2 lan3 lan4 bat0")
        -- uci:commit("network")
       
end

-- batmesh子機設定
local function configure_bat_child(setion)
        
        -- B.A.T.M.A.N.の設定
        uci:section("network", "interface", "bat0", {
            proto = "batadv",
            routing_algo = "BATMAN_IV",
            bridge_loop_avoidance = "1",
            gw_mode = "client",
            hop_penalty = "30"
        })
        -- uci:commit("network")
    
        -- メッシュインターフェイスの設定
        uci:section("network", "interface", "batmesh", {
            proto = "batadv_hardif",
            master = "bat0"
        })
        -- uci:commit("network")
    
        -- ワイヤレス設定
        uci:set("wireless", "wifinet10", "mesh_fwding", "0")
        uci:set("wireless", "wifinet10", "network", "batmesh")
        uci:set("wireless", "wifinet11", "mesh_fwding", "0")
        uci:set("wireless", "wifinet11", "network", "batmesh")
        -- uci:commit("wireless")

        -- LANポートとB.A.T.M.A.N.インターフェイスのブリッジ設定
        uci:set("network", "batmesh", "device", "br-lan")
        uci:set("network", "@device[0]", "ports", "lan1 lan2 lan3 lan4 bat0")
        -- uci:commit("network")
        
end

-- ブリッジモード設定の適用
local function ap_mode()

        -- ブリッジモード設定の適用

            -- /etc/config/dhcp の設定変更
            uci:delete("dhcp", "lan", "ra_slaac")
            uci:set("dhcp", "lan", "ignore", "1")
    
            -- /etc/config/network の設定変更
            uci:delete("network", "lan", "ipaddr")
            uci:delete("network", "lan", "netmask")
            uci:delete("network", "lan", "ip6assign")
            uci:set("network", "lan", "proto", "dhcp")
    
            -- /etc/config/dhcp の設定変更
            uci:delete("dhcp", "wan")
    
            uci:delete("network", "wan")
            uci:delete("network", "wan6")
        
            -- wanインターフェースをbr-lanに接続
            uci:set("network", "@device[0]", "ports", "lan1 lan2 lan3 lan4 bat0 wan")
        
            -- ホスト名を"AP"に変更する
            uci:set("system", "@system[0]", "hostname", "AP")
            uci:set("system", "@system[0]", "zonename", "Asia/Tokyo")
            uci:set("system", "@system[0]", "timezone", "JST-9")
    
            os.execute('/etc/init.d/firewall disable && /etc/init.d/firewall stop')
            os.execute('/etc/init.d/dnsmasq disable && /etc/init.d/dnsmasq stop')
            os.execute('/etc/init.d/odhcpd disable && /etc/init.d/odhcpd stop')
            os.rename("/etc/config/firewall", "/etc/config/firewall.unused")
end


function choice.write(self, section, value)
        
    http.write("<script>alert('設定変更後、本体のLEDランプが消灯して再起動が完了するまで数分お待ちください。');</script>")    
    
    if value == "wifi" then
        -- WiFi AP設定
            configure_WiFi(section)   
                
    elseif value == "mesh_parent" then
        -- WiFi AP設定
            configure_WiFi(section)   
        -- メッシュWiFi親機設定を適用する処理
            configure_meshWiFi(section)
            configure_bat_parent(section)

    elseif value == "mesh_child" then
        -- WiFi AP設定
            configure_WiFi(section)   
        -- メッシュWiFi子機設定を適用する処理
            configure_meshWiFi(section)
            configure_bat_child(section)
            ap_mode()
    end

end

function m.on_after_commit(self)
    -- LuciのSAVE＆APPLYボタンで設定の反映およびネットワークサービスを再起動する
end

return m
