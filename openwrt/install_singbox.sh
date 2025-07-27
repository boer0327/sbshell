#!/bin/bash

# 定义颜色
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m' # 无颜色

install_dependencies() {
    local packages_to_install=()

    # Source the config file if it exists
    if [ -f /etc/sbshell/config ]; then
        source /etc/sbshell/config
    fi

    # Set default if not set
    FIREWALL_BACKEND=${FIREWALL_BACKEND:-nftables}

    # 检查防火墙依赖
    if [ "$FIREWALL_BACKEND" = "iptables" ]; then
        if ! opkg list-installed | grep -q "kmod-ipt-tproxy"; then
            packages_to_install+=("kmod-ipt-tproxy")
        fi
        if ! opkg list-installed | grep -q "iptables-nft"; then
            packages_to_install+=("iptables-nft")
        fi
    else # Default to nftables
        if ! opkg list-installed | grep -q "kmod-nft-tproxy"; then
            packages_to_install+=("kmod-nft-tproxy")
        fi
    fi

    # 检查 sing-box 是否已安装
    if ! command -v sing-box &> /dev/null; then
        packages_to_install+=("sing-box")
    fi

    if [ ${#packages_to_install[@]} -gt 0 ]; then
        echo "正在更新包列表并安装所需软件包..."
        opkg update >/dev/null 2>&1
        for pkg in "${packages_to_install[@]}"; do
            echo "正在安装 $pkg..."
            opkg install "$pkg" >/dev/null 2>&1
            if [ $? -ne 0 ]; then
                echo -e "${RED}$pkg 安装失败，请检查网络或手动安装。${NC}"
                # 根据需求决定是否退出
            fi
        done
    else
        echo -e "${CYAN}所有必需的软件包都已安装。${NC}"
    fi
}

# 检查 sing-box 是否已安装
if command -v sing-box &> /dev/null; then
    echo -e "${CYAN}sing-box 已安装，跳过安装步骤${NC}"
else
    install_dependencies
    if ! command -v sing-box &> /dev/null; then
        echo -e "${RED}sing-box 安装失败，请检查日志或网络配置${NC}"
        exit 1
    else
        echo -e "${CYAN}sing-box 安装成功${NC}"
    fi
fi

# 添加启动和停止命令到现有服务脚本
if [ -f /etc/init.d/sing-box ]; then
    sed -i '/start_service()/,/}/d' /etc/init.d/sing-box
    sed -i '/stop_service()/,/}/d' /etc/init.d/sing-box
fi

cat << 'EOF' >> /etc/init.d/sing-box

start_service() {
    procd_open_instance
    procd_set_param command /usr/bin/sing-box run -c /etc/sing-box/config.json
    procd_set_param respawn
    procd_set_param stderr 1
    procd_set_param stdout 1
    procd_close_instance

    # 等待服务完全启动
    sleep 3

    # 读取模式并应用防火墙规则
    MODE=$(grep -oE '^MODE=.*' /etc/sing-box/mode.conf | cut -d'=' -f2)
    if [ "$MODE" = "TProxy" ]; then
        /etc/sing-box/scripts/configure_tproxy.sh
    elif [ "$MODE" = "TUN" ]; then
        /etc/sing-box/scripts/configure_tun.sh
    fi
}

stop_service() {
    procd_kill "$NAME" 2>/dev/null
}
EOF

chmod +x /etc/init.d/sing-box

/etc/init.d/sing-box enable
/etc/init.d/sing-box start

echo -e "${CYAN}sing-box 服务已启用并启动${NC}"
