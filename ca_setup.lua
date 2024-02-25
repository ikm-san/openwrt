module("luci.controller.ca_setup", package.seeall)

function index()
    -- CA SETUPのトップレベルエントリを作成
    entry({"admin", "ca_setup"}, firstchild(), _("CA SETUP"), 60).dependent = false
    
    -- IPoE設定タブ
    entry({"admin", "ca_setup", "ipoe"}, cbi("ca_setup/ipoe"), _("IPoE設定"), 10)
    
    -- その他接続設定タブ
    entry({"admin", "ca_setup", "other"}, cbi("ca_setup/others"), _("設定の復元保存"), 60)
end
