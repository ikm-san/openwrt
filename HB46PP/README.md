# HB46PP Get Rule OpenWrt対応PJ

有志の方、ご参加いただけないでしょうか？  
OpenWrtルーターでHB46PP日本国内向け標準プロビ方式で各種パラメーターを取得できるようにしませんか？  
専用FQDN(4over6.info）に問い合わせを行い、DNSよりmap rule等のサーバー情報を取得し、その情報を用いて、IPv6接続に必要な各種データを専用のルールサーバーより取得します。
ここまで対応できれば、応用展開可能になります。

## 対応VNE
- BIGLOBE
- ASAHIネット  
※そのほかのVNEは現状対応しておらず非公開です。

## たたき台スクリプト
```
#!/usr/bin/env lua

local io = require("io")
local os = require("os")
local http = require("socket.http")
local ltn12 = require("ltn12")
local json = require("cjson")

-- DNSからプロビジョニングサーバのURLを取得する関数
function get_provisioning_url()
    local nslookup_output = io.popen("nslookup -type=txt 4over6.info")
    local dns_record = nslookup_output:read("*all")
    nslookup_output:close()
    
    local url = dns_record:match('"url=([^ "]+)')
    if not url then
        error("Error: Unable to find provisioning server URL from DNS records.")
    end
    return url
end

-- プロビジョニングデータを取得する関数
function fetch_provisioning_data(url)
    local response = {}
    local result, status = http.request({
        url = url,
        sink = ltn12.sink.table(response),
        method = "GET",
        headers = {
            ["vendorid"] = "acde48-v6pc_swg_hgw",
            ["product"] = "V6MIG-ROUTER",
            ["version"] = "0_00",
            ["capability"] = "map_e,dslite,lw4o6,ipip"
        }
    })
    if not result then
        error("Error: Failed to retrieve provisioning data from the server.")
    end
    return table.concat(response)
end

-- プロビジョニングデータを抽出して表示する関数
function extract_data(json_data)
    local data = json.decode(json_data)
    print("Extracted MAP-E Data:")
    print(json.encode(data.map_e))
    
    print("Extracted DS-Lite Data:")
    print(json.encode(data.dslite))
    
    print("Extracted IPIP Data:")
    print(json.encode(data.ipip))
end

-- メイン処理
local function main()
    local url = get_provisioning_url()
    print("Provisioning server URL obtained: " .. url)

    local json_data = fetch_provisioning_data(url)
    print("Provisioning data retrieved successfully.")

    extract_data(json_data)
end

main()
```

## 規格リファレンス
[IPv6マイグレーョン技術の国内標準プロビジョニング方式](https://github.com/v6pc/v6mig-prov/blob/1.1/spec.md)

## 参照先
https://gist.github.com/stkchp/4daea9158439c32d7a70a255d51e568b#file-get-dslite-aftr-in-asahinet-md
