#!/bin/bash

# ========================================
# Prometheus 安装脚本
# ========================================

install_prometheus() {
    local CONTAINER_NAME="prometheus"
    local DATA_DIR="/opt/docker/${CONTAINER_NAME}"
    local COMPOSE_DIR="/opt/docker/compose/${CONTAINER_NAME}"
    local TEMP_DIR="/opt/docker/temp"
    local GITHUB_BASE="https://raw.githubusercontent.com/Sm1rkBoy/DockerShell/main"

    echo "========================================"
    echo "开始安装 Prometheus 监控系统"
    echo "========================================"
    echo ""

    # 创建必要的目录
    echo "创建目录结构..."
    mkdir -p "${DATA_DIR}"/{apps,config}
    mkdir -p "${COMPOSE_DIR}"
    mkdir -p "${TEMP_DIR}"

    echo "✓ 端口: 9090 (仅容器内部访问，未暴露到宿主机)"

    echo ""
    echo "保存配置信息..."

    # 创建默认 prometheus 配置文件
    if [ ! -f "${DATA_DIR}/config/prometheus.yml" ]; then
        cat > "${DATA_DIR}/config/prometheus.yml" <<'EOF'
# Prometheus 配置文件
global:
  scrape_interval: 15s
  evaluation_interval: 15s

# 告警管理器配置
alerting:
  alertmanagers:
    - static_configs:
        - targets: []

# 规则文件
rule_files: []

# 抓取配置
scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
EOF
        echo "✓ 默认配置文件已创建"
    else
        echo "✓ 配置文件已存在，跳过创建"
    fi

    # 保存说明文件
    cat > "${DATA_DIR}/README.txt" <<EOF
Prometheus 容器信息
=====================================

安装时间: $(date '+%Y-%m-%d %H:%M:%S')

访问信息:
-----------
容器名: prometheus (仅 Docker 网络内访问)
端口: 9090

⚠ 注意: 端口未暴露到宿主机
- 需要通过 Nginx 反向代理访问
- 或手动添加端口映射后才能从宿主机访问

数据目录:
-----------
数据文件: ${DATA_DIR}/apps
配置文件: ${DATA_DIR}/config/prometheus.yml

通过 Nginx 访问:
-----------
在 Nginx 配置中添加反向代理:
location /prometheus/ {
    proxy_pass http://prometheus:9090/;
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
}

如需从宿主机直接访问，请手动添加端口映射:
-----------
docker stop prometheus
编辑 /opt/docker/compose/prometheus/compose.yml 添加: - "9090:9090"
docker start prometheus
然后访问: http://localhost:9090

配置说明:
-----------
编辑配置文件: ${DATA_DIR}/config/prometheus.yml
重载配置: docker exec prometheus kill -HUP 1

Docker 命令:
-----------
进入容器: docker exec -it prometheus sh
查看日志: docker logs -f prometheus
重启容器: docker restart prometheus
停止容器: docker stop prometheus
启动容器: docker start prometheus
=====================================
EOF

    echo "✓ 说明文件已保存到: ${DATA_DIR}/README.txt"

    # 下载临时 compose 文件用于初始化
    echo ""
    echo "下载临时配置文件..."

    wget -O "${TEMP_DIR}/prometheus.yml" "${GITHUB_BASE}/temp/prometheus.yml"
    if [ $? -eq 0 ]; then
        echo "✓ 临时配置文件已下载"

        # 启动临时容器进行初始化
        echo "启动临时容器初始化目录..."
        docker compose -f "${TEMP_DIR}/prometheus.yml" up -d
        sleep 3
        docker compose -f "${TEMP_DIR}/prometheus.yml" down --volumes

        # 删除临时生成的目录链接
        rm -f "${DATA_DIR}/config/console_libraries" 2>/dev/null || true
        rm -f "${DATA_DIR}/config/consoles" 2>/dev/null || true

        echo "✓ 目录初始化完成"
    else
        echo "⚠ 警告: 临时配置文件下载失败，跳过初始化步骤"
    fi

    # 下载正式 compose 文件
    echo ""
    echo "下载 Docker Compose 配置文件..."

    wget -O "${COMPOSE_DIR}/compose.yml" "${GITHUB_BASE}/compose/prometheus/compose.yml"
    if [ $? -eq 0 ]; then
        echo "✓ Docker Compose 配置文件已下载"
    else
        echo "✗ Docker Compose 配置文件下载失败"
        return 1
    fi

    # 启动容器
    echo ""
    echo "启动 Prometheus 容器..."

    if docker compose -f "${COMPOSE_DIR}/compose.yml" up -d; then
        echo ""
        echo "========================================"
        echo "✓ Prometheus 安装成功！"
        echo "========================================"
        echo ""
        echo "访问信息:"
        echo "  容器名: prometheus (仅 Docker 网络内访问)"
        echo ""
        echo "⚠ 注意: 端口未暴露到宿主机，仅供容器间访问"
        echo ""
        echo "访问方式:"
        echo "  1. 通过 Nginx 反向代理访问（推荐）"
        echo "  2. 或手动添加端口映射后从宿主机访问"
        echo ""
        echo "配置文件:"
        echo "  ${DATA_DIR}/config/prometheus.yml"
        echo "  ${DATA_DIR}/README.txt"
        echo ""
        echo "等待 Prometheus 启动完成..."
        sleep 3

        if docker ps | grep -q "prometheus"; then
            echo "✓ Prometheus 容器运行正常"
        else
            echo "⚠ Prometheus 容器可能未正常启动，请检查日志"
        fi

        return 0
    else
        echo ""
        echo "✗ Prometheus 安装失败！"
        return 1
    fi
}
