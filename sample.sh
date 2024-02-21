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
    local ipv6_PSIDcalc=$NET_ADDR6  # 引数からIPv6アドレスを受け取る場合
    # IPv6アドレスを':'で分割し、第4セグメント（IPv4変換サフィックスとPSIDを含む）を取得
    local segment=$(echo $ipv6_PSIDcalc | cut -d':' -f4)
    # セグメントの長さを確認し、4文字未満の場合はゼロ埋めを行う
    local segment_length=${#ipv6_segment}
    if (( segment_length < 4 )); then
        # 16ビット値が省略形で表現されている場合、ゼロ埋めを行う
        local padded_segment=$(printf '%04x' $((16#$ipv6_segment)))
        ipv6_segment=$padded_segment
    fi
    # ゼロ埋め後の値から前半8ビットを抽出
    local psid_hex=${ipv6_segment:0:2}
    # 16進数を10進数に変換
    local psid_dec=$((16#$psid_hex))
    # PSIDを出力
    echo $psid_dec
}

# PSIDを抽出して出力
extract_psid "$NET_ADDR6"


extract_psid() {
    local ipv6_segment=$(echo $ipv6_PSIDcalc | cut -d':' -f4)
