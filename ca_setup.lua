-- /usr/lib/lua/luci/controller

module("luci.controller.ca_setup", package.seeall)

function index()
    local page

    -- CA SETUP メニューの追加
    page = entry({"admin", "network", "ca_setup"}, alias("admin", "ca_setup", "ipoe"), _("CA SETUP"), 60)
    page.dependent = true

    -- IPoE設定ページの追加
    page = entry({"admin", "ca_setup", "ipoe"}, cbi("ca_setup/ipoe"), _("IPoE設定"), 10)
    page.dependent = true

    -- その他接続設定ページの追加
    page = entry({"admin", "ca_setup", "others"}, cbi("ca_setup/others"), _("その他接続設定"), 20)
    page.dependent = true

    -- IPoE設定のアクション（動作）
    entry({"admin", "ca_setup", "ipoe", "action"}, call("action_ipoe"), nil).leaf = true

    -- その他の接続設定のアクション（動作）
    entry({"admin", "ca_setup", "others", "action"}, call("action_others"), nil).leaf = true
end

function action_ipoe()
    local setting = luci.http.formvalue("setting")
    if setting then
        -- ここでbashスクリプトを実行する
        -- os.execute("/path/to/bash/script.sh "..setting)
    end
    luci.http.redirect(luci.dispatcher.build_url("admin", "ca_setup", "ipoe"))
end

function action_others()
    local setting = luci.http.formvalue("setting")
    if setting then
        -- ここでbashスクリプトを実行する
        -- os.execute("/path/to/bash/script.sh "..setting)
    end
    luci.http.redirect(luci.dispatcher.build_url("admin", "ca_setup", "others"))
end
