local uci = require("luci.model.uci").cursor()
local json = require("luci.jsonc")

local function save_ca_setup_config(json_data)
    -- JSONデータをパース
    local data = json.parse(json_data)

    -- 'ca_setup' configを開くまたは作成する
    uci:section("ca_setup", "settings", nil, {
        dmr = data.dmr,
        id = data.id,
        ipv6_fixlen = data.ipv6_fixlen,
        fmr = json.stringify(data.fmr)  -- fmrはJSON形式の文字列として保存
    })

    -- 設定をコミット
    uci:commit("ca_setup")
end

-- JSONデータを含む変数（この例では直接文字列を渡していますが、実際には外部から取得したデータを使用します）
local json_data = '?({"dmr":"2404:9200:225:100::64","id":"953389bacb479f3df35b112aa0d12d22","ipv6_fixlen":56,"fmr":[{"ipv6":"240b:10::/32","ipv4":"106.72.0.0/16","psid_offset":4,"ea_length":24},{"ipv6":"240b:11::/32","ipv4":"106.73.0.0/16","psid_offset":4,"ea_length":24},{"ipv6":"240b:12::/32","ipv4":"14.8.0.0/16","psid_offset":4,"ea_length":24},{"ipv6":"240b:13::/32","ipv4":"14.9.0.0/16","psid_offset":4,"ea_length":24},{"ipv6":"240b:250::/32","ipv4":"14.10.0.0/16","psid_offset":4,"ea_length":24},{"ipv6":"240b:251::/32","ipv4":"14.11.0.0/16","psid_offset":4,"ea_length":24},{"ipv6":"240b:252::/32","ipv4":"14.12.0.0/16","psid_offset":4,"ea_length":24},{"ipv6":"240b:253::/32","ipv4":"14.13.0.0/16","psid_offset":4,"ea_length":24}]})'

-- JSON文字列から先頭の'?('と末尾の')'を削除（APIからの応答形式に基づく）
json_data = json_data:sub(3, -2)

-- 設定保存関数を呼び出し
save_ca_setup_config(json_data)
