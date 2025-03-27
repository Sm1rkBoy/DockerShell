#!/bin/bash

install_victoriametrics() {
    # 创建目录
    mkdir -p /opt/docker/temp
    mkdir -p /opt/docker/compose/victoriametrics
    mkdir -p /opt/docker/victoriametrics/apps

    # 读取用户名和密码
    read -p "请输入 VictoriaMetrics 的用户名: " VM_USERNAME
    read -sp "请输入 VictoriaMetrics 的密码: " VM_PASSWORD
    echo "" # 换行

    # 检查输入是否为空
    if [[ -z "$VM_USERNAME" || -z "$VM_PASSWORD" ]]; then
        echo "错误：用户名和密码不能为空！"
        exit 1
    fi

    wget -O /opt/docker/temp/victoriametrics.yml https://raw.githubusercontent.com/Sm1rkBoy/DockerShell/main/temp/victoriametrics.yml
    wget -O /opt/docker/compose/victoriametrics/compose.yml https://raw.githubusercontent.com/Sm1rkBoy/DockerShell/main/compose/victoriametrics/compose.yml

    # 使用 sed 替换占位符
    sed -i -e "s/__USERNAME__/${VM_USERNAME}/g" -e "s/__PASSWORD__/${VM_PASSWORD}/g" "/opt/docker/compose/victoriametrics/compose.yml"
    
    # 启动 Docker Compose
    docker compose -f /opt/docker/temp/victoriametrics.yml up -d
    docker compose -f /opt/docker/temp/victoriametrics.yml down --volumes
    docker compose -f /opt/docker/compose/victoriametrics/compose.yml up -d

    if [ $? -eq 0 ]; then
        echo "Victoriametrics 安装成功！"
    else
        echo "Victoriametrics 安装失败！"
    fi
}