module("luci.controller.ca_setup", package.seeall)

function index()
    -- CA SETUPのトップレベルエントリを作成
    entry({"admin", "ca_setup"}, firstchild(), _("CA SETUP"), 60).dependent = false
    
    -- IPoE設定タブ
    entry({"admin", "ca_setup", "ipoe"}, cbi("ca_setup/ipoe"), _("Internet接続設定"), 10)

    -- IPoE設定タブ
    entry({"admin", "ca_setup", "wireless"}, cbi("ca_setup/wireless"), _("WiFi接続設定"), 20)

    -- アップデート処理
    entry({"admin", "ca_setup", "update"}, cbi("ca_setup/update"), _("設定ソフトの更新処理"), 20)
    
    -- デバッグ用
    entry({"admin", "ca_setup", "sandbox"}, cbi("ca_setup/sandbox"), _("テスト用"), 60)
end
