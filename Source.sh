#!/bin/bash

# 定义颜色输出函数
red() { echo -e "\033[31m\033[01m[WARNING] $1\033[0m"; }
green() { echo -e "\033[32m\033[01m[INFO] $1\033[0m"; }
greenline() { echo -e "\033[32m\033[01m $1\033[0m"; }
yellow() { echo -e "\033[33m\033[01m[NOTICE] $1\033[0m"; }
blue() { echo -e "\033[34m\033[01m[MESSAGE] $1\033[0m"; }
light_magenta() { echo -e "\033[95m\033[01m[NOTICE] $1\033[0m"; }
highlight() { echo -e "\033[32m\033[01m$1\033[0m"; }
cyan() { echo -e "\033[38;2;0;255;255m$1\033[0m"; }

# 定义颜色变量
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
NC="\033[0m"

# 检查是否以 root 用户身份运行
if [ "$(id -u)" -ne 0 ]; then
    green "注意！输入密码过程不显示*号属于正常现象"
    echo "此脚本需要以 root 用户权限运行，请输入当前用户的密码："
    # 使用 'sudo' 重新以 root 权限运行此脚本
    sudo -E "$0" "$@"
    exit $?
fi

declare -a menu_options
declare -A commands
menu_options=(
	"更新软件源和系统软件包"
	"安装1panel面板管理工具"
    "查看1panel用户信息"
    "安装常用软件包"
    "设置局域网代理"
    "还原代理设置"
)

commands=(
    ["更新软件源和系统软件包"]="update_system_packages"
    ["安装1panel面板管理工具"]="install_1panel_on_linux"
    ["查看1panel用户信息"]="read_user_info"
    ["安装常用软件包"]="install_common_software"
    ["设置局域网代理"]="setup_lan_proxy"
    ["还原代理设置"]="restore_proxy_settings"

)

# 更新系统软件包
update_system_packages() {
	# 删除sources.list文件内容
	> /etc/apt/sources.list

	# 写入新的sources.list内容
	green "Update qinghua Source"
	echo "# 默认注释了源码镜像以提高 apt update 速度,如有需要可自行取消注释
	deb https://mirrors.tuna.tsinghua.edu.cn/debian/ bookworm main contrib non-free non-free-firmware
	# deb-src https://mirrors.tuna.tsinghua.edu.cn/debian/ bookworm main contrib non-free non-free-firmware

	deb https://mirrors.tuna.tsinghua.edu.cn/debian/ bookworm-updates main contrib non-free non-free-firmware
	# deb-src https://mirrors.tuna.tsinghua.edu.cn/debian/ bookworm-updates main contrib non-free non-free-firmware

	deb https://mirrors.tuna.tsinghua.edu.cn/debian/ bookworm-backports main contrib non-free non-free-firmware
	# deb-src https://mirrors.tuna.tsinghua.edu.cn/debian/ bookworm-backports main contrib non-free non-free-firmware

	deb https://mirrors.tuna.tsinghua.edu.cn/debian-security bookworm-security main contrib non-free non-free-firmware
	# deb-src https://mirrors.tuna.tsinghua.edu.cn/debian-security bookworm-security main contrib non-free non-free-firmware

	# deb https://security.debian.org/debian-security bookworm-security main contrib non-free non-free-firmware
	# # deb-src https://security.debian.org/debian-security bookworm-security main contrib non-free non-free-firmware" >> /etc/apt/sources.list

	# 注释raspi源
	sed -i 's/^/#/g' /etc/apt/sources.list.d/raspi.list

	# 添加raspi源
	echo "deb http://mirror.tuna.tsinghua.edu.cn/raspberrypi/ bookworm main" >> /etc/apt/sources.list.d/raspi.list

	green "Setting timezone Asia/Shanghai..."
	timedatectl set-timezone Asia/Shanghai
	
	# 更新系统软件包
	green "Updating system packages..."
	sudo apt update
	sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y

	if ! command -v curl &> /dev/null; then
		red "curl is not installed. Installing now..."
		sudo apt install -y curl
		if command -v curl &> /dev/null; then
			green "curl has been installed successfully."
		else
			echo "Failed to install curl. Please check for errors."
		fi
	else
		echo "curl is already installed."
	fi
}

# 安装1panel面板
install_1panel_on_linux() {
    curl -sSL https://resource.fit2cloud.com/1panel/package/quick_start.sh -o quick_start.sh && sudo bash quick_start.sh
    intro="https://1panel.cn/docs/installation/cli/"
    if command -v 1pctl &>/dev/null; then
        echo '{
  "registry-mirrors": [
    "https://docker.mirrors.ustc.edu.cn",
    "https://hub-mirror.c.163.com",
    "https://docker.m.daocloud.io",
    "https://ghcr.io",
    "https://mirror.baidubce.com",
    "https://docker.nju.edu.cn"
  ]
}' | sudo tee /etc/docker/daemon.json >/dev/null
        sudo /etc/init.d/docker restart
        green "如何卸载1panel 请参考：$intro"
    else
        red "未安装1panel"
    fi
}

# 查看1panel用户信息
read_user_info() {
    if command -v 1pctl &>/dev/null; then
        1pctl user-info
    else
        red "1panel未安装，请先安装1panel"
        return 1
    fi
}

# 安装常用软件包
install_common_software() {
    green "开始安装常用软件包..."
    
    # 定义要安装的软件包列表
    packages=(
        "vim"
    )
    
    # 更新包列表
    green "更新包列表..."
    if apt update; then
        green "包列表更新成功"
    else
        red "包列表更新失败"
        return 1
    fi
    
    # 安装软件包
    for package in "${packages[@]}"; do
        if command -v "$package" &>/dev/null; then
            green "$package 已安装"
        else
            blue "正在安装 $package..."
            if apt install -y "$package"; then
                green "$package 安装成功"
            else
                red "$package 安装失败"
            fi
        fi
    done
    
    green "常用软件包安装完成！"
}

# 设置局域网代理
setup_lan_proxy() {
    green "配置局域网代理设置..."
    
    # 获取代理服务器IP地址
    while true; do
        echo -n "请输入代理服务器IP地址: "
        read proxy_ip
        
        # 验证IP地址格式
        if [[ $proxy_ip =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
            # 进一步验证每个数字是否在0-255范围内
            valid=true
            IFS='.' read -ra ADDR <<< "$proxy_ip"
            for i in "${ADDR[@]}"; do
                if [ "$i" -gt 255 ] || [ "$i" -lt 0 ]; then
                    valid=false
                    break
                fi
            done
            
            if [ "$valid" = true ]; then
                break
            else
                red "IP地址格式不正确，请重新输入"
            fi
        else
            red "IP地址格式不正确，请重新输入"
        fi
    done
    
    # 获取代理端口
    while true; do
        echo -n "请输入代理端口 (默认7890): "
        read proxy_port
        
        if [ -z "$proxy_port" ]; then
            proxy_port="7890"
        fi
        
        # 验证端口范围
        if [[ $proxy_port =~ ^[0-9]+$ ]] && [ "$proxy_port" -ge 1 ] && [ "$proxy_port" -le 65535 ]; then
            break
        else
            red "端口必须是1-65535之间的数字"
        fi
    done
    
    proxy_url="http://$proxy_ip:$proxy_port"
    
    green "设置代理为: $proxy_url"
    
    # 备份原始配置文件
    backup_suffix=$(date +%Y%m%d_%H%M%S)
    
    # 设置环境变量代理
    green "配置环境变量代理..."
    
    # 创建代理配置文件
    cat << EOF > /etc/environment.d/proxy.conf
# 系统代理配置
http_proxy=$proxy_url
https_proxy=$proxy_url
ftp_proxy=$proxy_url
no_proxy=localhost,127.0.0.1,::1
HTTP_PROXY=$proxy_url
HTTPS_PROXY=$proxy_url
FTP_PROXY=$proxy_url
NO_PROXY=localhost,127.0.0.1,::1
EOF
    
    # 设置APT代理
    green "配置APT代理..."
    if [ -f "/etc/apt/apt.conf" ]; then
        cp /etc/apt/apt.conf /etc/apt/apt.conf.bak.$backup_suffix
    fi
    
    cat << EOF > /etc/apt/apt.conf.d/95proxy
Acquire::http::Proxy "$proxy_url";
Acquire::https::Proxy "$proxy_url";
Acquire::ftp::Proxy "$proxy_url";
EOF
    
    # 设置Git代理
    green "配置Git代理..."
    git config --global http.proxy "$proxy_url"
    git config --global https.proxy "$proxy_url"
    
    # 添加到用户的.bashrc
    if [ -n "$SUDO_USER" ]; then
        user_home="/home/$SUDO_USER"
        if [ -f "$user_home/.bashrc" ]; then
            cp "$user_home/.bashrc" "$user_home/.bashrc.bak.$backup_suffix"
            # 移除旧的代理设置
            sed -i '/# Proxy settings/,/# End proxy settings/d' "$user_home/.bashrc"
            # 添加新的代理设置
            cat << EOF >> "$user_home/.bashrc"

# Proxy settings
export http_proxy=$proxy_url
export https_proxy=$proxy_url
export ftp_proxy=$proxy_url
export no_proxy=localhost,127.0.0.1,::1
export HTTP_PROXY=$proxy_url
export HTTPS_PROXY=$proxy_url
export FTP_PROXY=$proxy_url
export NO_PROXY=localhost,127.0.0.1,::1
# End proxy settings
EOF
            chown "$SUDO_USER:$SUDO_USER" "$user_home/.bashrc"
        fi
    fi
    
    green "代理配置完成！"
    yellow "注意：代理设置将在下次登录时生效，或者执行 source ~/.bashrc"
    yellow "如需取消代理，请删除以下文件："
    yellow "  - /etc/environment.d/proxy.conf"
    yellow "  - /etc/apt/apt.conf.d/95proxy"
    yellow "  并执行: git config --global --unset http.proxy && git config --global --unset https.proxy"
}

# 还原代理设置
restore_proxy_settings() {
    green "开始还原代理设置..."
    
    # 确认操作
    echo -n "确定要还原所有代理设置吗？(y/N): "
    read confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        yellow "操作已取消"
        return 0
    fi
    
    restored_files=()
    failed_operations=()
    
    # 1. 删除系统环境变量代理文件
    if [ -f "/etc/environment.d/proxy.conf" ]; then
        if rm -f /etc/environment.d/proxy.conf; then
            green "✓ 删除系统代理配置文件"
            restored_files+=("系统环境变量代理")
        else
            red "✗ 删除系统代理配置文件失败"
            failed_operations+=("删除系统代理配置文件")
        fi
    else
        yellow "系统代理配置文件不存在，跳过"
    fi
    
    # 2. 删除APT代理配置
    if [ -f "/etc/apt/apt.conf.d/95proxy" ]; then
        if rm -f /etc/apt/apt.conf.d/95proxy; then
            green "✓ 删除APT代理配置"
            restored_files+=("APT代理")
        else
            red "✗ 删除APT代理配置失败"
            failed_operations+=("删除APT代理配置")
        fi
    else
        yellow "APT代理配置文件不存在，跳过"
    fi
    
    # 3. 还原APT配置文件（如果有备份）
    apt_backup=$(find /etc/apt/ -name "apt.conf.bak.*" -type f 2>/dev/null | head -1)
    if [ -n "$apt_backup" ]; then
        if cp "$apt_backup" /etc/apt/apt.conf; then
            green "✓ 还原APT配置文件: $(basename "$apt_backup")"
            restored_files+=("APT原始配置")
        else
            red "✗ 还原APT配置文件失败"
            failed_operations+=("还原APT配置文件")
        fi
    fi
    
    # 4. 取消Git代理设置
    if git config --global --get http.proxy >/dev/null 2>&1; then
        if git config --global --unset http.proxy; then
            green "✓ 取消Git HTTP代理"
            restored_files+=("Git HTTP代理")
        else
            red "✗ 取消Git HTTP代理失败"
            failed_operations+=("取消Git HTTP代理")
        fi
    fi
    
    if git config --global --get https.proxy >/dev/null 2>&1; then
        if git config --global --unset https.proxy; then
            green "✓ 取消Git HTTPS代理"
            restored_files+=("Git HTTPS代理")
        else
            red "✗ 取消Git HTTPS代理失败"
            failed_operations+=("取消Git HTTPS代理")
        fi
    fi
    
    # 5. 处理用户的.bashrc文件
    if [ -n "$SUDO_USER" ]; then
        user_home="/home/$SUDO_USER"
        bashrc_file="$user_home/.bashrc"
        
        if [ -f "$bashrc_file" ]; then
            # 检查是否存在代理设置
            if grep -q "# Proxy settings" "$bashrc_file"; then
                # 查找最新的备份文件
                bashrc_backup=$(find "$user_home" -name ".bashrc.bak.*" -type f 2>/dev/null | sort -r | head -1)
                
                if [ -n "$bashrc_backup" ]; then
                    # 使用备份文件还原
                    if cp "$bashrc_backup" "$bashrc_file" && chown "$SUDO_USER:$SUDO_USER" "$bashrc_file"; then
                        green "✓ 还原用户bashrc文件: $(basename "$bashrc_backup")"
                        restored_files+=("用户bashrc配置")
                    else
                        red "✗ 还原用户bashrc文件失败"
                        failed_operations+=("还原用户bashrc文件")
                    fi
                else
                    # 没有备份文件，手动删除代理设置
                    if sed -i '/# Proxy settings/,/# End proxy settings/d' "$bashrc_file"; then
                        green "✓ 从bashrc中删除代理设置"
                        restored_files+=("用户bashrc代理设置")
                    else
                        red "✗ 从bashrc中删除代理设置失败"
                        failed_operations+=("删除bashrc代理设置")
                    fi
                fi
            else
                yellow "用户bashrc中未发现代理设置，跳过"
            fi
        fi
    fi
    
    # 6. 显示结果总结
    echo
    green "==================== 还原结果总结 ===================="
    
    if [ ${#restored_files[@]} -gt 0 ]; then
        green "成功还原的项目:"
        for item in "${restored_files[@]}"; do
            green "  ✓ $item"
        done
    fi
    
    if [ ${#failed_operations[@]} -gt 0 ]; then
        echo
        red "失败的操作:"
        for item in "${failed_operations[@]}"; do
            red "  ✗ $item"
        done
    fi
    
    echo
    if [ ${#failed_operations[@]} -eq 0 ]; then
        green "🎉 所有代理设置已成功还原！"
        yellow "建议执行以下操作使更改完全生效:"
        yellow "  1. 重新登录或执行: source ~/.bashrc"
        yellow "  2. 重启系统（可选）"
    else
        yellow "部分设置还原失败，请手动检查相关配置文件"
    fi
    
    # 7. 清理备份文件（询问用户）
    echo
    echo -n "是否删除相关备份文件？(y/N): "
    read clean_backup
    if [[ "$clean_backup" =~ ^[Yy]$ ]]; then
        green "清理备份文件..."
        find /etc/apt/ -name "apt.conf.bak.*" -type f -delete 2>/dev/null
        if [ -n "$SUDO_USER" ]; then
            find "/home/$SUDO_USER" -name ".bashrc.bak.*" -type f -delete 2>/dev/null
        fi
        green "备份文件清理完成"
    else
        yellow "备份文件已保留，如需要可手动删除"
    fi
}


show_menu() {
    clear
    greenline "————————————————————————————————————————————————————"
    echo '
    ***********  快速部署服务器  ***************
    环境:Linux(Ubuntu/debian)
    脚本作用:快速部署服务器
            --- Made by wukong with YOU ---'
    echo -e "    https://github.com/wukongdaily/OrangePiShell"
    greenline "————————————————————————————————————————————————————"
    echo "请选择操作："	
	
	# 特殊处理的项数组（当前为空，可根据需要添加）
	special_items=()
    for i in "${!menu_options[@]}"; do
        if [[ " ${special_items[*]} " =~ " ${menu_options[i]} " ]]; then
            # 如果当前项在特殊处理项数组中，使用特殊颜色
            cyan "$((i + 1)). ${menu_options[i]}"
        else
            # 否则，使用普通格式
            echo "$((i + 1)). ${menu_options[i]}"
        fi
    done
}


handle_choice() {
    local choice=$1
    # 检查输入是否为空
    if [[ -z $choice ]]; then
        echo -e "${RED}输入不能为空，请重新选择。${NC}"
        return
    fi

    # 检查输入是否为数字
    if ! [[ $choice =~ ^[0-9]+$ ]]; then
        echo -e "${RED}请输入有效数字!${NC}"
        return
    fi

    # 检查数字是否在有效范围内
    if [[ $choice -lt 1 ]] || [[ $choice -gt ${#menu_options[@]} ]]; then
        echo -e "${RED}选项超出范围!${NC}"
        echo -e "${YELLOW}请输入 1 到 ${#menu_options[@]} 之间的数字。${NC}"
        return
    fi

    # 执行命令
    if [ -z "${commands[${menu_options[$choice - 1]}]}" ]; then
        echo -e "${RED}无效选项，请重新选择。${NC}"
        return
    fi

    "${commands[${menu_options[$choice - 1]}]}"
}

while true; do
    show_menu
    read -p "请输入选项的序号(输入q退出): " choice
    if [[ $choice == 'q' ]]; then
        break
    fi
    handle_choice $choice
    echo "按任意键继续..."
    read -n 1 # 等待用户按键
done
