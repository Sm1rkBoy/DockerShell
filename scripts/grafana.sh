#!/bin/bash

install_grafana() {
    # 创建目录
    mkdir -p /opt/docker/grafana/{apps,config,compose,log}

    # 定义文件路径
    touch /opt/docker/grafana/compose/grafana.env
    output_file="/opt/docker/grafana/compose/grafana.env" > "$output_file"  # 清空文件内容
    echo "GF_PATHS_CONFIG=/etc/grafana/grafana.ini" >> "$output_file"
    echo "GF_PATHS_DATA=/var/lib/grafana" >> "$output_file"
    echo "GF_PATHS_HOME=/usr/share/grafana" >> "$output_file"
    echo "GF_PATHS_LOGS=/var/log/grafana" >> "$output_file"
    echo "GF_PATHS_PLUGINS=/var/lib/grafana/plugins" >> "$output_file"
    echo "GF_PATHS_PROVISIONING=/etc/grafana/provisioning" >> "$output_file"
    read -p "请输入管理员用户名(默认:grafana): " GF_SECURITY_ADMIN_USER
    GF_SECURITY_ADMIN_USER=${GF_SECURITY_ADMIN_USER:-grafana}
    read -p "请输入管理员密码(默认:12345678): " GF_SECURITY_ADMIN_PASSWORD
    GF_SECURITY_ADMIN_PASSWORD=${GF_SECURITY_ADMIN_PASSWORD:-12345678}
    read -p "是否允许用户注册(默认:false): " GF_USERS_ALLOW_SIGN_UP
    GF_USERS_ALLOW_SIGN_UP=${GF_USERS_ALLOW_SIGN_UP:-false}
    echo "GF_SECURITY_ADMIN_USER=$GF_SECURITY_ADMIN_USER" >> "$output_file"
    echo "GF_SECURITY_ADMIN_PASSWORD=$GF_SECURITY_ADMIN_PASSWORD" >> "$output_file"
    echo "GF_USERS_ALLOW_SIGN_UP=$GF_USERS_ALLOW_SIGN_UP" >> "$output_file"

    echo "正在启动临时 Grafana 容器..."
    # 启动 Grafana 临时容器
    docker run -d \
        --name grafana \
        -p 3000:3000 \
        --health-cmd "curl -f http://localhost:3000/api/health || exit 1" \
        --health-interval 10s \
        --health-timeout 10s \
        --health-retries 10 \
        -e GF_PATHS_CONFIG=/etc/grafana/grafana.ini \
        -e GF_PATHS_DATA=/var/lib/grafana \
        -e GF_PATHS_HOME=/usr/share/grafana \
        -e GF_PATHS_LOGS=/var/log/grafana \
        -e GF_PATHS_PLUGINS=/var/lib/grafana/plugins \
        -e GF_PATHS_PROVISIONING=/etc/grafana/provisioning \
        -e GF_SECURITY_ADMIN_USER=${GF_SECURITY_ADMIN_USER:-grafana} \
        -e GF_SECURITY_ADMIN_PASSWORD=${GF_SECURITY_ADMIN_PASSWORD:-12345678} \
        -e GF_USERS_ALLOW_SIGN_UP=${GF_USERS_ALLOW_SIGN_UP:-false} \
        grafana/grafana:latest

    # 当容器完全启动再执行docker cp命令
    while [[ $(docker inspect -f '{{.State.Health.Status}}' grafana) != "healthy" ]]; do
        sleep 1
    done

    docker cp grafana:/etc/grafana/. /opt/docker/grafana/config
    docker cp grafana:/var/lib/grafana/. /opt/docker/grafana/apps
    docker cp grafana:/var/log/grafana/. /opt/docker/grafana/log
    docker rm -f grafana

    # -O 参数指定下载文件的保存路径
    wget -O /opt/docker/grafana/compose/compose.yml https://raw.githubusercontent.com/Sm1rkBoy/DockerShell/main/compose/grafana/compose.yml

    # 启动 Docker Compose
    docker compose -f /opt/docker/grafana/compose/compose.yml up -d

    if [ $? -eq 0 ]; then
        echo "Grafana 安装成功！"
    else
        echo "Grafana 安装失败！"
    fi
}