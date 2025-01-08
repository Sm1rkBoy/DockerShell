#!/bin/bash

install_mysql() {
    # 创建目录
    mkdir -p /opt/docker/temp
    mkdir -p /opt/docker/compose/mysql
    mkdir -p /opt/docker/mysql/{apps,config,log}

    # 提示用户输入 MySQL root 密码
    read -s -p "请输入MySQL密码(root): " rootPassword
    echo

    if [ -z "$rootPassword" ]; then
    rootPassword=$(openssl rand -base64 16 | tr -dc 'a-zA-Z0-9' | head -c 16)
    echo "未输入密码,已生成随机密码: $rootPassword"
    fi

    # 将密码写入 .env 文件
    touch /opt/docker/compose/mysql/mysql.env
    echo "MYSQL_ROOT_PASSWORD=$rootPassword" > /opt/docker/compose/mysql/mysql.env
    echo "密码已经写入/opt/docker/compose/mysql/mysql.env"

    # -O 参数指定下载文件的保存路径
    wget -O /opt/docker/temp/mysql.yml https://raw.githubusercontent.com/Sm1rkBoy/DockerShell/main/temp/mysql.yml
    wget -O /opt/docker/compose/mysql/compose.yml https://raw.githubusercontent.com/Sm1rkBoy/DockerShell/main/compose/mysql/compose.yml

    # 启动临时容器
    docker compose -f /opt/docker/temp/mysql.yml up -d
    docker compose -f /opt/docker/temp/mysql.yml down --volumes

    # 启动 Docker Compose
    docker compose -f /opt/docker/compose/mysql/compose.yml up -d

    if [ $? -eq 0 ]; then
        echo "MySQL 安装成功！"
    else
        echo "MySQL 安装失败！"
    fi
}