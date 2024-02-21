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
prefix=$(echo $NET_ADDR6 | awk -F: '{print $1 ":" $2 "::/32"}')

echo $prefix
