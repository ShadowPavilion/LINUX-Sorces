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
)

commands=(
    ["更新软件源和系统软件包"]="update_system_packages"
    ["安装1panel面板管理工具"]="install_1panel_on_linux"
    ["查看1panel用户信息"]="read_user_info"

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
	sudo timedatectl set-timezone Asia/Shanghai
	
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
    sudo 1pctl user-info
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
	
	# 特殊处理的项数组
	special_items=("安装小雅tvbox" "安装特斯拉伴侣TeslaMate")
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
