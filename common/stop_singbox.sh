#!/bin/bash
set -e

# Function to stop sing-box service
stop_sing_box() {
    echo "Stopping sing-box service..."
    if command -v systemctl &> /dev/null && systemctl is-active --quiet sing-box; then
        systemctl stop sing-box
    elif [ -f "/etc/init.d/sing-box" ]; then
        /etc/init.d/sing-box stop
    else
        echo "Could not find a way to stop sing-box service."
        exit 1
    fi
    echo "sing-box service stopped."
}

stop_sing_box
