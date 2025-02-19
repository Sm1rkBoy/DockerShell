#!/bin/bash

install_nginx(){
    # 创建目录
    mkdir -p /opt/docker/nginx/{apps,config,compose,log}

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

    echo "拷贝/etc/nginx文件到到本地文件/opt/docker/nginx/config"
    docker cp nginx:/etc/nginx/. /opt/docker/nginx/config

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
