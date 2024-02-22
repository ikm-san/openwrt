#!/bin/bash
# wan6

. /lib/functions/network.sh
network_flush_cache
network_find_wan6 NET_IF6
network_get_ipaddr6 NET_ADDR6 "${NET_IF6}"
# new_ip6_prefix=${NET_ADDR6}

# V6プラス用の値
mape_peeraddr="2404:9200:225:100::64"
mape_ipv6prefixlen="32"
mape_ipv4prefixlen="16"
mape_ealen="24"
mape_psidlen="8"
mape_offset="4"

# AWKを使用して最初の2つのセグメントを取得し、"::/32"を付加 V6プラスの場合のみ
mape_ipv6prefix=$(echo $NET_ADDR6 | awk -F: '{print $1 ":" $2 "::/32"}')
mape_ipv6prefix_conversion=$(echo $NET_ADDR6 | awk -F: '{print $1 ":" $2 "::"}') #IPv4アドレス検索用

# V6プラスの簡易変換テーブル https://ipv4.web.fc2.com/map-e.html
declare -A map_conversion_table=(
    ["240b:10::"]="106.72.0.0"
    ["240b:12::"]="14.8.0.0"
    ["240b:250::"]="14.10.0.0"
    ["240b:252::"]="14.12.0.0"
)
# 簡易変換テーブルからmap-e用のIPv4アドレスを抽出
mape_ipv4address="${map_conversion_table[$mape_ipv6prefix_conversion]}"

# IPv6アドレスからPSIDを抽出する関数　ipv6prefix 32ビット前提
        extract_psid() {
            local ipv6_address=$1
            local ipv6_segment=$(echo "$ipv6_address" | cut -d':' -f4)
            # 16進数の数字を定義
            local hex_num=$ipv6_segment
        
            # 4桁の16進数表記に変換
            local formatted_hex=$(printf "%04x" $((16#$hex_num)))
        
            # 後ろ2桁をカット（先頭2桁を抽出）
            local cut_hex=${formatted_hex:0:2}
        
            # 残った2桁を10進数に変換
            local decimal_value=$((16#$cut_hex))
        
            # 結果を出力
            echo "$decimal_value"
        }
# PSIDを抽出して出力
mape_PSID=$(extract_psid "$NET_ADDR6")　

echo "ipv6 address: $NET_ADDR6"
echo "mape_peeraddr: $mape_peeraddr"
echo "mape_ipv6prefix: $mape_ipv6prefix"
echo "mape_ipv6prefixlen: $mape_ipv6prefixlen"
echo "mape_ipv4address: $mape_ipv4address"
echo "mape_ipv4prefixlen: $mape_ipv4prefixlen"
echo "mape_ealen: $mape_ealen"
echo "mape_psidlen: $mape_psidlen"
echo "mape_offset: $mape_offset"
echo "mape_PSID: $mape_PSID"

# IPv6アドレスを引数として受け取る
ipv6_address=$NET_ADDR6

# IPv6アドレスの先頭16ビットを取得
prefix=$(echo $ipv6_address | cut -d: -f1)

# VNEを判別
case $prefix in
    240b)
        echo "JPIX（v6プラス）"
        ;;
    2404)
        echo "Biglobe（IPv6オプション）"
        ;;
    2400)
        echo "NTTコミュニケーションズ（OCNバーチャルコネクト）"
        ;;
    2409)
        echo "インターネットマルチフィード（transix）"
        ;;
    2001)
        # 2001の場合はさらに細かく確認が必要なので、先頭4文字を再度チェック
        four_prefix=$(echo $ipv6_address | cut -d: -f1,2 | tr -d ":")
        if [[ $four_prefix == "2001f" ]]; then
            echo "アルテリアネットワークス（クロスパス）"
        else
            echo "2001で始まるアドレスですが、詳細なVNEは判別できません"
        fi
        ;;
    2405)
        echo "Asahiネット（v6コネクト）"
        ;;
    *)
        echo "該当するVNEが見つかりません"
        ;;
esac
