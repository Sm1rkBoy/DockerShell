#!/bin/bash

# ========================================
# Redis 安装脚本
# ========================================

install_redis() {
    local CONTAINER_NAME="redis"
    local DATA_DIR="/opt/docker/${CONTAINER_NAME}"
    local COMPOSE_DIR="/opt/docker/compose/${CONTAINER_NAME}"
    local GITHUB_BASE="https://raw.githubusercontent.com/Sm1rkBoy/DockerShell/main"

    echo "========================================"
    echo "开始安装 Redis 缓存服务"
    echo "========================================"
    echo ""

    # 创建必要的目录
    echo "创建目录结构..."
    mkdir -p "${DATA_DIR}"/{apps,config,log}
    mkdir -p "${COMPOSE_DIR}"

    # 提示用户输入配置
    echo ""
    echo "请配置 Redis 参数："
    echo ""

    # Redis 密码
    read -s -p "请输入 Redis 密码 (留空自动生成): " redisPassword
    echo ""

    if [ -z "$redisPassword" ]; then
        redisPassword=$(openssl rand -base64 16 | tr -dc 'a-zA-Z0-9!@#$%^&*' | head -c 16)
        echo "✓ 已生成随机密码: $redisPassword"
    else
        echo "✓ 已设置自定义密码"
    fi

    # 最大内存配置
    read -p "请输入最大内存限制 (默认 256mb): " max_memory
    max_memory=${max_memory:-256mb}
    echo "✓ 最大内存: $max_memory"

    echo "✓ 端口: 6379 (仅容器内部访问，未暴露到宿主机)"

    echo ""
    echo "保存配置信息..."

    # 保存环境变量
    cat > "${COMPOSE_DIR}/redis.env" <<EOF
REDIS_PASSWORD=${redisPassword}
TZ=Asia/Shanghai
EOF

    # 创建 Redis 配置文件
    cat > "${DATA_DIR}/config/redis.conf" <<EOF
# Redis 配置文件

# 绑定地址
bind 0.0.0.0

# 端口
port 6379

# 密码
requirepass ${redisPassword}

# 最大内存
maxmemory ${max_memory}
maxmemory-policy allkeys-lru

# 持久化
save 900 1
save 300 10
save 60 10000

# AOF 持久化
appendonly yes
appendfilename "appendonly.aof"
appendfsync everysec

# 日志
loglevel notice
logfile ""

# 数据库数量
databases 16

# 时区
# timezone Asia/Shanghai

# 其他设置
timeout 300
tcp-keepalive 300
daemonize no
supervised no
pidfile /var/run/redis_6379.pid
dir /data
EOF

    # 保存信息到说明文件
    cat > "${DATA_DIR}/README.txt" <<EOF
Redis 容器信息
=====================================

安装时间: $(date '+%Y-%m-%d %H:%M:%S')

连接信息:
-----------
容器名: redis (仅 Docker 网络内访问)
端口: 6379
密码: ${redisPassword}

数据目录:
-----------
数据文件: ${DATA_DIR}/apps
配置文件: ${DATA_DIR}/config/redis.conf
日志文件: ${DATA_DIR}/log

连接命令:
-----------
从容器内: docker exec -it redis redis-cli -a "${redisPassword}"
从其他容器: redis-cli -h redis -p 6379 -a "${redisPassword}"

连接字符串:
-----------
redis://:${redisPassword}@redis:6379

如需从宿主机访问，请手动添加端口映射:
docker stop redis
编辑 /opt/docker/compose/redis/compose.yml 添加: - "6379:6379"
docker start redis

Docker 命令:
-----------
进入容器: docker exec -it redis sh
查看日志: docker logs -f redis
重启容器: docker restart redis
停止容器: docker stop redis
启动容器: docker start redis

性能监控:
-----------
docker exec -it redis redis-cli -a "${redisPassword}" INFO
docker exec -it redis redis-cli -a "${redisPassword}" MONITOR
=====================================
EOF

    echo "✓ 配置文件已保存"

    # 下载 compose 文件
    echo ""
    echo "下载 Docker Compose 配置文件..."

    wget -O "${COMPOSE_DIR}/compose.yml" "${GITHUB_BASE}/compose/redis/compose.yml"
    if [ $? -eq 0 ]; then
        echo "✓ Docker Compose 配置文件已下载"
    else
        echo "✗ Docker Compose 配置文件下载失败"
        return 1
    fi

    # 启动容器
    echo ""
    echo "启动 Redis 容器..."

    if docker compose -f "${COMPOSE_DIR}/compose.yml" up -d; then
        echo ""
        echo "========================================"
        echo "✓ Redis 安装成功！"
        echo "========================================"
        echo ""
        echo "连接信息:"
        echo "  容器名: redis (仅 Docker 网络内访问)"
        echo "  密码: ${redisPassword}"
        echo ""
        echo "连接字符串:"
        echo "  redis://:${redisPassword}@redis:6379"
        echo ""
        echo "⚠ 注意: 端口未暴露到宿主机，仅供容器间访问"
        echo ""
        echo "数据目录: ${DATA_DIR}"
        echo "配置文件: ${DATA_DIR}/README.txt"
        echo ""
        echo "等待 Redis 启动完成..."
        sleep 3

        # 检查容器状态
        if docker ps | grep -q "redis"; then
            echo "✓ Redis 容器运行正常"
        else
            echo "⚠ Redis 容器可能未正常启动，请检查日志"
            echo "  查看日志: docker logs redis"
        fi

        return 0
    else
        echo ""
        echo "========================================"
        echo "✗ Redis 安装失败！"
        echo "========================================"
        echo ""
        echo "请检查错误信息并重试"
        return 1
    fi
}
