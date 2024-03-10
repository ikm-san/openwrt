#!/bin/bash

# APIのURL
url="https://api.enabler.ne.jp/6823228689437e773f260662947d6239/get_rules"

# curlを使用してデータを取得
response=$(curl -v -s "$url" 2>&1)

# レスポンスの確認
if echo "$response" | grep -q "データの取得に失敗しました"; then
    echo "データの取得に失敗しました。"
elif echo "$response" | grep -q "Could not resolve host"; then
    echo "ホスト名を解決できませんでした。URLが正しいか確認してください。"
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
