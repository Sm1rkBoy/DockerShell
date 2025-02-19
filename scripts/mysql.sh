#!/bin/bash

install_mysql() {
    # 创建目录
    mkdir -p /opt/docker/mysql/{apps,config,compose,log}

    # 提示用户输入 MySQL root 密码
    read -s -p "请输入MySQL密码(root): " rootPassword
    echo

    # 如果用户没有输入密码,则生成一个随机密码
    if [ -z "$rootPassword" ]; then
    rootPassword=$(openssl rand -base64 16 | tr -dc 'a-zA-Z0-9' | head -c 16)
    echo "未输入密码,已生成随机密码: $rootPassword"
    fi

    # 将密码写入 .env 文件
    touch /opt/docker/mysql/compose/mysql.env
    echo "MYSQL_ROOT_PASSWORD=$rootPassword" > /opt/docker/mysql/compose/mysql.env

    # 提示用户 .env 文件已创建
    echo "密码已经写入/opt/docker/mysql/compose/mysql.env"

    echo "正在启动临时 MySQL 容器..."
    # 启动 MySQL 临时容器
    docker run -d \
        --name mysql \
        -e MYSQL_ROOT_PASSWORD=$rootPassword \
        -p 3306:3306 \
        --health-cmd "mysqladmin ping -h localhost" \
        --health-interval 5s \
        --health-timeout 10s \
        --health-retries 5 \
        mysql:8.4.3
    
    # 当容器完全启动再执行docker cp命令
    while [[ $(docker inspect -f '{{.State.Health.Status}}' mysql) != "healthy" ]]; do
        sleep 1
    done

    docker cp mysql:/etc/my.cnf /opt/docker/mysql/config/.
    docker rm -f mysql

    # -O 参数指定下载文件的保存路径
    wget -O /opt/docker/mysql/compose/compose.yml https://raw.githubusercontent.com/Sm1rkBoy/DockerShell/main/compose/mysql/compose.yml

    # 启动 Docker Compose
    docker compose -f /opt/docker/mysql/compose/compose.yml up -d

    if [ $? -eq 0 ]; then
        echo "MySQL 安装成功！"
    else
        echo "MySQL 安装失败！"
    fi
}