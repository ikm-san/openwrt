module("luci.controller.ca_setup", package.seeall)
-- /usr/lib/lua/luci/controller

function index()
    local page

    -- CA SETUP メニューの追加 (カテゴリとして定義し、デフォルトでIPoEページを表示)
    page = node("admin", "network", "ca_setup")
    page.target = alias("admin", "network", "ca_setup", "ipoe")
    page.title = _("CA SETUP")
    page.order = 60

    -- IPoE設定ページの追加
    entry({"admin", "network", "ca_setup", "ipoe"}, cbi("ca_setup/ipoe"), _("IPoE設定"), 10)

    -- その他接続設定ページの追加
    entry({"admin", "network", "ca_setup", "others"}, cbi("ca_setup/others"), _("その他接続設定"), 20)

    -- IPoE設定のアクション（動作）
    entry({"admin", "network", "ca_setup", "ipoe", "action"}, call("action_ipoe"), nil).leaf = true

    -- その他の接続設定のアクション（動作）
    entry({"admin", "network", "ca_setup", "others", "action"}, call("action_others"), nil).leaf = true
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
