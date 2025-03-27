#!/bin/bash

install_grafana() {
    # 创建目录
    mkdir -p /opt/docker/temp
    mkdir -p /opt/docker/compose/grafana
    mkdir -p /opt/docker/grafana/{apps,config,log}

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

    # -O 参数指定下载文件的保存路径
    wget -O /opt/docker/temp/grafana.yml https://raw.githubusercontent.com/Sm1rkBoy/DockerShell/main/temp/grafana.yml
    wget -O /opt/docker/compose/grafana/compose.yml https://raw.githubusercontent.com/Sm1rkBoy/DockerShell/main/compose/grafana/compose.yml

    # 启动临时容器
    docker compose -f /opt/docker/temp/grafana.yml up -d
    docker compose -f /opt/docker/temp/grafana.yml down --volumes

    # 启动 Docker Compose
    docker compose -f /opt/docker/compose/grafana/compose.yml up -d

    if [ $? -eq 0 ]; then
        echo "Grafana 安装成功！"
    else
        echo "Grafana 安装失败！"
    fi
}