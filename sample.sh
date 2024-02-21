#!/bin/bash
# wan6

. /lib/functions/network.sh
network_flush_cache
network_find_wan6 NET_IF6
network_get_ipaddr6 NET_ADDR6 "${NET_IF6}"
new_ip6_prefix=${NET_ADDR6}

echo $NET_IF6
echo $NET_ADDR6

# AWKを使用して最初の2つのセグメントを取得し、"::/32"を付加 V6プラスの場合のみ
ip6mape_prefix=$(echo $NET_ADDR6 | awk -F: '{print $1 ":" $2 "::/32"}')
ip6prefix=$(echo $NET_ADDR6 | awk -F: '{print $1 ":" $2 "::"}')

echo $ip6mape_prefix

# IPv6アドレスからPSIDを抽出する関数　prefixが32ビット前提
extract_psid() {
    local ipv6_address=$1
    local ipv6_segment=$(echo "$ipv6_address" | cut -d':' -f4)
    # 16進数の数字を定義
    local hex_num=$ipv6_segment

    # 4桁の16進数表記に変換
    local formatted_hex=$(printf "%04x" $((16#$hex_num)))

    # 後ろ2桁をカット（先頭2桁を抽出）
    local cut_hex=${formatted_hex:0:2}

    # 残った2桁を10進数に変換
    local decimal_value=$((16#$cut_hex))

    # 結果を出力
    echo "$decimal_value"
}

# PSIDを抽出して 出力
mape_PSID=$(extract_psid "$NET_ADDR6")
echo "mape_PSID: $mape_PSID"
