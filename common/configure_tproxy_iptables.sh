#!/bin/bash
set -e

# Variables
FWMARK=1
TPROXY_PORT=1080
TABLE_ID=100
ROUTE_TABLE_NAME="sbshell"

# Create new chain
iptables -t mangle -N sbshell
iptables -t mangle -A sbshell -p tcp -j TPROXY --on-port "$TPROXY_PORT" --tproxy-mark "$FWMARK/0xffffffff"
iptables -t mangle -A sbshell -p udp -j TPROXY --on-port "$TPROXY_PORT" --tproxy-mark "$FWMARK/0xffffffff"

# Apply to PREROUTING
iptables -t mangle -A PREROUTING -j sbshell

# Add routing rules
ip rule add fwmark "$FWMARK" table "$TABLE_ID"
ip route add local 0.0.0.0/0 dev lo table "$TABLE_ID"

# Add route table name
if ! grep -q "$TABLE_ID $ROUTE_TABLE_NAME" /etc/iproute2/rt_tables; then
    echo "$TABLE_ID $ROUTE_TABLE_NAME" >> /etc/iproute2/rt_tables
fi

echo "iptables TProxy configured successfully."
