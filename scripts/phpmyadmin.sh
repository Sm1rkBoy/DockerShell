#!/bin/bash

install_phpmyadmin(){
    # 创建目录
    mkdir -p /opt/docker/phpmyadmin

    echo "下载 phpmyadmin 的compose.yml文件"
    wget -O /opt/docker/compose/phpmyadmin/compose.yml https://raw.githubusercontent.com/Sm1rkBoy/DockerShell/main/compose/phpmyadmin/compose.yml

    # 启动 Docker Compose
    docker compose -f /opt/docker/compose/phpmyadmin/compose.yml up -d

    if [ $? -eq 0 ]; then
        echo "phpmyadmin 安装成功！"
    else
        echo "phpmyadmin 安装失败！"
    fi
}
