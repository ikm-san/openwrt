#!/bin/bash

# 対応するIPv4プレフィックスを定義
declare -A ruleprefix31=(
  [0x240b0010]=106.72.0.0
  [0x240b0012]=14.8.0.0
  [0x240b0250]=14.10.0.0
  [0x240b0252]=14.12.0.0
  [0x24047a80]=133.200.0.0
  [0x24047a84]=133.206.0.0
)

# WANインターフェースのIPv6アドレスを取得
NET_ADDR6=$(ip -6 addr show dev wan | grep 'inet6' | grep -v 'scope link' | awk '{print $2}' | sed -E 's/\/.*$//' | head -n 1)

# IPv6アドレスの先頭32ビットを0x形式で取得し、対応するIPv4プレフィックスを返す関数
getIPv4Prefix() {
    local ipv6=$1

    # IPv6アドレスの先頭32ビットを0x形式で取得
    local prefix=$(echo $ipv6 | sed -E 's/([0-9a-fA-F]{1,4}):([0-9a-fA-F]{1,4}).*/0x\1\2/')

    # 対応するIPv4プレフィックスをルールから検索
    echo "${ruleprefix31[$prefix]}"
}

# IPv4プレフィックスを取得して出力
ipv4Prefix=$(getIPv4Prefix $NET_ADDR6)
if [ -n "$ipv4Prefix" ]; then
    echo "IPv4 Prefix: $ipv4Prefix"
else
    echo "対応するIPv4プレフィックスが見つかりません。"
fi
