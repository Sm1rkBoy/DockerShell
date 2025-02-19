#!/bin/bash

install_nezha() {
    # 创建目录
    mkdir -p /opt/docker/nezha/{apps,config,compose,log}

    echo "下载 nezha 的compose.yml文件"
    wget -O /opt/docker/nezha/compose/compose.yml https://raw.githubusercontent.com/Sm1rkBoy/DockerShell/main/compose/nezha/compose.yml

    # 启动 Docker Compose
    docker compose -f /opt/docker/nezha/compose/compose.yml up -d

    # 定义要修改的文件路径
    CONFIG_FILE="/opt/docker/nezha/apps/config.yaml"
    read -p "请输入网站徽标: " SITENAME
    sed -i "s/sitename: .*/sitename: $SITENAME/" "$CONFIG_FILE"
    read -p "请输入Agent对接地址(IP:PORT): " INSTALLHOST
    sed -i "s/installhost: .*/installhost: $INSTALLHOST/" "$CONFIG_FILE"
    sed -i 's/language: .*/language: zh_CN/' "$CONFIG_FILE"

    # 重新启动 Docker Compose 重建nezha
    docker compose -f /opt/docker/nezha/compose/compose.yml up -d

    if [ $? -eq 0 ]; then
        echo "nezha 安装成功！"
    else
        echo "nezha 安装失败！"
    fi
}