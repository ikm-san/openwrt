module("luci.controller.ca_setup", package.seeall)
-- /usr/lib/lua/luci/controller

function index()
    local page

    -- CA SETUP メニューのみを追加
    page = entry({"admin", "network", "ca_setup"}, cbi("ca_setup/ipoe"), _("CA SETUP"), 60)
    page.dependent = true

    -- IPoE設定のアクション（動作）
    entry({"admin", "ca_setup", "action_ipoe"}, call("action_ipoe"), nil).leaf = true
end

function action_ipoe()
    local setting = luci.http.formvalue("setting")
    if setting then
        -- ここでbashスクリプトを実行する
        -- os.execute("/path/to/bash/script.sh "..setting)
    end
    luci.http.redirect(luci.dispatcher.build_url("admin", "network", "ca_setup"))
end
