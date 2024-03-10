#!/bin/bash

# APIのURL
url="https://api.enabler.ne.jp/6823228689437e773f260662947d6239/get_rules"

# curlを使用してデータを取得
response=$(curl -s "$url")

echo "取得したデータ:"
echo "$map_rules"
