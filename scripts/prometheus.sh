#!/bin/bash


install_prometheus() {
    # 创建目录
    mkdir -p /opt/docker/temp
    mkdir -p /opt/docker/compose/prometheus
    mkdir -p /opt/docker/prometheus/{apps,config}

    # -O 参数指定下载文件的保存路径
    wget -O /opt/docker/temp/promtheus.yml https://raw.githubusercontent.com/Sm1rkBoy/DockerShell/main/temp/promtheus.yml
    wget -O /opt/docker/compose/promtheus/compose.yml https://raw.githubusercontent.com/Sm1rkBoy/DockerShell/main/compose/promtheus/compose.yml

    docker compose -f /opt/docker/temp/promtheus.yml up -d
    docker compose -f /opt/docker/temp/promtheus.yml down --volumes
    
    # 启动 Docker Compose
    docker compose -f /opt/docker/compose/promtheus/compose.yml up -d

    if [ $? -eq 0 ]; then
        echo "Prometheus 安装成功！"
    else
        echo "Prometheus 安装失败！"
    fi
}