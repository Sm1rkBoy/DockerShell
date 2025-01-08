#!/bin/bash


install_prometheus() {
    # 创建目录
    mkdir -p /opt/docker/temp
    mkdir -p /opt/docker/compose/prometheus
    mkdir -p /opt/docker/prometheus/{apps,config}

    # -O 参数指定下载文件的保存路径
    wget -O /opt/docker/temp/prometheus.yml https://raw.githubusercontent.com/Sm1rkBoy/DockerShell/main/temp/prometheus.yml
    wget -O /opt/docker/compose/prometheus/compose.yml https://raw.githubusercontent.com/Sm1rkBoy/DockerShell/main/compose/prometheus/compose.yml

    docker compose -f /opt/docker/temp/prometheus.yml up -d
    docker compose -f /opt/docker/temp/prometheus.yml down --volumes
    
    # 启动 Docker Compose
    docker compose -f /opt/docker/compose/prometheus/compose.yml up -d
    rm /opt/docker/prometheus/config/console_libraries /opt/docker/prometheus/config/consoles
    
    if [ $? -eq 0 ]; then
        echo "Prometheus 安装成功！"
    else
        echo "Prometheus 安装失败！"
    fi
}