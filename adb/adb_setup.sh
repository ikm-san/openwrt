#!/bin/sh

# adblock setup for OAK 19.07

# Function to update opkg with retry logic
retry_update_opkg() {
    local max_retries=3
    local count=0
    local success=0

    while [ $count -lt $max_retries ]; do
        echo "Updating opkg (attempt $(($count + 1))/$max_retries)"
        opkg update && success=1 && break
        count=$(($count + 1))
        echo "opkg update failed. Retrying..."
    done

    if [ $success -eq 0 ]; then
        echo "Failed to update opkg after $max_retries attempts."
        return 1
    fi
}

# Function to install a package with retry logic
retry_install() {
    local package=$1
    local max_retries=3
    local count=0
    local success=0

    while [ $count -lt $max_retries ]; do
        echo "Installing $package (attempt $(($count + 1))/$max_retries)"
        opkg install $package && success=1 && break
        count=$(($count + 1))
        echo "$package installation failed. Retrying..."
    done

    if [ $success -eq 0 ]; then
        echo "Failed to install $package after $max_retries attempts."
        return 1
    fi
}

# Update and install Adblock and Luci
retry_update_opkg || exit 1
retry_install adblock 
retry_install luci-app-adblock

# Add TOFU filter
cd /etc/adblock
gunzip /etc/adblock/adblock.sources.gz
sed -i '$ d' /etc/adblock/adblock.sources  # Remove the last }
echo '    ,"tofu": {
        "url": "https://raw.githubusercontent.com/tofukko/filter/master/Adblock_Plus_list.txt",
        "rule": "BEGIN{FS=\"[|^]\"}/^\\|\\|([[:alnum:]_-]{1,63}\\.)+[[:alpha:]]+\\^(\\$third-party)?$/{print tolower($3)}",
        "size": "S",
        "focus": "ads_analysis",
        "descurl": "https://github.com/tofukko/filter"
    }' >> /etc/adblock/adblock.sources

echo "}" >> /etc/adblock/adblock.sources
gzip /etc/adblock/adblock.sources
cd /

# uci -q del_list adblock.global.adb_sources='tofu'
uci add_list adblock.global.adb_sources='tofu'
uci commit adblock

# Get the router's current IPv4 and IPv6 addresses
ipv4_address=$(uci get network.lan.ipaddr)
ipv6_address=$(ip -6 addr show br-lan | grep 'inet6' | awk '{print $2}' | grep -v '^fe80' | cut -d'/' -f1)

# Remove existing DNS settings for LAN
uci -q delete dhcp.lan.dhcp_option
uci -q delete dhcp.lan.dns

# Add the router's IPv4 and IPv6 as DNS servers
uci add_list dhcp.lan.dhcp_option="6,$ipv4_address"
if [ -n "$ipv6_address" ]; then
  uci add_list dhcp.lan.dns="$ipv6_address"
fi

uci set adblock.global.adb_trigger='lan'
uci set adblock.global.adb_dns='dnsmasq'
uci set adblock.global.adb_forcedns='1'

# Commit changes and restart services
/etc/init.d/adblock enable
/etc/init.d/adblock restart
uci commit dhcp
/etc/init.d/dnsmasq restart


echo "Adblock DNS filtering with TOFU enabled for LAN using $ipv4_address (IPv4) and $ipv6_address (IPv6)."
echo "The automatic configuration of Adblock is complete. It will take a few minutes after a restart for the custom filter to start working." && echo "Adblockの自動設定が完了しました。カスタムフィルタの動作反映まで再起動後、数分かかります。"

# Prompt the user for confirmation to reboot
read -p "再起動を実行しますか？(N/y): " choice

# Handle the user's input for reboot
if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
    echo "Rebooting the system..."
    /sbin/reboot
else
    echo "Reboot canceled."
fi
