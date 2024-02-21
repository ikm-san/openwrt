#!/bin/sh
# wan6
# 

. /lib/functions/network.sh
network_flush_cache
network_find_wan6 NET_IF6
network_get_ipaddr6 NET_ADDR6 "${NET_IF6}"
new_ip6_prefix=${NET_ADDR6}

echo $NET_IF6
echo $NET_ADDR6

# AWKを使用して最初の2つのセグメントを取得し、"::/32"を付加
ip6mape_prefix=$(echo $NET_ADDR6 | awk -F: '{print $1 ":" $2 "::/32"}')
ip6prefix=$(echo $NET_ADDR6 | awk -F: '{print $1 ":" $2 "::"}')

echo $ip6mape_prefix

# プレフィックスの長さ (例: 32ビット)
prefix_length=32

# IPv6アドレスからPSIDを抽出する関数
extract_psid() {
    local ipv6=$NET_ADDR6

    # IPv6アドレスをコロンで分割し、IPv4のサフィックスの部分を取得
    local suffix=$(echo $ipv6 | cut -d':' -f3)

    # PSIDの部分を取得 (次の16ビットのセグメントの前半8ビット)
    local psid_hex=$(echo $ipv6 | cut -d':' -f4 | cut -c1-2)
    
    echo $psid_hex
    
    # 16進数を10進数に変換
    local psid_dec=$((16#$psid_hex))

    echo $psid_dec
}

# 関数を呼び出してPSIDを算出
psid=$(extract_psid $ipv6_addr)
echo "PSID: $psid"
