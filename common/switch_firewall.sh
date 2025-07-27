#!/bin/bash

# Get the config file path
CONFIG_FILE="/etc/sbshell/config"

# Check if the config file exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Configuration file not found at $CONFIG_FILE"
    exit 1
fi

# Read the current firewall backend
CURRENT_BACKEND=$(grep -oP 'FIREWALL_BACKEND=\K\w+' "$CONFIG_FILE")

# Toggle the backend
if [ "$CURRENT_BACKEND" == "nftables" ]; then
    NEW_BACKEND="iptables"
else
    NEW_BACKEND="nftables"
fi

# Update the config file
sed -i "s/FIREWALL_BACKEND=$CURRENT_BACKEND/FIREWALL_BACKEND=$NEW_BACKEND/" "$CONFIG_FILE"

echo "Firewall backend switched from $CURRENT_BACKEND to $NEW_BACKEND."
