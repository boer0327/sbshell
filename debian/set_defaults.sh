#!/bin/bash

# Create sbshell config directory
mkdir -p /etc/sbshell

# Create firewall backend config file if it doesn't exist
if [ ! -f "/etc/sbshell/config" ]; then
    echo 'FIREWALL_BACKEND="nftables"' > /etc/sbshell/config
fi

DEFAULTS_FILE="/etc/sing-box/defaults.conf"

# 提示用户输入参数，如果为空则使用默认值
read -rp "请输入后端地址: " BACKEND_URL
BACKEND_URL=${BACKEND_URL:-$(grep BACKEND_URL $DEFAULTS_FILE | cut -d '=' -f2)}

read -rp "请输入订阅地址: " SUBSCRIPTION_URL
SUBSCRIPTION_URL=${SUBSCRIPTION_URL:-$(grep SUBSCRIPTION_URL $DEFAULTS_FILE | cut -d '=' -f2)}

read -rp "请输入TProxy配置文件地址: " TPROXY_TEMPLATE_URL
TPROXY_TEMPLATE_URL=${TPROXY_TEMPLATE_URL:-$(grep TPROXY_TEMPLATE_URL $DEFAULTS_FILE | cut -d '=' -f2)}

read -rp "请输入TUN配置文件地址: " TUN_TEMPLATE_URL
TUN_TEMPLATE_URL=${TUN_TEMPLATE_URL:-$(grep TUN_TEMPLATE_URL $DEFAULTS_FILE | cut -d '=' -f2)}

# 更新默认配置文件
cat > $DEFAULTS_FILE <<EOF
BACKEND_URL=$BACKEND_URL
SUBSCRIPTION_URL=$SUBSCRIPTION_URL
TPROXY_TEMPLATE_URL=$TPROXY_TEMPLATE_URL
TUN_TEMPLATE_URL=$TUN_TEMPLATE_URL
EOF

echo "默认配置已更新"
