module("luci.controller.ca_setup", package.seeall)

function index()
    -- CA SETUPのトップレベルエントリ
    entry({"admin", "ca_setup"}, firstchild(), _("CA接続設定"), 60).dependent = false
    
    -- IPoE設定タブ
    entry({"admin", "ca_setup", "ipoe"}, cbi("ca_setup/ipoe"), _("Internet接続設定"), 10)

    -- WiFi設定タブ
    if nixio.fs.access("/etc/config/wireless") then
        entry({"admin", "ca_setup", "wireless"}, cbi("ca_setup/wireless"), _("WiFi接続設定"), 20)
    end
    
    -- デバッグ用
    -- entry({"admin", "ca_setup", "sandbox"}, cbi("ca_setup/sandbox"), _("テスト用"), 60)

    
end
