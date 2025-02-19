#!/bin/bash

install_redis() {
    mkdir -p /opt/docker/redis/{apps,config,compose,log}
    echo "下载 redis 的compose.yml文件"
    wget -O /opt/docker/redis/compose/compose.yml https://raw.githubusercontent.com/Sm1rkBoy/DockerShell/main/compose/redis/compose.yml
    # 启动 Docker Compose
    docker compose -f /opt/docker/redis/compose/compose.yml up -d
    if [ $? -eq 0 ]; then
        echo "redis 安装成功！"
    else
        echo "redis 安装失败！"
    fi
}