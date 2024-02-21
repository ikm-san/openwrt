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

# IPv6アドレスを引数から受け取る
ipv6_PSIDcalc= $NET_ADDR6

# IPv6アドレスからPSIDを抽出する関数
extract_psid() {
    # IPv6アドレスを':'で分割し、第4セグメント（IPv4変換サフィックスとPSIDを含む）を取得
    local segment=$(echo $ipv6_PSIDcalc | cut -d':' -f4)
    # 第4セグメントから先頭2文字（16ビットのうちPSIDを含む前半8ビット）を取得
    local psid_hex=${segment:0:2}
    # 16進数を10進数に変換
    local psid_dec=$((16#$psid_hex))
    # PSIDを出力
    echo $psid_dec
}

# PSIDを抽出して出力
extract_psid $ipv6_PSIDcalc
