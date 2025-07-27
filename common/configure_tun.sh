#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Configuration ---
# Firewall mark for sing-box traffic
PROXY_FWMARK=1
# Route table for sing-box traffic
PROXY_ROUTE_TABLE=100
# Get the default network interface
INTERFACE=$(ip route show default | awk '/default/ {print $5}')

# --- Error Handling ---
# Function to print an error message and exit
# Usage: error_exit "Error message"
error_exit() {
    echo "Error: $1" >&2
    exit 1
}

# --- Rule Cleanup ---
# Clean up firewall rules from TProxy mode
clear_tproxy_rules() {
    echo "Cleaning up TProxy firewall rules..."
    # Check if the sing-box table exists before trying to delete it
    if nft list table inet sing-box &>/dev/null; then
        nft delete table inet sing-box || error_exit "Failed to delete nftables table 'inet sing-box'."
    fi
    # Suppress errors if the rule or route doesn't exist
    ip rule del fwmark "$PROXY_FWMARK" lookup "$PROXY_ROUTE_TABLE" 2>/dev/null
    ip route del local default dev "$INTERFACE" table "$PROXY_ROUTE_TABLE" 2>/dev/null
    echo "TProxy firewall rules cleaned up successfully."
}

# --- Main Logic ---
echo "Applying TUN mode firewall rules..."

# Clean up any lingering TProxy rules first
clear_tproxy_rules

# Define the directory for TUN configuration
TUN_CONFIG_DIR="/etc/sing-box/tun"

# Ensure the configuration directory exists
mkdir -p "$TUN_CONFIG_DIR" || error_exit "Failed to create directory '$TUN_CONFIG_DIR'."

# Create a basic nftables configuration for TUN mode
# This configuration flushes all existing rules and sets a default accept policy.
NFT_CONFIG_PATH="$TUN_CONFIG_DIR/nftables.conf"
cat > "$NFT_CONFIG_PATH" <<EOF
# Flush the entire ruleset
flush ruleset

# Create a new table 'filter' for basic traffic filtering
table inet filter {
    # Default chains with 'accept' policy
    chain input { type filter hook input priority 0; policy accept; }
    chain forward { type filter hook forward priority 0; policy accept; }
    chain output { type filter hook output priority 0; policy accept; }
}
EOF

echo "Applying new nftables rules from $NFT_CONFIG_PATH..."
# Apply the new firewall rules
nft -f "$NFT_CONFIG_PATH" || error_exit "Failed to apply nftables rules from '$NFT_CONFIG_PATH'."

echo "TUN mode firewall rules applied successfully."
