#!/bin/bash

# ========================================
# Nginx 安装脚本
# ========================================

install_nginx(){
    local CONTAINER_NAME="nginx"
    local DATA_DIR="/opt/docker/${CONTAINER_NAME}"
    local COMPOSE_DIR="/opt/docker/compose/${CONTAINER_NAME}"
    local GITHUB_BASE="https://raw.githubusercontent.com/Sm1rkBoy/DockerShell/main"

    echo "========================================"
    echo "开始安装 Nginx 反向代理"
    echo "========================================"
    echo ""

    # 创建必要的目录
    echo "创建目录结构..."
    mkdir -p "${DATA_DIR}"/{config/conf.d,html,log,ssl}
    mkdir -p "${COMPOSE_DIR}"

    # 端口配置
    read -p "请输入 HTTP 端口 (默认 80): " http_port
    http_port=${http_port:-80}
    echo "✓ HTTP 端口: $http_port"

    read -p "请输入 HTTPS 端口 (默认 443): " https_port
    https_port=${https_port:-443}
    echo "✓ HTTPS 端口: $https_port"

    echo ""
    echo "保存配置信息..."

    # 保存环境变量
    cat > "${COMPOSE_DIR}/nginx.env" <<EOF
HTTP_PORT=${http_port}
HTTPS_PORT=${https_port}
TZ=Asia/Shanghai
EOF

    # 创建默认 nginx 配置
    cat > "${DATA_DIR}/config/nginx.conf" <<'EOF'
user  nginx;
worker_processes  auto;

error_log  /var/log/nginx/error.log notice;
pid        /var/run/nginx.pid;

events {
    worker_connections  1024;
}

http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;

    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;

    sendfile        on;
    tcp_nopush      on;
    tcp_nodelay     on;
    keepalive_timeout  65;
    types_hash_max_size 2048;
    client_max_body_size 100M;

    gzip  on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript application/x-javascript application/xml+rss application/json;

    include /etc/nginx/conf.d/*.conf;
}
EOF

    # 创建默认站点配置
    cat > "${DATA_DIR}/config/conf.d/default.conf" <<'EOF'
server {
    listen       80;
    listen  [::]:80;
    server_name  localhost;

    location / {
        root   /usr/share/nginx/html;
        index  index.html index.htm;
    }

    error_page   500 502 503 504  /50x.html;
    location = /50x.html {
        root   /usr/share/nginx/html;
    }
}
EOF

    # 创建默认主页
    cat > "${DATA_DIR}/html/index.html" <<'EOF'
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Nginx 运行正常</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            max-width: 800px;
            margin: 50px auto;
            padding: 20px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
        }
        .container {
            background: rgba(255, 255, 255, 0.1);
            padding: 40px;
            border-radius: 10px;
            backdrop-filter: blur(10px);
        }
        h1 { margin-top: 0; }
        .status { color: #4ade80; }
    </style>
</head>
<body>
    <div class="container">
        <h1>✓ Nginx 运行正常</h1>
        <p class="status">您的 Nginx 服务器已成功启动！</p>
        <p>配置文件位置: /opt/docker/nginx/config/</p>
        <p>网站文件位置: /opt/docker/nginx/html/</p>
        <p>日志文件位置: /opt/docker/nginx/log/</p>
    </div>
</body>
</html>
EOF

    # 保存说明文件
    cat > "${DATA_DIR}/README.txt" <<EOF
Nginx 容器信息
=====================================

安装时间: $(date '+%Y-%m-%d %H:%M:%S')

访问信息:
-----------
HTTP: http://localhost:${http_port}
HTTPS: https://localhost:${https_port}

目录说明:
-----------
配置文件: ${DATA_DIR}/config/nginx.conf
站点配置: ${DATA_DIR}/config/conf.d/
网站文件: ${DATA_DIR}/html/
日志文件: ${DATA_DIR}/log/
SSL证书: ${DATA_DIR}/ssl/

常用命令:
-----------
进入容器: docker exec -it nginx sh
查看日志: docker logs -f nginx
重载配置: docker exec nginx nginx -s reload
测试配置: docker exec nginx nginx -t
重启容器: docker restart nginx

配置示例:
-----------
反向代理配置文件存放在: ${DATA_DIR}/config/conf.d/
示例: ${DATA_DIR}/config/conf.d/example.conf

SSL 配置:
-----------
将证书文件放在: ${DATA_DIR}/ssl/
然后在配置文件中引用
=====================================
EOF

    echo "✓ 配置文件已保存"

    # 下载 compose 文件
    echo ""
    echo "下载 Docker Compose 配置文件..."

    wget -O "${COMPOSE_DIR}/compose.yml" "${GITHUB_BASE}/compose/nginx/compose.yml"
    if [ $? -eq 0 ]; then
        echo "✓ Docker Compose 配置文件已下载"
    else
        echo "✗ Docker Compose 配置文件下载失败"
        return 1
    fi

    # 启动容器
    echo ""
    echo "启动 Nginx 容器..."

    if docker compose -f "${COMPOSE_DIR}/compose.yml" up -d; then
        echo ""
        echo "========================================"
        echo "✓ Nginx 安装成功！"
        echo "========================================"
        echo ""
        echo "访问地址:"
        echo "  HTTP: http://localhost:${http_port}"
        echo "  HTTPS: https://localhost:${https_port}"
        echo ""
        echo "配置目录: ${DATA_DIR}"
        echo "说明文件: ${DATA_DIR}/README.txt"
        echo ""
        echo "等待 Nginx 启动完成..."
        sleep 2

        if docker ps | grep -q "nginx"; then
            echo "✓ Nginx 容器运行正常"
        else
            echo "⚠ Nginx 容器可能未正常启动，请检查日志"
        fi

        return 0
    else
        echo ""
        echo "✗ Nginx 安装失败！"
        return 1
    fi
}
