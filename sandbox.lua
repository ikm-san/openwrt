require "luci.sys"

-- スクリプトのフルパス
local script_path = "/usr/lib/lua/luci/model/cbi/ca_setup/mapv6.lua"
-- cronジョブ
local job = "0 3 * * * /usr/bin/lua " .. script_path .. " \\n"

-- 既存のcrontabにジョブを追加（重複を防ぐためにgrepを使用してチェック）
luci.sys.call("(crontab -l | grep -v -F '" .. script_path .. "' ; echo '" .. job .. "') | crontab -")

-- cronサービスを再起動
luci.sys.call("/etc/init.d/cron restart")
