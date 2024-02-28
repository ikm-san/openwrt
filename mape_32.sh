#!/bin/bash

# 必要なライブラリの読み込み
. /lib/functions/network.sh

# 定義されたルール
declare -A ruleprefix31=(
  [0x240b0010]=106,72
  [0x240b0012]=14,8
  [0x240b0250]=14,10
  [0x240b0252]=14,12
  [0x24047a80]=133,200
  [0x24047a84]=133,206
)

# WANのIPv6アドレスを取得する関数
getWANIPv6() {
    local wan_ipv6
    network_get_ipaddr6 wan_ipv6 wan
    echo $wan_ipv6
}

# IPv6アドレスの先頭32ビットを0x形式で取得し、対応するIPv4プレフィックスを返す関数
getIPv4Prefix() {
    local ipv6=$1
    local prefix=$(echo $ipv6 | sed -E 's/([0-9a-fA-F]{1,4}):([0-9a-fA-F]{1,4}).*/0x\1\2/')
    local ipv4_prefix=${ruleprefix31[$prefix]}
    if [ -n "$ipv4_prefix" ]; then
        IFS=',' read -r ip1 ip2 <<< "$ipv4_prefix"
        echo "$ip1.$ip2.0.0"
    else
        echo "対応するIPv4プレフィックスが見つかりません。"
    fi
}

# WANのIPv6アドレスを取得
ipv6=$(getWANIPv6)

# IPv4プレフィックスを取得
ipv4Prefix=$(getIPv4Prefix $ipv6)
echo "IPv4 Prefix: $ipv4Prefix"
