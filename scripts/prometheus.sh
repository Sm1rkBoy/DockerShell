#!/bin/bash


install_prometheus() {
    # 创建目录
    mkdir -p /opt/docker/prometheus/{apps,config,compose,log}

    # 安装临时的prometheus容器
    echo "启动 Prometheus 容器..."
    docker run -d --name prometheus -p 9090:9090 prom/prometheus:latest

    # 等待 Prometheus健康
    echo "等待 Prometheus完全启动..."
    while true; do
        if curl -s -o /dev/null -w "%{http_code}" http://localhost:9090/-/healthy | grep -q "200"; then
            echo "Prometheus完全启动,进行下一步"
            break
        else
            echo "等待Prometheus完全启动中..."
            sleep 5
        fi
    done

    # 拷贝容器内的文件到本地
    docker cp prometheus:/etc/prometheus/. /opt/docker/prometheus/config
    docker cp prometheus:/prometheus/. /opt/docker/prometheus/apps

    # 删除临时容器
    docker rm -f prometheus
    docker volume prune -a -f

    # -O 参数指定下载文件的保存路径
    wget -O /opt/docker/prometheus/compose/compose.yml https://raw.githubusercontent.com/Sm1rkBoy/DockerShell/main/compose/prometheus/compose.yml
    
    # 启动 Docker Compose
    docker compose -f /opt/docker/prometheus/compose/compose.yml up -d

    if [ $? -eq 0 ]; then
        echo "Prometheus 安装成功！"
    else
        echo "Prometheus 安装失败！"
    fi
}