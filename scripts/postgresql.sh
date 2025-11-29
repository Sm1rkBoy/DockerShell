#!/bin/bash

# ========================================
# PostgreSQL 安装脚本
# ========================================

install_postgresql() {
    local CONTAINER_NAME="postgresql"
    local DATA_DIR="/opt/docker/${CONTAINER_NAME}"
    local COMPOSE_DIR="/opt/docker/compose/${CONTAINER_NAME}"
    local GITHUB_BASE="https://raw.githubusercontent.com/Sm1rkBoy/DockerShell/main"

    echo "========================================"
    echo "开始安装 PostgreSQL 数据库"
    echo "========================================"
    echo ""

    # 创建必要的目录
    echo "创建目录结构..."
    mkdir -p "${DATA_DIR}"/{apps,config,backup}
    mkdir -p "${COMPOSE_DIR}"

    # 设置目录权限（PostgreSQL 容器使用 postgres 用户，UID 70）
    chown -R 70:70 "${DATA_DIR}/apps" 2>/dev/null || true

    # 提示用户输入配置
    echo ""
    echo "请配置 PostgreSQL 参数："
    echo ""

    # 超级用户密码
    read -s -p "请输入 PostgreSQL 超级用户密码 (留空自动生成): " rootPassword
    echo ""

    if [ -z "$rootPassword" ]; then
        rootPassword=$(openssl rand -base64 16 | tr -dc 'a-zA-Z0-9!@#$%^&*' | head -c 16)
        echo "✓ 已生成随机密码: $rootPassword"
    else
        echo "✓ 已设置自定义密码"
    fi

    # 数据库名称
    read -p "请输入默认数据库名 (默认 postgres): " db_name
    db_name=${db_name:-postgres}
    echo "✓ 数据库名: $db_name"

    # 用户名
    read -p "请输入数据库用户名 (默认 postgres): " db_user
    db_user=${db_user:-postgres}
    echo "✓ 用户名: $db_user"

    echo "✓ 端口: 5432 (仅容器内部访问，未暴露到宿主机)"

    echo ""
    echo "保存配置信息..."

    # 保存环境变量
    cat > "${COMPOSE_DIR}/postgresql.env" <<EOF
POSTGRES_PASSWORD=${rootPassword}
POSTGRES_DB=${db_name}
POSTGRES_USER=${db_user}
TZ=Asia/Shanghai
EOF

    # 保存说明文件
    cat > "${DATA_DIR}/README.txt" <<EOF
PostgreSQL 容器信息
=====================================

安装时间: $(date '+%Y-%m-%d %H:%M:%S')

连接信息:
-----------
容器名: postgresql (仅 Docker 网络内访问)
端口: 5432
数据库: ${db_name}
用户名: ${db_user}
密码: ${rootPassword}

数据目录:
-----------
数据文件: ${DATA_DIR}/apps
备份目录: ${DATA_DIR}/backup
日志查看: docker logs -f postgresql

连接命令:
-----------
从容器内: docker exec -it postgresql psql -U ${db_user} -d ${db_name}
从其他容器: psql -h postgresql -p 5432 -U ${db_user} -d ${db_name}

连接字符串:
-----------
postgresql://${db_user}:${rootPassword}@postgresql:5432/${db_name}

如需从宿主机访问，请手动添加端口映射:
docker stop postgresql
编辑 /opt/docker/compose/postgresql/compose.yml 添加: - "5432:5432"
docker start postgresql

Docker 命令:
-----------
进入容器: docker exec -it postgresql bash
进入数据库: docker exec -it postgresql psql -U ${db_user}
查看日志: docker logs -f postgresql
重启容器: docker restart postgresql
停止容器: docker stop postgresql
启动容器: docker start postgresql

备份命令:
-----------
docker exec postgresql pg_dump -U ${db_user} ${db_name} > backup.sql

恢复命令:
-----------
docker exec -i postgresql psql -U ${db_user} ${db_name} < backup.sql
=====================================
EOF

    echo "✓ 配置文件已保存到: ${COMPOSE_DIR}/postgresql.env"
    echo "✓ 说明文件已保存到: ${DATA_DIR}/README.txt"

    # 下载 compose 文件
    echo ""
    echo "下载 Docker Compose 配置文件..."

    wget -O "${COMPOSE_DIR}/compose.yml" "${GITHUB_BASE}/compose/postgresql/compose.yml"
    if [ $? -eq 0 ]; then
        echo "✓ Docker Compose 配置文件已下载"
    else
        echo "✗ Docker Compose 配置文件下载失败"
        return 1
    fi

    # 启动容器
    echo ""
    echo "启动 PostgreSQL 容器..."

    if docker compose -f "${COMPOSE_DIR}/compose.yml" up -d; then
        echo ""
        echo "========================================"
        echo "✓ PostgreSQL 安装成功！"
        echo "========================================"
        echo ""
        echo "连接信息:"
        echo "  容器名: postgresql (仅 Docker 网络内访问)"
        echo "  数据库: ${db_name}"
        echo "  用户: ${db_user}"
        echo "  密码: ${rootPassword}"
        echo ""
        echo "连接字符串:"
        echo "  postgresql://${db_user}:${rootPassword}@postgresql:5432/${db_name}"
        echo ""
        echo "⚠ 注意: 端口未暴露到宿主机，仅供容器间访问"
        echo ""
        echo "数据目录: ${DATA_DIR}"
        echo "配置文件: ${DATA_DIR}/README.txt"
        echo ""
        echo "等待 PostgreSQL 启动完成..."
        sleep 5

        if docker ps | grep -q "postgresql"; then
            echo "✓ PostgreSQL 容器运行正常"
        else
            echo "⚠ PostgreSQL 容器可能未正常启动，请检查日志"
        fi

        return 0
    else
        echo ""
        echo "✗ PostgreSQL 安装失败！"
        return 1
    fi
}
