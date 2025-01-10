#!/bin/bash

# 检查universal网络是否存在
echo "正在检查Docker网络设置"
if docker network inspect universal >/dev/null 2>&1; then
    echo "universal网络已存在"
else
    echo "创建universal网络..."
    sudo docker network create universal
fi

# 创建必要的文件夹
echo "正在创建/opt/docker文件夹"
mkdir -p /opt/docker/apps    # 存放数据文件以及运行文件
mkdir -p /opt/docker/config  # 存放配置文件
mkdir -p /opt/docker/log     # 存放日志文件
mkdir -p /opt/docker/compose # 存放compose文件和.env文件

# 定义容器列表和选择状态数组
containers=("mysql" "nginx" "watchtower" "phpmyadmin")
selected=() # 容器对应的状态(1 1 0 0)表示前两个容器已选中，后两个未选中

# 初始化 selected 数组，检查容器是否已安装
for i in "${!containers[@]}"; do # !containers[@]表示数组的索引
    if docker ps -a --format '{{.Names}}' | grep -q "^${containers[$i]}$"; then
        selected[$i]=1  # 容器已安装，标记为选中
    else
        selected[$i]=0  # 容器未安装，标记为未选中
    fi
done

# 显示菜单函数
show_menu() {
    clear
    echo "请选择要安装的容器 (使用数字切换选择，按e开始安装，按q退出):"
    for i in "${!containers[@]}"; do
        if [ "${selected[$i]}" -eq 1 ]; then
            echo "[*] $((i+1)).${containers[$i]}"
        else
            echo "[ ] $((i+1)).${containers[$i]}"
        fi
    done
}

# 处理用户输入
handle_input() {
    read -p "请输入选项: " choice
    case $choice in
        q)
            echo "退出程序"
            exit 0
            ;;
        e)
            execute_installation
            ;;
        [1-9])
            index=$((choice-1))
            if [ $index -lt ${#containers[@]} ]; then
                selected[$index]=$((1-selected[$index]))
            fi
            ;;
        *)
            echo "无效选项"
            sleep 1
            ;;
    esac
}

# 定义每个容器的安装函数
install_mysql() {
    mkdir -p /opt/docker/apps/mysql
    mkdir -p /opt/docker/config/mysql
    mkdir -p /opt/docker/compose/mysql
    mkdir -p /opt/docker/log/mysql

    echo "正在安装 MySQL..."
    # 启动 MySQL 临时容器
    docker run -d \
        --name mysql \
        -e MYSQL_ROOT_PASSWORD=123456 \
        -p 3306:3306 \
        --health-cmd "mysqladmin ping -h localhost" \
        --health-interval 5s \
        --health-timeout 10s \
        --health-retries 5 \
        mysql:8.4.0
    
    # 当容器完全启动再执行docker cp命令
    while [[ $(docker inspect -f '{{.State.Health.Status}}' mysql) != "healthy" ]]; do
        sleep 1
    done

    docker cp mysql:/var/lib/mysql /opt/docker/apps && docker cp mysql:/etc/my.cnf /opt/docker/config/mysql
    docker rm -f mysql

    # 提示用户输入 MySQL root 密码
    read -s -p "请输入MySQL密码(root): " rootPassword
    echo

    # 如果用户没有输入密码，则生成一个随机密码
    if [ -z "$rootPassword" ]; then
    rootPassword=$(openssl rand -base64 16 | tr -dc 'a-zA-Z0-9' | head -c 16)
    echo "未输入密码，已生成随机密码: $rootPassword"
    fi

    # 将密码写入 .env 文件
    touch /opt/docker/compose/mysql/.env
    echo "MYSQL_ROOT_PASSWORD=$rootPassword" > /opt/docker/compose/mysql/.env

    # 提示用户 .env 文件已创建
    echo "密码已经写入/opt/docker/compose/mysql/.env"

    # -O 参数指定下载文件的保存路径
    wget -O /opt/docker/compose/mysql/compose.yml https://raw.githubusercontent.com/Sm1rkBoy/DockerShell/main/compose/mysql/compose.yml

    # 启动 Docker Compose
    docker compose -f /opt/docker/compose/mysql/compose.yml up -d

    if [ $? -eq 0 ]; then
        echo "MySQL 安装成功！"
    else
        echo "MySQL 安装失败！"
    fi
}

install_nginx(){
    mkdir -p /opt/docker/config/nginx
    mkdir -p /opt/docker/log/nginx
    mkdir -p /opt/docker/compose/nginx
    # 启动 Nginx 容器
    echo "启动 Nginx 容器..."
    docker run -d --name nginx \
        --health-cmd="curl -f http://localhost || exit 1" \
        --health-interval=5s \
        --health-timeout=3s \
        --health-retries=3 \
        nginx:latest

    # 当容器完全启动再执行docker cp命令
    while [[ $(docker inspect -f '{{.State.Health.Status}}' nginx) != "healthy" ]]; do
        sleep 1
    done

    echo "拷贝/etc/nginx文件到到本地文件/opt/docker/config/nginx"
    docker cp nginx:/etc/nginx /opt/docker/config/

    echo "删除临时nginx容器"
    docker rm -f nginx

    echo "下载nginx的compose.yml文件"
    wget -O /opt/docker/compose/nginx/compose.yml https://raw.githubusercontent.com/Sm1rkBoy/DockerShell/compose/compose/nginx/compose.yml

    # 启动 Docker Compose
    docker compose -f /opt/docker/compose/nginx/compose.yml up -d

    if [ $? -eq 0 ]; then
        echo "Nginx 安装成功！"
    else
        echo "Nginx 安装失败！"
    fi
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

# 主循环
while true; do
    show_menu
    read -n 1 -p "请输入选择: " choice
    echo
    case $choice in
        [1-9])
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
                        echo "容器 $container_name 已经在运行，跳过安装。"
                    else
                        echo "正在安装 $container_name..."
                        # 动态调用安装函数
                        install_function="install_$container_name"
                        if declare -f "$install_function" > /dev/null; then # 判断函数是否被定义
                            $install_function
                        else
                            echo "未知容器: $container_name，跳过安装。"
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
            echo "无效选择，请重新输入。"
            ;;
    esac
done

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