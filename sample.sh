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

# IPv6アドレスから最初の32ビット（最初の2つのセグメント）を抜き出し
prefix=$(echo $NET_ADDR6 | cut -d':' -f1,2)

# /32を付加して結果を表示
echo "${prefix}::/32"
