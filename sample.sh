#!/bin/bash

# APIのURL
url="url here"

# curlを使用してデータを取得
map_rules=$(curl -s "$url")

echo "取得したデータ:"
echo "$map_rules"
