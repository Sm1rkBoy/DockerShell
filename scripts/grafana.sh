#!/bin/bash

# ========================================
# Grafana 安装脚本
# ========================================

install_grafana() {
    local CONTAINER_NAME="grafana"
    local DATA_DIR="/opt/docker/${CONTAINER_NAME}"
    local COMPOSE_DIR="/opt/docker/compose/${CONTAINER_NAME}"
    local TEMP_DIR="/opt/docker/temp"
    local GITHUB_BASE="https://raw.githubusercontent.com/Sm1rkBoy/DockerShell/main"

    echo "========================================"
    echo "开始安装 Grafana 监控面板"
    echo "========================================"
    echo ""

    # 创建必要的目录
    echo "创建目录结构..."
    mkdir -p "${DATA_DIR}"/{apps,config,log}
    mkdir -p "${COMPOSE_DIR}"
    mkdir -p "${TEMP_DIR}"

    # 提示用户输入配置
    echo ""
    echo "请配置 Grafana 参数："
    echo ""

    read -p "请输入管理员用户名 (默认 grafana): " GF_SECURITY_ADMIN_USER
    GF_SECURITY_ADMIN_USER=${GF_SECURITY_ADMIN_USER:-grafana}
    echo "✓ 管理员用户名: $GF_SECURITY_ADMIN_USER"

    read -s -p "请输入管理员密码 (默认 12345678): " GF_SECURITY_ADMIN_PASSWORD
    echo ""
    GF_SECURITY_ADMIN_PASSWORD=${GF_SECURITY_ADMIN_PASSWORD:-12345678}
    echo "✓ 已设置管理员密码"

    read -p "是否允许用户注册 (默认 false): " GF_USERS_ALLOW_SIGN_UP
    GF_USERS_ALLOW_SIGN_UP=${GF_USERS_ALLOW_SIGN_UP:-false}
    echo "✓ 用户注册: $GF_USERS_ALLOW_SIGN_UP"

    echo "✓ 端口: 3000 (仅容器内部访问，未暴露到宿主机)"

    echo ""
    echo "保存配置信息..."

    # 保存环境变量
    cat > "${COMPOSE_DIR}/grafana.env" <<EOF
GF_PATHS_CONFIG=/etc/grafana/grafana.ini
GF_PATHS_DATA=/var/lib/grafana
GF_PATHS_HOME=/usr/share/grafana
GF_PATHS_LOGS=/var/log/grafana
GF_PATHS_PLUGINS=/var/lib/grafana/plugins
GF_PATHS_PROVISIONING=/etc/grafana/provisioning
GF_SECURITY_ADMIN_USER=${GF_SECURITY_ADMIN_USER}
GF_SECURITY_ADMIN_PASSWORD=${GF_SECURITY_ADMIN_PASSWORD}
GF_USERS_ALLOW_SIGN_UP=${GF_USERS_ALLOW_SIGN_UP}
EOF

    echo "✓ 配置文件已保存到: ${COMPOSE_DIR}/grafana.env"

    # 保存说明文件
    cat > "${DATA_DIR}/README.txt" <<EOF
Grafana 容器信息
=====================================

安装时间: $(date '+%Y-%m-%d %H:%M:%S')

访问信息:
-----------
容器名: grafana (仅 Docker 网络内访问)
端口: 3000
管理员用户: ${GF_SECURITY_ADMIN_USER}
管理员密码: ${GF_SECURITY_ADMIN_PASSWORD}

⚠ 注意: 端口未暴露到宿主机
- 需要通过 Nginx 反向代理访问
- 或手动添加端口映射后才能从宿主机访问

数据目录:
-----------
数据文件: ${DATA_DIR}/apps
配置文件: ${DATA_DIR}/config
日志文件: ${DATA_DIR}/log

通过 Nginx 访问:
-----------
在 Nginx 配置中添加反向代理:
location /grafana/ {
    proxy_pass http://grafana:3000/;
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
}

如需从宿主机直接访问，请手动添加端口映射:
-----------
docker stop grafana
编辑 /opt/docker/compose/grafana/compose.yml 添加: - "3000:3000"
docker start grafana
然后访问: http://localhost:3000

Docker 命令:
-----------
进入容器: docker exec -it grafana sh
查看日志: docker logs -f grafana
重启容器: docker restart grafana
停止容器: docker stop grafana
启动容器: docker start grafana
=====================================
EOF

    echo "✓ 说明文件已保存到: ${DATA_DIR}/README.txt"

    # 下载临时 compose 文件用于初始化
    echo ""
    echo "下载临时配置文件..."

    wget -O "${TEMP_DIR}/grafana.yml" "${GITHUB_BASE}/temp/grafana.yml"
    if [ $? -eq 0 ]; then
        echo "✓ 临时配置文件已下载"

        # 启动临时容器进行初始化
        echo "启动临时容器初始化目录..."
        docker compose -f "${TEMP_DIR}/grafana.yml" up -d
        sleep 3
        docker compose -f "${TEMP_DIR}/grafana.yml" down --volumes
        echo "✓ 目录初始化完成"
    else
        echo "⚠ 警告: 临时配置文件下载失败，跳过初始化步骤"
    fi

    # 下载正式 compose 文件
    echo ""
    echo "下载 Docker Compose 配置文件..."

    wget -O "${COMPOSE_DIR}/compose.yml" "${GITHUB_BASE}/compose/grafana/compose.yml"
    if [ $? -eq 0 ]; then
        echo "✓ Docker Compose 配置文件已下载"
    else
        echo "✗ Docker Compose 配置文件下载失败"
        return 1
    fi

    # 启动容器
    echo ""
    echo "启动 Grafana 容器..."

    if docker compose -f "${COMPOSE_DIR}/compose.yml" up -d; then
        echo ""
        echo "========================================"
        echo "✓ Grafana 安装成功！"
        echo "========================================"
        echo ""
        echo "访问信息:"
        echo "  容器名: grafana (仅 Docker 网络内访问)"
        echo "  管理员用户: ${GF_SECURITY_ADMIN_USER}"
        echo "  管理员密码: ${GF_SECURITY_ADMIN_PASSWORD}"
        echo ""
        echo "⚠ 注意: 端口未暴露到宿主机，仅供容器间访问"
        echo ""
        echo "访问方式:"
        echo "  1. 通过 Nginx 反向代理访问（推荐）"
        echo "  2. 或手动添加端口映射后从宿主机访问"
        echo ""
        echo "配置文件: ${DATA_DIR}/README.txt"
        echo ""
        echo "等待 Grafana 启动完成..."
        sleep 5

        if docker ps | grep -q "grafana"; then
            echo "✓ Grafana 容器运行正常"
        else
            echo "⚠ Grafana 容器可能未正常启动，请检查日志"
        fi

        return 0
    else
        echo ""
        echo "✗ Grafana 安装失败！"
        return 1
    fi
}
