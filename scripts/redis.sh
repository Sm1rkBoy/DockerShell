#!/bin/bash

install_redis() {
    mkdir -p /opt/docker/redis/apps

    echo "下载 redis 的compose.yml文件"
    wget -O /opt/docker/temp/redis.yml https://raw.githubusercontent.com/Sm1rkBoy/DockerShell/main/temp/redis.yml
    wget -O /opt/docker/compose/redis/compose.yml https://raw.githubusercontent.com/Sm1rkBoy/DockerShell/main/compose/redis/compose.yml

    docker compose -f /opt/docker/temp/redis.yml up -d
    docker compose -f /opt/docker/temp/redis.yml down --volumes

    # 启动 Docker Compose
    docker compose -f /opt/docker/compose/redis/compose.yml up -d

    if [ $? -eq 0 ]; then
        echo "redis 安装成功！"
    else
        echo "redis 安装失败！"
    fi
}