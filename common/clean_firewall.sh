#!/bin/bash
set -e

# Get the config file path
CONFIG_FILE="/etc/sbshell/config"

# Check if the config file exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Configuration file not found at $CONFIG_FILE"
    exit 1
fi

# Read the firewall backend
FIREWALL_BACKEND=$(grep -oP 'FIREWALL_BACKEND=\K\w+' "$CONFIG_FILE")

# Stop sing-box service using the common script
"$(dirname "$0")/stop_singbox.sh"

if [ "$FIREWALL_BACKEND" == "iptables" ]; then
    echo "Cleaning iptables rules..."
    "$(dirname "$0")/clean_iptables.sh"
else
    # Clean all nftables rules
    echo "Cleaning all nftables rules..."
    nft flush ruleset
    echo "All nftables rules have been cleaned."
fi
