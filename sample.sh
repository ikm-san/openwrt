#!/bin/bash

# APIのURL
url="https://api.enabler.ne.jp/6823228689437e773f260662947d6239/get_rules"

# curlを使用してデータを取得（SSL証明書の検証を無視）
response=$(curl -k -s "$url")

# レスポンスの確認
if [ -z "$response" ]; then
    echo "データの取得に失敗しました。"
else
    # JSONP応答からJSON部分のみを抽出
    map_rules=$(echo $response | sed -n 's/^.*(\(.*\)).*$/\1/p')
    
    if [ -z "$map_rules" ]; then
        echo "JSONPからJSONを抽出できませんでした。"
    else
        echo "データの取得に成功しました:"
        echo "$map_rules"
    fi
fi
