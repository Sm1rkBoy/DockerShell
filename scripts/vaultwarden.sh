#!/bin/bash

# ========================================
# Vaultwarden 安装脚本
# ========================================

install_vaultwarden() {
    local CONTAINER_NAME="vaultwarden"
    local DATA_DIR="/opt/docker/${CONTAINER_NAME}"
    local COMPOSE_DIR="/opt/docker/compose/${CONTAINER_NAME}"
    local GITHUB_BASE="https://raw.githubusercontent.com/Sm1rkBoy/DockerShell/main"

    echo "========================================"
    echo "开始安装 Vaultwarden 密码管理器"
    echo "========================================"
    echo ""

    # 创建必要的目录
    echo "创建目录结构..."
    mkdir -p "${DATA_DIR}"/{apps,backup}
    mkdir -p "${COMPOSE_DIR}"

    echo "✓ 端口: 80 (仅容器内部访问，未暴露到宿主机)"

    # 生成管理员 Token
    ADMIN_TOKEN=$(openssl rand -base64 48)

    echo ""
    echo "保存配置信息..."

    # 保存环境变量
    cat > "${COMPOSE_DIR}/vaultwarden.env" <<EOF
# 管理员 Token
ADMIN_TOKEN=${ADMIN_TOKEN}

# 基础设置
SIGNUPS_ALLOWED=true
INVITATIONS_ALLOWED=true
SHOW_PASSWORD_HINT=false

# WebSocket 支持
WEBSOCKET_ENABLED=true

# 日志设置
LOG_LEVEL=warn
EXTENDED_LOGGING=true

# 时区
TZ=Asia/Shanghai
EOF

    # 保存说明文件
    cat > "${DATA_DIR}/README.txt" <<EOF
Vaultwarden 容器信息
=====================================

安装时间: $(date '+%Y-%m-%d %H:%M:%S')

访问信息:
-----------
容器名: vaultwarden (仅 Docker 网络内访问)
Web 端口: 80
管理员 Token: ${ADMIN_TOKEN}

⚠ 注意: 端口未暴露到宿主机
- 需要通过 Nginx 反向代理访问
- 或手动添加端口映射后才能从宿主机访问

数据目录:
-----------
数据文件: ${DATA_DIR}/apps
备份目录: ${DATA_DIR}/backup

通过 Nginx 访问:
-----------
在 Nginx 配置中添加反向代理:
location /vault {
    proxy_pass http://vaultwarden:80;
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
}

如需从宿主机直接访问，请手动添加端口映射:
-----------
docker stop vaultwarden
编辑 /opt/docker/compose/vaultwarden/compose.yml 添加: - "8000:80"
docker start vaultwarden
然后访问: http://localhost:8000

首次使用:
-----------
1. 通过 Nginx 或端口映射访问 Web 界面
2. 创建第一个账户（首次注册后建议关闭注册）
3. 访问 /admin 管理容器
4. 使用上面的 Token 登录管理面板

关闭注册:
-----------
1. 编辑配置文件: ${COMPOSE_DIR}/vaultwarden.env
2. 修改: SIGNUPS_ALLOWED=false
3. 重启容器: docker restart vaultwarden

Docker 命令:
-----------
进入容器: docker exec -it vaultwarden sh
查看日志: docker logs -f vaultwarden
重启容器: docker restart vaultwarden
停止容器: docker stop vaultwarden
启动容器: docker start vaultwarden

高级配置:
-----------
如需配置 SMTP、数据库等，请编辑配置文件:
${COMPOSE_DIR}/vaultwarden.env

配置参考: https://github.com/dani-garcia/vaultwarden/wiki
=====================================
EOF

    echo "✓ 配置文件已保存"

    # 下载 compose 文件
    echo ""
    echo "下载 Docker Compose 配置文件..."

    wget -O "${COMPOSE_DIR}/compose.yml" "${GITHUB_BASE}/compose/vaultwarden/compose.yml"
    if [ $? -eq 0 ]; then
        echo "✓ Docker Compose 配置文件已下载"
    else
        echo "✗ Docker Compose 配置文件下载失败"
        return 1
    fi

    # 启动容器
    echo ""
    echo "启动 Vaultwarden 容器..."

    if docker compose -f "${COMPOSE_DIR}/compose.yml" up -d; then
        echo ""
        echo "========================================"
        echo "✓ Vaultwarden 安装成功！"
        echo "========================================"
        echo ""
        echo "容器信息:"
        echo "  容器名: vaultwarden (仅 Docker 网络内访问)"
        echo "  Web 端口: 80"
        echo ""
        echo "管理员 Token:"
        echo "  ${ADMIN_TOKEN}"
        echo ""
        echo "⚠ 注意: 端口未暴露到宿主机，仅供容器间访问"
        echo ""
        echo "访问方式:"
        echo "  1. 通过 Nginx 反向代理访问（推荐）"
        echo "  2. 或手动添加端口映射后从宿主机访问"
        echo ""
        echo "配置文件: ${DATA_DIR}/README.txt"
        echo ""
        echo "⚠ 重要提示:"
        echo "  1. 首次访问请先创建账户"
        echo "  2. 创建账户后建议关闭注册功能"
        echo "  3. 管理员 Token 已保存在配置文件中"
        echo ""
        echo "等待 Vaultwarden 启动完成..."
        sleep 3

        if docker ps | grep -q "vaultwarden"; then
            echo "✓ Vaultwarden 容器运行正常"
        else
            echo "⚠ Vaultwarden 容器可能未正常启动，请检查日志"
        fi

        return 0
    else
        echo ""
        echo "✗ Vaultwarden 安装失败！"
        return 1
    fi
}
