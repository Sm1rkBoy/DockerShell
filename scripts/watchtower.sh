#!/bin/bash

# ========================================
# Watchtower 安装脚本
# ========================================

install_watchtower(){
    local CONTAINER_NAME="watchtower"
    local DATA_DIR="/opt/docker/${CONTAINER_NAME}"
    local COMPOSE_DIR="/opt/docker/compose/${CONTAINER_NAME}"
    local GITHUB_BASE="https://raw.githubusercontent.com/Sm1rkBoy/DockerShell/main"

    echo "========================================"
    echo "开始安装 Watchtower 容器自动更新工具"
    echo "========================================"
    echo ""

    # 创建必要的目录
    echo "创建目录结构..."
    mkdir -p "${DATA_DIR}"
    mkdir -p "${COMPOSE_DIR}"

    echo "✓ Watchtower 将监控并自动更新带有标签的容器"
    echo "✓ 使用 host 网络模式，无需端口配置"

    # 保存说明文件
    cat > "${DATA_DIR}/README.txt" <<EOF
Watchtower 容器信息
=====================================

安装时间: $(date '+%Y-%m-%d %H:%M:%S')

功能说明:
-----------
Watchtower 是一个自动更新 Docker 容器的工具
它会定期检查容器使用的镜像是否有新版本
如果发现新版本，会自动拉取并重启容器

配置说明:
-----------
- 网络模式: host (使用宿主机网络)
- 标签启用: 仅更新带有标签的容器
- 自动清理: 更新后自动清理旧镜像

为容器启用自动更新:
-----------
在容器的 docker-compose.yml 中添加标签:
labels:
  com.centurylinklabs.watchtower.enable: true

示例:
services:
  myapp:
    image: myapp:latest
    labels:
      com.centurylinklabs.watchtower.enable: true

Docker 命令:
-----------
查看日志: docker logs -f watchtower
重启容器: docker restart watchtower
停止容器: docker stop watchtower
启动容器: docker start watchtower

注意事项:
-----------
1. Watchtower 本身已启用自动更新标签
2. 其他容器需要手动添加标签才会被监控
3. 建议在生产环境谨慎使用自动更新
4. 可以在 compose.yml 中调整检查间隔
=====================================
EOF

    echo "✓ 说明文件已保存到: ${DATA_DIR}/README.txt"

    # 下载 compose 文件
    echo ""
    echo "下载 Docker Compose 配置文件..."

    wget -O "${COMPOSE_DIR}/compose.yml" "${GITHUB_BASE}/compose/watchtower/compose.yml"
    if [ $? -eq 0 ]; then
        echo "✓ Docker Compose 配置文件已下载"
    else
        echo "✗ Docker Compose 配置文件下载失败"
        return 1
    fi

    # 启动容器
    echo ""
    echo "启动 Watchtower 容器..."

    if docker compose -f "${COMPOSE_DIR}/compose.yml" up -d; then
        echo ""
        echo "========================================"
        echo "✓ Watchtower 安装成功！"
        echo "========================================"
        echo ""
        echo "容器信息:"
        echo "  容器名: watchtower"
        echo "  网络模式: host"
        echo ""
        echo "功能说明:"
        echo "  ✓ 自动监控容器更新"
        echo "  ✓ 仅更新带有标签的容器"
        echo "  ✓ 自动清理旧镜像"
        echo ""
        echo "配置文件: ${DATA_DIR}/README.txt"
        echo ""
        echo "等待 Watchtower 启动完成..."
        sleep 3

        if docker ps | grep -q "watchtower"; then
            echo "✓ Watchtower 容器运行正常"
        else
            echo "⚠ Watchtower 容器可能未正常启动，请检查日志"
        fi

        return 0
    else
        echo ""
        echo "✗ Watchtower 安装失败！"
        return 1
    fi
}
