#!/bin/bash

# バックアップファイルのパス
backup_file="/etc/config/network_bk"

# 元のネットワーク設定ファイルのパス
network_file="/etc/config/network"

# バックアップファイルが存在するか確認
if [ -f "$backup_file" ]; then
    # バックアップファイルを元のファイルに上書き
    cp $backup_file $network_file
    
    # ネットワークサービスを再起動
    /etc/init.d/network restart
    
    echo "ネットワーク設定が復元されました。"
else
    echo "バックアップファイルが見つかりません。"
fi
