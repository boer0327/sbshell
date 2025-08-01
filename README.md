# Sbshell
⚠️⚠️请注意禁止搬运到中国大陆，请遵守属地法律法律⚠️⚠️
Sbshell 是一款针对 官方sing-box 的辅助运行脚本，旨在解决官方sing-box的使用不便：

- **系统支持**：支持系统为Debian/Ubuntu/Armbian以及OpenWrt。
- **辅助运行**：保持 sing-box 以官方裸核形式运行，追求极致精简与性能。
- **双模支持**：兼容 TUN 和 TProxy 模式，可随时一键切换，灵活适应不同需求。
- **版本管理**：支持一键切换稳定版与测试版内核，检测并更新至最新版本，操作简单高效。
- **防火墙切换**：TProxy模式支持 `nftables` 和 `iptables` 双防火墙后端，可在菜单中一键切换。
- **灵活配置**：支持手动输入后端地址、订阅链接、配置文件链接，并可设置默认值，提升使用效率。
- **订阅管理**：支持手动更新、定时自动更新，确保订阅和配置始终保持最新。
- **启动控制**：支持手动启动、停止和开机自启管理，操作直观。
- **网络配置**：内置网络配置模块，可快速修改系统 IP、网关和 DNS，自动提示是否需要调整。
- **便捷命令**：集成常用命令，避免手动查找与复制的繁琐。
- **在线更新**：支持脚本在线更新，始终保持最新版本。
- **面板更新**：支持clash面板在线更新/切换。

## 设备支持：

目前支持系统为deiban/ubuntu/armbian以及openwrt！

## 一键脚本：(请自行安装curl和bash，如果缺少的话)
```
bash <(curl -sL https://ghfast.top/https://raw.githubusercontent.com/boer0327/sbshell/refs/heads/main/sbshall.sh)
```
- 初始化运行结束，输入“**sb**”进入菜单
- 目前支持系统为deiban/ubuntu/armbian/openwrt。
- TProxy模式的防火墙后端支持 `nftables` 和 `iptables`，可在菜单中自由切换。
- 非openwrt并使用2.1.2之前版本的用户想要升级并且使用1.12.X版本内核建议卸载重装

## 适配配置文件：

### 稳定版(1.11)：  
tproxy：
https://gh-proxy.com/https://raw.githubusercontent.com/boer0327/sbshell/refs/heads/main/config_template/config_tproxy.json

tun：
https://gh-proxy.com/https://raw.githubusercontent.com/boer0327/sbshell/refs/heads/main/config_template/config_tun.json  

## 其他问题：

**请查看[wiki](https://github.com/qljsyph/sbshell/wiki)**


