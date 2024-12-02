#!/bin/bash

# Function to get internal IP
get_internal_ip() {
    ip route get 1 | awk '{print $7; exit}'
}

# Function to get external IP using API
get_external_ip() {
    # Try multiple APIs in case one fails
    local external_ip

    # Try ipify API first
    external_ip=$(curl -s -f "https://api.ipify.org")
    if [ $? -eq 0 ] && [ ! -z "$external_ip" ]; then
        echo "$external_ip"
        return
    fi

    # Fallback to ipapi if ipify fails
    external_ip=$(curl -s -f "https://ipapi.co/ip/")
    if [ $? -eq 0 ] && [ ! -z "$external_ip" ]; then
        echo "$external_ip"
        return
    fi

    # Second fallback to icanhazip
    external_ip=$(curl -s -f "https://icanhazip.com")
    if [ $? -eq 0 ] && [ ! -z "$external_ip" ]; then
        echo "$external_ip"
        return
    fi

    # If all APIs fail, return error message
    echo "Failed to get IP"
}

# Function to get network interface name
get_interface() {
    ip route get 1 | awk '{print $5; exit}'
}

# Function to get connection type (wifi/ethernet)
get_connection_type() {
    local interface=$(get_interface)
    if [[ $interface == wlan* ]]; then
        echo "WiFi"
    elif [[ $interface == eth* ]]; then
        echo "Ethernet"
    else
        echo "Unknown"
    fi
}

# Function to get current wifi SSID if on wifi
get_wifi_ssid() {
    local interface=$(get_interface)
    if [[ $interface == wlan* ]]; then
        iwgetid -r
    else
        echo ""
    fi
}

case $1 in
    "internal")
        internal_ip=$(get_internal_ip)
        if [ ! -z "$internal_ip" ]; then
            echo "$internal_ip"
            echo "$internal_ip" | wl-copy
            notify-send "IP Copied" "Internal IP ($internal_ip) copied to clipboard" -t 2000
        else
            notify-send "Error" "Failed to get internal IP" -t 2000
        fi
        ;;
    "external")
        external_ip=$(get_external_ip)
        if [ ! -z "$external_ip" ] && [ "$external_ip" != "Failed to get IP" ]; then
            echo "$external_ip"
            echo "$external_ip" | wl-copy
            notify-send "IP Copied" "External IP ($external_ip) copied to clipboard" -t 2000
        else
            notify-send "Error" "Failed to get external IP" -t 2000
        fi
        ;;
    *)
        internal_ip=$(get_internal_ip)
        connection_type=$(get_connection_type)
        wifi_ssid=$(get_wifi_ssid)

        # Build tooltip with network information
        tooltip="Connection Type: $connection_type"
        if [ ! -z "$wifi_ssid" ]; then
            tooltip="$tooltip\nSSID: $wifi_ssid"
        fi
        tooltip="$tooltip\nInternal IP: $internal_ip\n\nLeft click: Show/copy external IP\nRight click: Copy internal IP"

        # Output JSON for waybar
        echo "{\"text\": \"$internal_ip\", \"tooltip\": \"$tooltip\"}"
        ;;
esac
