#!/bin/sh

# インターフェース名を指定する場合は、この変数を設定
INTERFACE="br-lan"

# IPv6アドレスを表示
if [ -z "$INTERFACE" ]; then
    # インターフェース名が指定されていない場合、全てのインターフェースのIPv6アドレスを表示
    ip -6 addr
else
    # 特定のインターフェースのIPv6アドレスを表示
    ip -6 addr show dev $INTERFACE
fi
