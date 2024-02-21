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
    local prefix_len=prefix_length

    # プレフィックス以外のビット数を計算
    local suffix_bits=$((128 - prefix_len))

    # IPv6アドレスを16進数のブロックに分割
    IFS=':' read -ra ADDR <<< "$ipv6"

    # プレフィックス以外の部分を取得
    local non_prefix_part=""
    for (( i=0; i<${#ADDR[@]}; i++ )); do
        if (( i >= prefix_len / 16 )); then
            non_prefix_part+="${ADDR[i]}"
        fi
    done

    # PSIDの位置を計算 (ここではプレフィックスが32ビットの場合の例を基にしています)
    # これをダイナミックに変更するためには、プレフィックスの長さに応じて調整する
    local psid_hex=${non_prefix_part:4:4} # af40の次のセグメント

    # 16進数を10進数に変換
    local psid_dec=$((16#$psid_hex))

    echo $psid_dec
}

# 関数を呼び出してPSIDを算出
psid=$(extract_psid "$ipv6_addr" $prefix_length)
echo "PSID: $psid"
