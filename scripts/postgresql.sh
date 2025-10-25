#!/bin/bash

install_postgresql() {
    # 创建目录
    mkdir -p /opt/docker/compose/postgresql
    mkdir -p /opt/docker/postgresql/apps

    # 提示用户输入 PostgreSQL root 密码
    read -s -p "请输入PostgreSQL密码(postgres): " rootPassword
    echo

    if [ -z "$rootPassword" ]; then
    rootPassword=$(openssl rand -base64 16 | tr -dc 'a-zA-Z0-9' | head -c 16)
    echo "未输入密码,已生成随机密码: $rootPassword"
    fi

    # 将密码写入 .env 文件
    touch /opt/docker/compose/postgresql/postgresql.env
    echo "POSTGRES_PASSWORD=$rootPassword" > /opt/docker/compose/postgresql/postgresql.env
    echo "密码已经写入/opt/docker/compose/postgresql/postgresql.env"

    # -O 参数指定下载文件的保存路径
    wget -O /opt/docker/compose/postgresql/compose.yml https://raw.githubusercontent.com/Sm1rkBoy/DockerShell/main/compose/postgresql/compose.yml

    # 启动 Docker Compose
    docker compose -f /opt/docker/compose/postgresql/compose.yml up -d

    if [ $? -eq 0 ]; then
        echo "PostgreSQL 安装成功！"
    else
        echo "PostgreSQL 安装失败！"
    fi
}