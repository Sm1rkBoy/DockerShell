#!/bin/bash

# ========================================
# phpMyAdmin 安装脚本
# ========================================

install_phpmyadmin(){
    local CONTAINER_NAME="phpmyadmin"
    local DATA_DIR="/opt/docker/${CONTAINER_NAME}"
    local COMPOSE_DIR="/opt/docker/compose/${CONTAINER_NAME}"
    local GITHUB_BASE="https://raw.githubusercontent.com/Sm1rkBoy/DockerShell/main"

    echo "========================================"
    echo "开始安装 phpMyAdmin"
    echo "========================================"
    echo ""

    # 创建必要的目录
    echo "创建目录结构..."
    mkdir -p "${DATA_DIR}"
    mkdir -p "${COMPOSE_DIR}"

    echo "✓ 端口: 80 (仅容器内部访问，未暴露到宿主机)"
    echo "✓ 通过 Nginx 反向代理访问"

    # 下载 compose 文件
    echo ""
    echo "下载 Docker Compose 配置文件..."

    wget -O "${COMPOSE_DIR}/compose.yml" "${GITHUB_BASE}/compose/phpmyadmin/compose.yml"
    if [ $? -eq 0 ]; then
        echo "✓ Docker Compose 配置文件已下载"
    else
        echo "✗ Docker Compose 配置文件下载失败"
        return 1
    fi

    # 启动容器
    echo ""
    echo "启动 phpMyAdmin 容器..."

    if docker compose -f "${COMPOSE_DIR}/compose.yml" up -d; then
        echo ""
        echo "========================================"
        echo "✓ phpMyAdmin 安装成功！"
        echo "========================================"
        echo ""
        echo "访问信息:"
        echo "  容器名: phpmyadmin (仅 Docker 网络内访问)"
        echo "  ⚠ 需要通过 Nginx 反向代理访问"
        echo ""
        echo "等待 phpMyAdmin 启动完成..."
        sleep 3

        if docker ps | grep -q "phpmyadmin"; then
            echo "✓ phpMyAdmin 容器运行正常"
        else
            echo "⚠ phpMyAdmin 容器可能未正常启动，请检查日志"
        fi

        return 0
    else
        echo ""
        echo "✗ phpMyAdmin 安装失败！"
        return 1
    fi
}
