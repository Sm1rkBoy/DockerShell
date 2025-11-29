#!/bin/bash

# ========================================
# VictoriaMetrics 安装脚本
# ========================================

install_victoriametrics() {
    local CONTAINER_NAME="victoriametrics"
    local DATA_DIR="/opt/docker/${CONTAINER_NAME}"
    local COMPOSE_DIR="/opt/docker/compose/${CONTAINER_NAME}"
    local TEMP_DIR="/opt/docker/temp"
    local GITHUB_BASE="https://raw.githubusercontent.com/Sm1rkBoy/DockerShell/main"

    echo "========================================"
    echo "开始安装 VictoriaMetrics 时序数据库"
    echo "========================================"
    echo ""

    # 创建必要的目录
    echo "创建目录结构..."
    mkdir -p "${DATA_DIR}/apps"
    mkdir -p "${COMPOSE_DIR}"
    mkdir -p "${TEMP_DIR}"

    # 提示用户输入配置
    echo ""
    echo "请配置 VictoriaMetrics 参数："
    echo ""

    read -p "请输入 VictoriaMetrics 的用户名: " VM_USERNAME
    if [[ -z "$VM_USERNAME" ]]; then
        echo "✗ 错误：用户名不能为空！"
        return 1
    fi
    echo "✓ 用户名: $VM_USERNAME"

    read -sp "请输入 VictoriaMetrics 的密码: " VM_PASSWORD
    echo ""
    if [[ -z "$VM_PASSWORD" ]]; then
        echo "✗ 错误：密码不能为空！"
        return 1
    fi
    echo "✓ 已设置密码"

    echo "✓ 端口: 8428 (仅容器内部访问，未暴露到宿主机)"

    echo ""
    echo "保存配置信息..."

    # 保存说明文件
    cat > "${DATA_DIR}/README.txt" <<EOF
VictoriaMetrics 容器信息
=====================================

安装时间: $(date '+%Y-%m-%d %H:%M:%S')

访问信息:
-----------
容器名: victoriametrics (仅 Docker 网络内访问)
端口: 8428
用户名: ${VM_USERNAME}
密码: ${VM_PASSWORD}
数据保留期: 90天

⚠ 注意: 端口未暴露到宿主机
- 需要通过 Nginx 反向代理访问
- 或手动添加端口映射后才能从宿主机访问

数据目录:
-----------
数据文件: ${DATA_DIR}/apps

通过 Nginx 访问:
-----------
在 Nginx 配置中添加反向代理:
location /victoriametrics/ {
    proxy_pass http://victoriametrics:8428/;
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
}

如需从宿主机直接访问，请手动添加端口映射:
-----------
docker stop victoriametrics
编辑 /opt/docker/compose/victoriametrics/compose.yml 添加: - "8428:8428"
docker start victoriametrics
然后访问: http://localhost:8428

API 使用示例:
-----------
写入数据:
curl -u '${VM_USERNAME}:${VM_PASSWORD}' -d 'measurement,tag1=value1 field1=123' http://victoriametrics:8428/write

查询数据:
curl -u '${VM_USERNAME}:${VM_PASSWORD}' http://victoriametrics:8428/api/v1/query?query=up

Docker 命令:
-----------
进入容器: docker exec -it victoriametrics sh
查看日志: docker logs -f victoriametrics
重启容器: docker restart victoriametrics
停止容器: docker stop victoriametrics
启动容器: docker start victoriametrics
=====================================
EOF

    echo "✓ 说明文件已保存到: ${DATA_DIR}/README.txt"

    # 下载临时 compose 文件用于初始化
    echo ""
    echo "下载临时配置文件..."

    wget -O "${TEMP_DIR}/victoriametrics.yml" "${GITHUB_BASE}/temp/victoriametrics.yml"
    if [ $? -eq 0 ]; then
        echo "✓ 临时配置文件已下载"

        # 启动临时容器进行初始化
        echo "启动临时容器初始化目录..."
        docker compose -f "${TEMP_DIR}/victoriametrics.yml" up -d
        sleep 3
        docker compose -f "${TEMP_DIR}/victoriametrics.yml" down --volumes
        echo "✓ 目录初始化完成"
    else
        echo "⚠ 警告: 临时配置文件下载失败，跳过初始化步骤"
    fi

    # 下载正式 compose 文件
    echo ""
    echo "下载 Docker Compose 配置文件..."

    wget -O "${COMPOSE_DIR}/compose.yml" "${GITHUB_BASE}/compose/victoriametrics/compose.yml"
    if [ $? -eq 0 ]; then
        # 使用 sed 替换用户名和密码占位符
        sed -i "s/__USERNAME__/${VM_USERNAME}/g" "${COMPOSE_DIR}/compose.yml"
        sed -i "s/__PASSWORD__/${VM_PASSWORD}/g" "${COMPOSE_DIR}/compose.yml"

        echo "✓ Docker Compose 配置文件已下载并配置"
    else
        echo "✗ Docker Compose 配置文件下载失败"
        return 1
    fi

    # 启动容器
    echo ""
    echo "启动 VictoriaMetrics 容器..."

    if docker compose -f "${COMPOSE_DIR}/compose.yml" up -d; then
        echo ""
        echo "========================================"
        echo "✓ VictoriaMetrics 安装成功！"
        echo "========================================"
        echo ""
        echo "访问信息:"
        echo "  容器名: victoriametrics (仅 Docker 网络内访问)"
        echo "  用户名: ${VM_USERNAME}"
        echo "  密码: ${VM_PASSWORD}"
        echo ""
        echo "⚠ 注意: 端口未暴露到宿主机，仅供容器间访问"
        echo ""
        echo "访问方式:"
        echo "  1. 通过 Nginx 反向代理访问（推荐）"
        echo "  2. 或手动添加端口映射后从宿主机访问"
        echo ""
        echo "配置文件: ${DATA_DIR}/README.txt"
        echo ""
        echo "等待 VictoriaMetrics 启动完成..."
        sleep 3

        if docker ps | grep -q "victoriametrics"; then
            echo "✓ VictoriaMetrics 容器运行正常"
        else
            echo "⚠ VictoriaMetrics 容器可能未正常启动，请检查日志"
        fi

        return 0
    else
        echo ""
        echo "✗ VictoriaMetrics 安装失败！"
        return 1
    fi
}
