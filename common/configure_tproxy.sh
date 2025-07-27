#!/bin/sh
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

if [ "$FIREWALL_BACKEND" == "iptables" ]; then
    echo "Using iptables backend."
    # shellcheck source=./configure_tproxy_iptables.sh
    . "$(dirname "$0")/configure_tproxy_iptables.sh"
    exit 0
fi

echo "Using nftables backend."

# --- Configuration ---
# TPROXY_PORT: Port for sing-box TProxy inbound. Must match your sing-box configuration.
TPROXY_PORT=${TPROXY_PORT:-7895}

# ROUTING_MARK: Mark for sing-box outbound traffic. Must match your sing-box configuration.
ROUTING_MARK=${ROUTING_MARK:-666}

# PROXY_FWMARK: Firewall mark for redirecting traffic to the TProxy port.
PROXY_FWMARK=${PROXY_FWMARK:-1}

# PROXY_ROUTE_TABLE: Route table ID for proxy traffic.
PROXY_ROUTE_TABLE=${PROXY_ROUTE_TABLE:-100}

# --- Network Setup ---
# Auto-detect the default interface.
INTERFACE=$(ip route show default | awk '/default/ {print $5; exit}')
if [ -z "$INTERFACE" ]; then
    echo "Error: Could not determine default interface." >&2
    exit 1
fi

# Reserved and bypass IP address sets.
ReservedIP4='{ 127.0.0.0/8, 10.0.0.0/8, 100.64.0.0/10, 169.254.0.0/16, 172.16.0.0/12, 192.0.0.0/24, 192.0.2.0/24, 198.51.100.0/24, 192.88.99.0/24, 192.168.0.0/16, 203.0.113.0/24, 224.0.0.0/4, 240.0.0.0/4, 255.255.255.255/32 }'
CustomBypassIP='{ 192.168.0.0/16, 10.0.0.0/8 }' # Customize as needed.

# --- Functions ---
# Function to check for command existence.
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Error handling function.
handle_error() {
    echo "Error: $1" >&2
    exit 1
}

# Clean up existing sing-box firewall rules and routes.
clear_singbox_rules() {
    echo "Cleaning up existing sing-box firewall rules and routes..."
    nft list table inet sing-box >/dev/null 2>&1 && nft delete table inet sing-box
    ip rule del fwmark "$PROXY_FWMARK" lookup "$PROXY_ROUTE_TABLE" 2>/dev/null || true
    ip route del local default dev "$INTERFACE" table "$PROXY_ROUTE_TABLE" 2>/dev/null || true
    echo "Cleanup complete."
}

# --- Main Script ---
# Verify required commands are available.
for cmd in ip nft; do
    if ! command_exists "$cmd"; then
        handle_error "'$cmd' command not found. Please install it."
    fi
done

echo "Applying TProxy firewall rules..."

# Clean up previous rules before applying new ones.
clear_singbox_rules

# Enable IP forwarding.
sysctl -w net.ipv4.ip_forward=1 > /dev/null

# Set up IP rules and routes with error checking.
echo "Setting up IP rules and routes..."
ip -f inet rule add fwmark "$PROXY_FWMARK" lookup "$PROXY_ROUTE_TABLE" || handle_error "Failed to add firewall mark rule."
ip -f inet route add local default dev "$INTERFACE" table "$PROXY_ROUTE_TABLE" || handle_error "Failed to add local route."
echo "IP rules and routes configured successfully."

# Create directory for nftables configuration if it doesn't exist.
mkdir -p /etc/sing-box/nft

# Define nftables ruleset.
NFT_CONFIG_PATH="/etc/sing-box/nft/tproxy_rules.nft"
cat > "$NFT_CONFIG_PATH" <<EOF
table inet sing-box {
    set RESERVED_IPSET {
        type ipv4_addr
        flags interval
        auto-merge
        elements = $ReservedIP4
    }

    set CUSTOM_BYPASS_IPSET {
        type ipv4_addr
        flags interval
        auto-merge
        elements = $CustomBypassIP
    }

    chain prerouting_tproxy {
        type filter hook prerouting priority mangle; policy accept;

        # Redirect DNS to TProxy port
        meta l4proto { tcp, udp } th dport 53 tproxy to :$TPROXY_PORT accept

        # Bypass custom IPs
        ip daddr @CUSTOM_BYPASS_IPSET accept

        # Reject traffic to local TProxy port to prevent loops
        fib daddr type local meta l4proto { tcp, udp } th dport $TPROXY_PORT reject with icmpx type host-unreachable

        # Bypass local and reserved addresses
        fib daddr type local accept
        ip daddr @RESERVED_IPSET accept

        # Redirect remaining traffic to TProxy
        meta l4proto { tcp, udp } tproxy to :$TPROXY_PORT meta mark set $PROXY_FWMARK
    }

    chain output_tproxy {
        type route hook output priority mangle; policy accept;

        # Allow loopback traffic
        meta oifname "lo" accept

        # Allow sing-box outbound traffic
        meta mark $ROUTING_MARK accept

        # Mark DNS requests from local processes
        meta l4proto { tcp, udp } th dport 53 meta mark set $PROXY_FWMARK

        # Bypass custom and reserved IPs
        ip daddr @CUSTOM_BYPASS_IPSET accept
        fib daddr type local accept
        ip daddr @RESERVED_IPSET accept

        # Mark remaining local traffic
        meta l4proto { tcp, udp } meta mark set $PROXY_FWMARK
    }
}
EOF

# Apply the nftables ruleset.
echo "Applying nftables ruleset..."
nft -f "$NFT_CONFIG_PATH" || handle_error "Failed to apply nftables ruleset."

echo "TProxy mode firewall rules applied successfully."
