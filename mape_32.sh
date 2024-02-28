#!/bin/bash

# WANインターフェースのIPv6アドレスの先頭32ビットを0x形式で取得
NET_ADDR6=$(ip -6 addr show dev wan | grep 'inet6' | grep -v 'scope link' | awk '{print $2}' | sed -E 's/\/.*$//' | head -n 1)
PREFIX_HEX=$(echo $NET_ADDR6 | cut -d':' -f1,2 | sed -E 's/([0-9a-fA-F]+):([0-9a-fA-F]+).*/\1\2/' | tr 'a-f' 'A-F')
PREFIX_HEX="0x$PREFIX_HEX"

# IPv6アドレスの先頭32ビットを基に対応するIPv4プレフィックスを検索し、フォーマットして返す関数
getIPv4Prefix() {
    local prefix=$1
    local ipv4_prefix=${ruleprefix31[$prefix]}
    if [ -n "$ipv4_prefix" ]; then
        # ルールに基づきIPv4プレフィックスを取得し、フォーマットする
        IFS=',' read -r -a ipv4_parts <<< "$ipv4_prefix"
        printf "%d.%d.0.0\n" "${ipv4_parts[0]}" "${ipv4_parts[1]}"
    else
        echo "対応するIPv4プレフィックスが見つかりません。"
    fi
}

# IPv4プレフィックスを取得して出力
ipv4Prefix=$(getIPv4Prefix $PREFIX_HEX)
echo "IPv4 Prefix: $ipv4Prefix"

# ルールの定義をそのまま使用
declare -A ruleprefix31=(
  [0x240b0010]=106,72
  [0x240b0012]=14,8
  [0x240b0250]=14,10
  [0x240b0252]=14,12
  [0x24047a80]=133,200
  [0x24047a84]=133,206
)
