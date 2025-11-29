#!/bin/bash

# ========================================
# MySQL 安装脚本
# ========================================

install_mysql() {
    local CONTAINER_NAME="mysql"
    local DATA_DIR="/opt/docker/${CONTAINER_NAME}"
    local COMPOSE_DIR="/opt/docker/compose/${CONTAINER_NAME}"
    local GITHUB_BASE="https://raw.githubusercontent.com/Sm1rkBoy/DockerShell/main"

    echo "========================================"
    echo "开始安装 MySQL 数据库"
    echo "========================================"
    echo ""

    # 创建必要的目录
    echo "创建目录结构..."
    mkdir -p "${DATA_DIR}"/{apps,config,log,backup}
    mkdir -p "${COMPOSE_DIR}"

    # 提示用户输入配置
    echo ""
    echo "请配置 MySQL 参数："
    echo ""

    # MySQL root 密码
    read -s -p "请输入 MySQL root 密码 (留空自动生成): " rootPassword
    echo ""

    if [ -z "$rootPassword" ]; then
        rootPassword=$(openssl rand -base64 16 | tr -dc 'a-zA-Z0-9!@#$%^&*' | head -c 16)
        echo "✓ 已生成随机密码: $rootPassword"
    else
        echo "✓ 已设置自定义密码"
    fi

    echo "✓ 端口: 3306 (仅容器内部访问，未暴露到宿主机)"

    echo ""
    echo "保存配置信息..."

    # 保存环境变量
    cat > "${COMPOSE_DIR}/mysql.env" <<EOF
MYSQL_ROOT_PASSWORD=${rootPassword}
TZ=Asia/Shanghai
EOF

    # 保存密码到说明文件
    cat > "${DATA_DIR}/README.txt" <<EOF
MySQL 容器信息
=====================================

安装时间: $(date '+%Y-%m-%d %H:%M:%S')

连接信息:
-----------
容器名: mysql (仅 Docker 网络内访问)
端口: 3306
用户: root
密码: ${rootPassword}

数据目录:
-----------
数据文件: ${DATA_DIR}/apps
配置文件: ${DATA_DIR}/config
日志文件: ${DATA_DIR}/log
备份目录: ${DATA_DIR}/backup

连接命令:
-----------
从容器内: docker exec -it mysql mysql -u root -p
从其他容器: mysql -h mysql -P 3306 -u root -p${rootPassword}

如需从宿主机访问，请手动添加端口映射:
docker stop mysql
编辑 /opt/docker/compose/mysql/compose.yml 添加: - "3306:3306"
docker start mysql

Docker 命令:
-----------
进入容器: docker exec -it mysql bash
查看日志: docker logs -f mysql
重启容器: docker restart mysql
停止容器: docker stop mysql
启动容器: docker start mysql
=====================================
EOF

    echo "✓ 配置文件已保存到: ${COMPOSE_DIR}/mysql.env"
    echo "✓ 说明文件已保存到: ${DATA_DIR}/README.txt"

    # 下载 compose 文件
    echo ""
    echo "下载 Docker Compose 配置文件..."

    wget -O "${COMPOSE_DIR}/compose.yml" "${GITHUB_BASE}/compose/mysql/compose.yml"
    if [ $? -eq 0 ]; then
        echo "✓ Docker Compose 配置文件已下载"
    else
        echo "✗ Docker Compose 配置文件下载失败"
        return 1
    fi

    # 创建自定义配置文件
    cat > "${DATA_DIR}/config/custom.cnf" <<'EOF'
[mysqld]
# 字符集设置
character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci

# 性能优化
max_connections = 500
max_allowed_packet = 64M
innodb_buffer_pool_size = 256M
innodb_log_file_size = 64M

# 日志设置
log_error = /var/log/mysql/error.log
slow_query_log = 1
slow_query_log_file = /var/log/mysql/slow.log
long_query_time = 2

# 时区设置
default-time-zone = '+08:00'

[client]
default-character-set = utf8mb4
EOF

    echo "✓ MySQL 配置文件已创建"

    # 启动容器
    echo ""
    echo "启动 MySQL 容器..."

    if docker compose -f "${COMPOSE_DIR}/compose.yml" up -d; then
        echo ""
        echo "========================================"
        echo "✓ MySQL 安装成功！"
        echo "========================================"
        echo ""
        echo "连接信息:"
        echo "  容器名: mysql (仅 Docker 网络内访问)"
        echo "  用户: root"
        echo "  密码: ${rootPassword}"
        echo ""
        echo "⚠ 注意: 端口未暴露到宿主机，仅供容器间访问"
        echo ""
        echo "数据目录: ${DATA_DIR}"
        echo "配置文件: ${DATA_DIR}/README.txt"
        echo ""
        echo "等待 MySQL 启动完成..."
        sleep 5

        # 检查容器状态
        if docker ps | grep -q "mysql"; then
            echo "✓ MySQL 容器运行正常"
        else
            echo "⚠ MySQL 容器可能未正常启动，请检查日志"
            echo "  查看日志: docker logs mysql"
        fi

        return 0
    else
        echo ""
        echo "========================================"
        echo "✗ MySQL 安装失败！"
        echo "========================================"
        echo ""
        echo "请检查错误信息并重试"
        return 1
    fi
}
