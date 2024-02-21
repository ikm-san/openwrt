#!/bin/bash
# wan6

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

# IPv6アドレスからPSIDを抽出する関数
extract_psid() {
    local ipv6_segment=$(echo $ipv6_PSIDcalc | cut -d':' -f4)
    # IPv6セグメント（16ビット）を2進数に変換
    local binary_segment=$(echo "obase=2; ibase=16; ${ipv6_segment^^}" | bc)
    
    # 2進数の値が16ビット未満の場合、前に0を追加して16ビットにする
    while [ ${#binary_segment} -lt 16 ]; do
        binary_segment="0$binary_segment"
    done
    
    # 2進数の値から後半8ビットを削除（前半8ビットを取得）
    local front_half_binary=${binary_segment:0:8}
    
    # 前半8ビットを10進数に変換
    local front_half_decimal=$(echo "obase=10; ibase=2; ${front_half_binary}" | bc)
    
    echo $front_half_decimal
}

# PSIDを抽出して出　力
extract_psid "$NET_ADDR6"
