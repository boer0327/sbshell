#!/bin/bash
set -e

# Variables
FWMARK=1
TABLE_ID=100
ROUTE_TABLE_NAME="sbshell"

# Remove routing rules
ip rule del fwmark "$FWMARK" table "$TABLE_ID" || true
ip route flush table "$TABLE_ID" || true

# Remove route table name
sed -i "/\b$TABLE_ID\b.*\b$ROUTE_TABLE_NAME\b/d" /etc/iproute2/rt_tables

# Clean up iptables
iptables -t mangle -F sbshell || true
iptables -t mangle -D PREROUTING -j sbshell || true
iptables -t mangle -X sbshell || true

echo "iptables rules cleaned up successfully."
