#!/bin/bash

install_nginx(){
    # 创建目录
    mkdir -p /opt/docker/temp
    mkdir -p /opt/docker/compose/nginx
    mkdir -p /opt/docker/nginx/{config,log}

    echo "下载nginx的compose.yml文件"
    wget -O /opt/docker/temp/nginx.yml https://raw.githubusercontent.com/Sm1rkBoy/DockerShell/main/temp/nginx.yml
    wget -O /opt/docker/compose/nginx/compose.yml https://raw.githubusercontent.com/Sm1rkBoy/DockerShell/main/compose/nginx/compose.yml

    docker compose -f /opt/docker/temp/nginx.yml up -d
    docker compose -f /opt/docker/temp/nginx.yml down --volumes

    # 启动 Docker Compose
    docker compose -f /opt/docker/compose/nginx/compose.yml up -d

    if [ $? -eq 0 ]; then
        echo "Nginx 安装成功！"
    else
        echo "Nginx 安装失败！"
    fi
}
