#!/bin/bash

# 检查docker是否安装
check_docker() {
    if ! command -v docker &> /dev/null; then
        echo "Docker 未安装，请先安装 Docker。"
        exit 1
    else
        echo "Docker 已安装，继续执行脚本。"
    fi
}

# 检查Docker网络设置
check_dockerNetwork() {
    local network_name="universal"

    echo "正在检查Docker网络设置..."
    if docker network inspect "$network_name" >/dev/null 2>&1; then
        echo "$network_name 网络已存在。"
    else
        echo "创建 $network_name 网络..."
        sudo docker network create "$network_name"
        if [ $? -eq 0 ]; then
            echo "$network_name 网络创建成功。"
        else
            echo "$network_name 网络创建失败，请检查 Docker 是否正常运行。"
            exit 1
        fi
    fi
}

check_docker
check_dockerNetwork

# 定义容器列表和选择状态数组
containers=("mysql" "redis" "nginx" "watchtower" "phpmyadmin" "vaultwarden" "nezha" "grafana" "prometheus" "victoriametrics")
selected=() # 容器对应的状态(1 1 0 0)表示前两个容器已选中,后两个未选中

# 检查容器是否安装
check_installed() {
    # 初始化 selected 数组,检查容器是否已安装
    for i in "${!containers[@]}"; do # !containers[@]表示数组的索引,即容器的编号,从0开始,到数组的长度-1
        if docker ps -a --format '{{.Names}}' | grep -q "^${containers[$i]}$"; then # 检查容器是否已安装
            selected[$i]=1  # 容器已安装,标记为选中
        else
            selected[$i]=0  # 容器未安装,标记为未选中
        fi
    done
}

check_installed

# 显示菜单函数
show_menu() {
    clear
    echo "请选择要安装的容器 (输入容器对应的数字勾选,按e开始安装,按q退出):"
    for i in "${!containers[@]}"; do
        if [ "${selected[$i]}" -eq 1 ]; then # 判断容器是否安装,如果已经安装则选中
            echo "[*] $((i+1)).${containers[$i]}"
        else
            echo "[ ] $((i+1)).${containers[$i]}"
        fi
    done
}

# 检查容器是否正在运行
is_container_running() {
    local container_name=$1 # 传入的第一个参数作为容器名
    local status=$(docker inspect --format='{{.State.Status}}' "$container_name" 2>/dev/null)
    if [ "$status" == "running" ]; then
        return 0  # 容器正在运行
    else
        return 1  # 容器未运行
    fi
}

# 处理用户输入
handle_input() {
    # 提示用户输入
    echo -n "请选择需要的容器: "

    # 读取第一个字符
    read -N 1 choice

    # 尝试读取第二个字符（超时时间为 0.2 秒）
    if read -N 1 -t 0.2 second_char; then
        choice="$choice$second_char"
    fi

    # 删除可能的换行符
    choice=$(echo "$choice" | tr -d '\n')

    echo
    case $choice in
        [1-9]|[1-9][0-9])
            index=$((choice-1)) # $((...))表示算术运算
            if [ "$index" -lt "${#containers[@]}" ]; then # 索引小于容器数量 #containers[@]表示数组的个数
                selected[$index]=$((1 - selected[$index]))  # 切换选择状态
            fi
            ;;
        e)
            echo "开始安装选中的容器..."
            for i in "${!containers[@]}"; do
                if [ "${selected[$i]}" -eq 1 ]; then
                    container_name="${containers[$i]}"
                    if is_container_running "$container_name"; then
                        echo "容器 $container_name 已经在运行,跳过安装。"
                    else
                        echo "正在安装的容器是 $container_name..."
                        # 动态调用安装函数
                        install_function="install_$container_name"
                        if declare -f "$install_function" > /dev/null; then # 判断函数是否被定义
                            $install_function
                        else
                            echo "未知容器: $container_name,跳过安装。"
                        fi
                    fi
                fi
            done
            break
            ;;
        q)
            echo "退出脚本。"
            exit 0
            ;;
        *)
            echo "无效选择,请重新输入。"
            ;;
    esac
}

# 主循环
while true; do
    show_menu
    handle_input
done