#!/bin/bash

# 定义函数 check_docker
check_docker() {
    if ! command -v docker &> /dev/null; then
        echo "Docker 未安装，请先安装 Docker。"
        exit 1
    else
        echo "Docker 已安装，继续执行脚本。"
    fi
}

# 定义函数 check_and_create_network
check_dockerNetwork() {
    local network_name="universal"  # 定义网络名称

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

# 创建必要的文件夹
echo "正在创建/opt/docker文件夹"
mkdir -p /opt/docker/{apps,config,log,compose}

# 定义容器列表和选择状态数组
containers=("mysql" "redis" "nginx" "watchtower" "phpmyadmin" "vaultwarden" "dockge" "nezha" "grafana" "prometheus")
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

    # 尝试读取第二个字符（超时时间为 0.15 秒）
    if read -N 1 -t 0.15 second_char; then
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

install_mysql() {
    # 创建目录
    mkdir -p /opt/docker/{apps,config,compose,log}/mysql

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

    # 如果用户没有输入密码,则生成一个随机密码
    if [ -z "$rootPassword" ]; then
    rootPassword=$(openssl rand -base64 16 | tr -dc 'a-zA-Z0-9' | head -c 16)
    echo "未输入密码,已生成随机密码: $rootPassword"
    fi

    # 将密码写入 .env 文件
    touch /opt/docker/compose/mysql/mysql.env
    echo "MYSQL_ROOT_PASSWORD=$rootPassword" > /opt/docker/compose/mysql/mysql.env

    # 提示用户 .env 文件已创建
    echo "密码已经写入/opt/docker/compose/mysql/mysql.env"

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

install_redis() {
    mkdir -p /opt/docker/{apps,config,compose,log}/redis
    echo "下载 redis 的compose.yml文件"
    wget -O /opt/docker/compose/redis/compose.yml https://raw.githubusercontent.com/Sm1rkBoy/DockerShell/main/compose/redis/compose.yml
    # 启动 Docker Compose
    docker compose -f /opt/docker/compose/redis/compose.yml up -d
    if [ $? -eq 0 ]; then
        echo "redis 安装成功！"
    else
        echo "redis 安装失败！"
    fi
}

install_nginx(){
    # 创建目录
    mkdir -p /opt/docker/{apps,config,compose,log}/nginx

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
    wget -O /opt/docker/compose/nginx/compose.yml https://raw.githubusercontent.com/Sm1rkBoy/DockerShell/main/compose/nginx/compose.yml

    # 启动 Docker Compose
    docker compose -f /opt/docker/compose/nginx/compose.yml up -d

    if [ $? -eq 0 ]; then
        echo "Nginx 安装成功！"
    else
        echo "Nginx 安装失败！"
    fi
}

install_watchtower(){
    mkdir -p /opt/docker/compose/watchtower

    echo "下载watchtower的compose.yml文件"
    echo "该容器不需要在/opt/docker/apps文件夹下创建文件夹"
    wget -O /opt/docker/compose/watchtower/compose.yml https://raw.githubusercontent.com/Sm1rkBoy/DockerShell/main/compose/watchtower/compose.yml

    # 启动 Docker Compose
    docker compose -f /opt/docker/compose/watchtower/compose.yml up -d

    if [ $? -eq 0 ]; then
        echo "watchtower 安装成功！"
    else
        echo "watchtower 安装失败！"
    fi
}

install_phpmyadmin(){
    # 创建目录
    mkdir -p /opt/docker/{apps,config,compose,log}/phpmyadmin

    echo "下载 phpmyadmin 的compose.yml文件"
    echo "该容器不需要在/opt/docker/apps文件夹下创建文件夹"
    wget -O /opt/docker/compose/phpmyadmin/compose.yml https://raw.githubusercontent.com/Sm1rkBoy/DockerShell/main/compose/phpmyadmin/compose.yml

    # 启动 Docker Compose
    docker compose -f /opt/docker/compose/phpmyadmin/compose.yml up -d

    if [ $? -eq 0 ]; then
        echo "phpmyadmin 安装成功！"
    else
        echo "phpmyadmin 安装失败！"
    fi
}

install_vaultwarden() {
    # 创建目录
    mkdir -p /opt/docker/{apps,config,compose,log}/vaultwarden

    # 初始化配置文件
    CONFIG_FILE="/opt/docker/compose/vaultwarden/vaultwarden.env" > "$CONFIG_FILE"  # 清空文件内容

    echo "# log文件设置" >> "$CONFIG_FILE"
    echo "LOG_FILE=/log/vaultwarden.log" >> "$CONFIG_FILE"
    echo "LOG_LEVEL=warn" >> "$CONFIG_FILE"
    echo "EXTENDED_LOGGING=true" >> "$CONFIG_FILE"
    echo >> "$CONFIG_FILE"  # 空行

    echo "# 取消密码提示" >> "$CONFIG_FILE"
    echo "SHOW_PASSWORD_HINT=false" >> "$CONFIG_FILE"
    echo >> "$CONFIG_FILE"  # 空行

    echo "初次创建最好开启注册再关闭注册!!!!"
    read -p "是否开启注册(关闭注册默认打开邀请)?(Y/n): " SIGNUPS_ALLOWED
    SIGNUPS_ALLOWED=${SIGNUPS_ALLOWED:-y}
    if [[ "$SIGNUPS_ALLOWED" =~ ^[Yy]$ ]]; then
        echo "# 注册&邀请设置" >> "$CONFIG_FILE"
        echo "SIGNUPS_ALLOWED=true" >> "$CONFIG_FILE"
        echo "INVITATIONS_ALLOWED=false" >> "$CONFIG_FILE"
        echo >> "$CONFIG_FILE"  # 空行
    fi

    echo "# Admin面板设置" >> "$CONFIG_FILE"
    TOKEN=$(openssl rand -base64 48) # 生成一个随机的48位字符串
    echo "DISABLE_ADMIN_TOKEN=false" >> "$CONFIG_FILE"
    echo "ADMIN_TOKEN=${TOKEN}" >> "$CONFIG_FILE" 
    echo >> "$CONFIG_FILE"  # 空行
    
    echo "# 域名设置" >> "$CONFIG_FILE"
    read -p "请输入域名: " DOMAIN
    echo "DOMAIN=$DOMAIN" >> "$CONFIG_FILE"
    echo >> "$CONFIG_FILE"  # 空行

    echo "# 时区设置" >> "$CONFIG_FILE"
    read -p "请输入时区(默认:Asia/Shanghai): " TZ
    TZ=${TZ:-Asia/Shanghai} # 如果用户未输入时区,则默认为 Asia/Shanghai
    echo "TZ=$TZ" >> "$CONFIG_FILE" 
    echo >> "$CONFIG_FILE"  # 空行

    # 询问是否开启WebSocket
    read -p "是否开启WebSocket?(Y/n): " WEBSOCKET_ENABLED
    WEBSOCKET_ENABLED=${WEBSOCKET_ENABLED:-y}
    if [[ "$WEBSOCKET_ENABLED" =~ ^[Yy]$ ]]; then
        echo "# WebSocket设置" >> "$CONFIG_FILE"
        echo "WEBSOCKET_ENABLED=true" >> "$CONFIG_FILE"
        echo >> "$CONFIG_FILE"  # 空行
    fi

    # 询问是否使用 MySQL数据库
    read -p "是否使用 MySQL?(y/N): " USE_MYSQL
    USE_MYSQL=${USE_MYSQL:-n}
    if [[ "$USE_MYSQL" =~ ^[Yy]$ ]]; then
        # 如果用户选择使用 MySQL，则设置 MySQL 相关配置
        read -p "请输入 MySQL 用户名: " MYSQL_USER
        read -p "请输入 MySQL 密码: " MYSQL_PASSWORD
        read -p "请输入 MySQL 主机: " MYSQL_HOST
        read -p "请输入 MySQL 端口: " MYSQL_PORT
        read -p "请输入 MySQL 数据库名: " MYSQL_DATABASE
        echo "# 数据库设置" >> "$CONFIG_FILE"
        echo "DATABASE_URL=mysql://${MYSQL_USER}:${MYSQL_PASSWORD}@${MYSQL_HOST}:${MYSQL_PORT}/${MYSQL_DATABASE}" >> "$CONFIG_FILE"
        echo >> "$CONFIG_FILE"  # 空行
    fi

    # 询问是否开启SMTP
    read -p "是否开启SMTP?(y/N): " USE_SMTP
    USE_SMTP=${USE_SMTP:-n}
    if [[ "$USE_SMTP" =~ ^[Yy]$ ]]; then
        read -p "请输入SMTP主机: " SMTP_HOST
        read -p "请输入SMTP端口: " SMTP_PORT
        read -p "请输入SMTP安全性: " SMTP_SECURITY
        read -p "请输入SMTP用户名: " SMTP_USERNAME
        read -p "请输入SMTP密码: " SMTP_PASSWORD
        read -p "请输入SMTP发件人: " SMTP_FROM
        read -p "请输入SMTP认证机制: " SMTP_AUTH_MECHANISM
        echo "# SMTP设置" >> "$CONFIG_FILE"
        echo "SMTP_HOST=$SMTP_HOST" >> "$CONFIG_FILE"
        echo "SMTP_PORT=$SMTP_PORT" >> "$CONFIG_FILE"
        echo "SMTP_SECURITY=$SMTP_SECURITY" >> "$CONFIG_FILE"
        echo "SMTP_USERNAME=$SMTP_USERNAME" >> "$CONFIG_FILE"
        echo "SMTP_PASSWORD=$SMTP_PASSWORD" >> "$CONFIG_FILE"
        echo "SMTP_FROM=$SMTP_FROM" >> "$CONFIG_FILE"
        echo "SMTP_AUTH_MECHANISM=$SMTP_AUTH_MECHANISM" >> "$CONFIG_FILE"
        echo >> "$CONFIG_FILE"  # 空行
    fi

    # 询问是否开启PUSH
    read -p "是否开启推送?(y/N): " USE_PUSH
    USE_PUSH=${USE_PUSH:-n}
    if [[ "$USE_PUSH" =~ ^[Yy]$ ]]; then
        read -p "请输入推送ID: " PUSH_ID
        read -p "请输入推送KEY: " PUSH_KEY
        echo "# 推送设置" >> "$CONFIG_FILE"
        echo "PUSH_ENABLED=true" >> "$CONFIG_FILE"
        echo "PUSH_INSTALLATION_ID=$PUSH_ID" >> "$CONFIG_FILE"
        echo "PUSH_INSTALLATION_KEY=$PUSH_KEY" >> "$CONFIG_FILE"
        echo >> "$CONFIG_FILE"  # 空行
    fi

    # -O 参数指定下载文件的保存路径
    wget -O /opt/docker/compose/vaultwarden/compose.yml https://raw.githubusercontent.com/Sm1rkBoy/DockerShell/main/compose/vaultwarden/compose.yml

    # 启动 Docker Compose
    docker compose -f /opt/docker/compose/vaultwarden/compose.yml up -d

    if [ $? -eq 0 ]; then
        echo "vaultwarden 安装成功！"
    else
        echo "vaultwarden 安装失败！"
    fi
    echo "Admin面板的token存储在/opt/docker/compose/vaultwarden/vaultwarden.env文件中"
    echo "Admin面板的token存储在/opt/docker/compose/vaultwarden/vaultwarden.env文件中"
    echo "Admin面板的token存储在/opt/docker/compose/vaultwarden/vaultwarden.env文件中"
}

install_dockge() {
    # 创建目录
    mkdir -p /opt/docker/{apps,config,compose,log}/dockge

    echo "下载 dockge 的compose.yml文件"
    wget -O /opt/docker/compose/dockge/compose.yml https://raw.githubusercontent.com/Sm1rkBoy/DockerShell/main/compose/dockge/compose.yml
    # 启动 Docker Compose
    docker compose -f /opt/docker/compose/dockge/compose.yml up -d
    if [ $? -eq 0 ]; then
        echo "dockge 安装成功！"
    else
        echo "dockge 安装失败！"
    fi
}

install_nezha() {
    # 创建目录
    mkdir -p /opt/docker/{apps,config,compose,log}/nezha

    echo "下载 nezha 的compose.yml文件"
    wget -O /opt/docker/compose/nezha/compose.yml https://raw.githubusercontent.com/Sm1rkBoy/DockerShell/main/compose/nezha/compose.yml

    # 启动 Docker Compose
    docker compose -f /opt/docker/compose/nezha/compose.yml up -d

    # 定义要修改的文件路径
    CONFIG_FILE="/opt/docker/apps/nezha/config.yaml"
    read -p "请输入网站徽标: " SITENAME
    sed -i "s/sitename: .*/sitename: $SITENAME/" "$CONFIG_FILE"
    read -p "请输入Agent对接地址(IP:PORT): " INSTALLHOST
    sed -i "s/installhost: .*/installhost: $INSTALLHOST/" "$CONFIG_FILE"
    sed -i 's/language: .*/language: zh_CN/' "$CONFIG_FILE"

    # 重新启动 Docker Compose 重建nezha
    docker compose -f /opt/docker/compose/nezha/compose.yml up -d

    if [ $? -eq 0 ]; then
        echo "nezha 安装成功！"
    else
        echo "nezha 安装失败！"
    fi
}

install_grafana() {
    # 创建目录
    mkdir -p /opt/docker/{apps,config,compose,log}/grafana

    echo "正在安装 Grafana..."
    # 启动 Grafana 临时容器
    docker run -d \
        --name grafana \
        -p 3000:3000 \
        --health-cmd "curl -f http://localhost:3000/api/health || exit 1" \
        --health-interval 30s \
        --health-timeout 10s \
        --health-retries 3 \
        grafana/grafana:latest

    # 当容器完全启动再执行docker cp命令
    while [[ $(docker inspect -f '{{.State.Health.Status}}' grafana) != "healthy" ]]; do
        sleep 1
    done

    docker cp grafana:/etc/grafana /opt/docker/config
    docker cp grafana:/var/lib/grafana /opt/docker/apps
    docker cp grafana:/var/log/grafana /opt/docker/log
    docker rm -f grafana

    # 定义文件路径
    touch /opt/docker/compose/grafana/grafana.env
    output_file="/opt/docker/compose/grafana/grafana.env" > "$output_file"  # 清空文件内容
    echo "GF_PATHS_CONFIG=/etc/grafana/grafana.ini" >> "$output_file"
    echo "GF_PATHS_DATA=/var/lib/grafana" >> "$output_file"
    echo "GF_PATHS_HOME=/usr/share/grafana" >> "$output_file"
    echo "GF_PATHS_LOGS=/var/log/grafana" >> "$output_file"
    echo "GF_PATHS_PLUGINS=/var/lib/grafana/plugins" >> "$output_file"
    echo "GF_PATHS_PROVISIONING=/etc/grafana/provisioning" >> "$output_file"
    read -p "请输入管理员用户名(默认:root): " GF_SECURITY_ADMIN_USER
    GF_SECURITY_ADMIN_USER=${GF_SECURITY_ADMIN_USER:-root}
    read -p "请输入管理员密码(默认:12345678): " GF_SECURITY_ADMIN_PASSWORD
    GF_SECURITY_ADMIN_PASSWORD=${GF_SECURITY_ADMIN_PASSWORD:-12345678}
    read -p "是否允许用户注册(默认:false): " GF_USERS_ALLOW_SIGN_UP
    GF_USERS_ALLOW_SIGN_UP=${GF_USERS_ALLOW_SIGN_UP:-false}

    echo "GF_SECURITY_ADMIN_USER= $GF_SECURITY_ADMIN_USER" >> "$output_file"
    echo "GF_SECURITY_ADMIN_PASSWORD= $GF_SECURITY_ADMIN_PASSWORD" >> "$output_file"
    echo "GF_USERS_ALLOW_SIGN_UP= $GF_USERS_ALLOW_SIGN_UP" >> "$output_file"

    # -O 参数指定下载文件的保存路径
    wget -O /opt/docker/compose/grafana/compose.yml https://raw.githubusercontent.com/Sm1rkBoy/DockerShell/main/compose/grafana/compose.yml

    # 启动 Docker Compose
    docker compose -f /opt/docker/compose/grafana/compose.yml up -d

    if [ $? -eq 0 ]; then
        echo "Grafana 安装成功！"
    else
        echo "Grafana 安装失败！"
    fi
}

install_prometheus() {
    # 创建目录
    mkdir -p /opt/docker/{apps,config,compose,log}/prometheus

    # 安装临时的prometheus容器
    echo "启动 Prometheus 容器..."
    docker run -d --name prometheus -p 9090:9090 prom/prometheus:latest

    # 等待 Prometheus健康
    echo "等待 Prometheus完全启动..."
    while true; do
        if curl -s -o /dev/null -w "%{http_code}" http://localhost:9090/-/healthy | grep -q "200"; then
            echo "Prometheus完全启动,进行下一步"
            break
        else
            echo "等待Prometheus完全启动中..."
            sleep 5
        fi
    done

    # 拷贝容器内的文件到本地
    docker cp prometheus:/etc/prometheus /opt/docker/config
    docker cp prometheus:/prometheus /opt/docker/apps

    # 删除临时容器
    docker rm -f prometheus
    docker volume prune -a -f

    # -O 参数指定下载文件的保存路径
    wget -O /opt/docker/compose/prometheus/compose.yml https://raw.githubusercontent.com/Sm1rkBoy/DockerShell/main/compose/prometheus/compose.yml
    
    # 启动 Docker Compose
    docker compose -f /opt/docker/compose/prometheus/compose.yml up -d

    if [ $? -eq 0 ]; then
        echo "Prometheus 安装成功！"
    else
        echo "Prometheus 安装失败！"
    fi
}

# 主循环
while true; do
    show_menu
    handle_input
done