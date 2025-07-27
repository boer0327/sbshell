#!/bin/bash
set -e

# 定义颜色
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m' # 无颜色

# 手动输入的配置文件
MANUAL_FILE="/etc/sing-box/manual.conf"
UPDATE_SCRIPT="/etc/sing-box/update-singbox.sh"

# 创建定时更新脚本
cat > "$UPDATE_SCRIPT" <<EOF
#!/bin/bash
set -e

# 读取手动输入的配置参数
BACKEND_URL=\$(grep "BACKEND_URL" "$MANUAL_FILE" | cut -d'=' -f2-)
SUBSCRIPTION_URL=\$(grep "SUBSCRIPTION_URL" "$MANUAL_FILE" | cut -d'=' -f2-)
TEMPLATE_URL=\$(grep "TEMPLATE_URL" "$MANUAL_FILE" | cut -d'=' -f2-)

# 构建完整的配置文件URL
FULL_URL="\${BACKEND_URL}/config/\${SUBSCRIPTION_URL}&file=\${TEMPLATE_URL}"

# 备份现有配置文件
[ -f "/etc/sing-box/config.json" ] && cp "/etc/sing-box/config.json" "/etc/sing-box/config.json.backup"

# 下载并验证新配置文件
if curl --fail -L --connect-timeout 10 --max-time 30 "\$FULL_URL" -o "/etc/sing-box/config.json"; then
    if ! sing-box check -c "/etc/sing-box/config.json"; then
        echo "新配置文件验证失败，恢复备份..."
        [ -f "/etc/sing-box/config.json.backup" ] && cp "/etc/sing-box/config.json.backup" "/etc/sing-box/config.json"
    fi
else
    echo "下载配置文件失败，恢复备份..."
    [ -f "/etc/sing-box/config.json.backup" ] && cp "/etc/sing-box/config.json.backup" "/etc/sing-box/config.json"
fi

# 重启 sing-box 服务
if command -v systemctl >/dev/null 2>&1; then
    systemctl restart sing-box
elif command -v /etc/init.d/sing-box >/dev/null 2>&1; then
    /etc/init.d/sing-box restart
fi
EOF

chmod a+x "$UPDATE_SCRIPT"

# 检查 crontab 是否可用
if ! command -v crontab >/dev/null 2>&1; then
    echo -e "${RED}crontab 命令不存在，无法设置定时任务。${NC}"
    exit 1
fi

while true; do
    echo -e "${CYAN}请选择操作:${NC}"
    echo "1. 设置自动更新间隔"
    echo "2. 取消自动更新"
    read -rp "请输入选项 (1或2, 默认为1): " menu_choice
    menu_choice="\${menu_choice:-1}"

    if [[ "$menu_choice" == "1" ]]; then
        while true; do
            read -rp "请输入更新间隔小时数 (1-23小时,默认为12小时): " interval_choice
            interval_choice="\${interval_choice:-12}"

            if [[ "$interval_choice" =~ ^[1-9]$|^1[0-9]$|^2[0-3]$ ]]; then
                break
            else
                echo -e "${RED}输入无效,请输入1到23之间的小时数。${NC}"
            fi
        done

        if crontab -l 2>/dev/null | grep -q "$UPDATE_SCRIPT"; then
            echo -e "${RED}检测到已有自动更新任务。${NC}"
            read -rp "是否重新设置自动更新任务？(y/n): " confirm_reset
            if [[ "$confirm_reset" =~ ^[Yy]$ ]]; then
                crontab -l 2>/dev/null | grep -v "$UPDATE_SCRIPT" | crontab -
                echo "已删除旧的自动更新任务。"
            else
                echo -e "${CYAN}保持已有的自动更新任务。返回菜单。${NC}"
                exit 0
            fi
        fi

        # 添加新的定时任务
        (crontab -l 2>/dev/null; echo "0 */\$interval_choice * * * $UPDATE_SCRIPT") | crontab -

        echo "定时更新任务已设置，每 $interval_choice 小时执行一次"
        break

    elif [[ "$menu_choice" == "2" ]]; then
        # 取消自动更新任务
        if crontab -l 2>/dev/null | grep -q "$UPDATE_SCRIPT"; then
            crontab -l 2>/dev/null | grep -v "$UPDATE_SCRIPT" | crontab -
            echo -e "${CYAN}自动更新任务已取消。${NC}"
        else
            echo -e "${CYAN}没有找到自动更新任务。${NC}"
        fi
        break

    else
        echo -e "${RED}输入无效, 请输入1或2。${NC}"
    fi
done
