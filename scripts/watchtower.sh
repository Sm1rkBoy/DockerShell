#!/bin/bash

install_watchtower(){
    mkdir -p /opt/docker/watchtower/compose

    echo "下载watchtower的compose.yml文件"
    wget -O /opt/docker/watchtower/compose/compose.yml https://raw.githubusercontent.com/Sm1rkBoy/DockerShell/main/compose/watchtower/compose.yml

    # 启动 Docker Compose
    docker compose -f /opt/docker/watchtower/compose/compose.yml up -d

    if [ $? -eq 0 ]; then
        echo "watchtower 安装成功！"
    else
        echo "watchtower 安装失败！"
    fi
}