#!/bin/bash

install_vaultwarden() {
    # 创建目录
    mkdir -p /opt/docker/vaultwarden/{apps,config,compose,log}

    # 初始化配置文件
    CONFIG_FILE="/opt/docker/vaultwarden/compose/vaultwarden.env" > "$CONFIG_FILE"  # 清空文件内容

    echo "# log文件设置" >> "$CONFIG_FILE"
    echo "LOG_FILE=/log/vaultwarden.log" >> "$CONFIG_FILE"
    echo "LOG_LEVEL=warn" >> "$CONFIG_FILE"
    echo "EXTENDED_LOGGING=true" >> "$CONFIG_FILE"
    echo >> "$CONFIG_FILE"  # 空行

    echo "# 取消密码提示" >> "$CONFIG_FILE"
    echo "SHOW_PASSWORD_HINT=false" >> "$CONFIG_FILE"
    echo >> "$CONFIG_FILE"  # 空行

    echo "初次创建最好开启注册再关闭注册!!!!"
    read -p "是否开启注册(关闭注册默认打开邀请)?(Y/n): " SIGNUPS_ALLOWED
    SIGNUPS_ALLOWED=${SIGNUPS_ALLOWED:-y}
    if [[ "$SIGNUPS_ALLOWED" =~ ^[Yy]$ ]]; then
        echo "# 注册&邀请设置" >> "$CONFIG_FILE"
        echo "SIGNUPS_ALLOWED=true" >> "$CONFIG_FILE"
        echo "INVITATIONS_ALLOWED=false" >> "$CONFIG_FILE"
        echo >> "$CONFIG_FILE"  # 空行
    fi

    echo "# Admin面板设置" >> "$CONFIG_FILE"
    TOKEN=$(openssl rand -base64 48) # 生成一个随机的48位字符串
    echo "DISABLE_ADMIN_TOKEN=false" >> "$CONFIG_FILE"
    echo "ADMIN_TOKEN=${TOKEN}" >> "$CONFIG_FILE" 
    echo >> "$CONFIG_FILE"  # 空行
    
    echo "# 域名设置" >> "$CONFIG_FILE"
    read -p "请输入域名: " DOMAIN
    echo "DOMAIN=$DOMAIN" >> "$CONFIG_FILE"
    echo >> "$CONFIG_FILE"  # 空行

    echo "# 时区设置" >> "$CONFIG_FILE"
    read -p "请输入时区(默认:Asia/Shanghai): " TZ
    TZ=${TZ:-Asia/Shanghai} # 如果用户未输入时区,则默认为 Asia/Shanghai
    echo "TZ=$TZ" >> "$CONFIG_FILE" 
    echo >> "$CONFIG_FILE"  # 空行

    # 询问是否开启WebSocket
    read -p "是否开启WebSocket?(Y/n): " WEBSOCKET_ENABLED
    WEBSOCKET_ENABLED=${WEBSOCKET_ENABLED:-y}
    if [[ "$WEBSOCKET_ENABLED" =~ ^[Yy]$ ]]; then
        echo "# WebSocket设置" >> "$CONFIG_FILE"
        echo "WEBSOCKET_ENABLED=true" >> "$CONFIG_FILE"
        echo >> "$CONFIG_FILE"  # 空行
    fi

    # 询问是否使用 MySQL数据库
    read -p "是否使用 MySQL?(y/N): " USE_MYSQL
    USE_MYSQL=${USE_MYSQL:-n}
    if [[ "$USE_MYSQL" =~ ^[Yy]$ ]]; then
        # 如果用户选择使用 MySQL，则设置 MySQL 相关配置
        read -p "请输入 MySQL 用户名: " MYSQL_USER
        read -p "请输入 MySQL 密码: " MYSQL_PASSWORD
        read -p "请输入 MySQL 主机: " MYSQL_HOST
        read -p "请输入 MySQL 端口: " MYSQL_PORT
        read -p "请输入 MySQL 数据库名: " MYSQL_DATABASE
        echo "# 数据库设置" >> "$CONFIG_FILE"
        echo "DATABASE_URL=mysql://${MYSQL_USER}:${MYSQL_PASSWORD}@${MYSQL_HOST}:${MYSQL_PORT}/${MYSQL_DATABASE}" >> "$CONFIG_FILE"
        echo >> "$CONFIG_FILE"  # 空行
    fi

    # 询问是否开启SMTP
    read -p "是否开启SMTP?(y/N): " USE_SMTP
    USE_SMTP=${USE_SMTP:-n}
    if [[ "$USE_SMTP" =~ ^[Yy]$ ]]; then
        read -p "请输入SMTP主机: " SMTP_HOST
        read -p "请输入SMTP端口: " SMTP_PORT
        read -p "请输入SMTP安全性: " SMTP_SECURITY
        read -p "请输入SMTP用户名: " SMTP_USERNAME
        read -p "请输入SMTP密码: " SMTP_PASSWORD
        read -p "请输入SMTP发件人: " SMTP_FROM
        read -p "请输入SMTP认证机制: " SMTP_AUTH_MECHANISM
        echo "# SMTP设置" >> "$CONFIG_FILE"
        echo "SMTP_HOST=$SMTP_HOST" >> "$CONFIG_FILE"
        echo "SMTP_PORT=$SMTP_PORT" >> "$CONFIG_FILE"
        echo "SMTP_SECURITY=$SMTP_SECURITY" >> "$CONFIG_FILE"
        echo "SMTP_USERNAME=$SMTP_USERNAME" >> "$CONFIG_FILE"
        echo "SMTP_PASSWORD=$SMTP_PASSWORD" >> "$CONFIG_FILE"
        echo "SMTP_FROM=$SMTP_FROM" >> "$CONFIG_FILE"
        echo "SMTP_AUTH_MECHANISM=$SMTP_AUTH_MECHANISM" >> "$CONFIG_FILE"
        echo >> "$CONFIG_FILE"  # 空行
    fi

    # 询问是否开启PUSH
    read -p "是否开启推送?(y/N): " USE_PUSH
    USE_PUSH=${USE_PUSH:-n}
    if [[ "$USE_PUSH" =~ ^[Yy]$ ]]; then
        read -p "请输入推送ID: " PUSH_ID
        read -p "请输入推送KEY: " PUSH_KEY
        echo "# 推送设置" >> "$CONFIG_FILE"
        echo "PUSH_ENABLED=true" >> "$CONFIG_FILE"
        echo "PUSH_INSTALLATION_ID=$PUSH_ID" >> "$CONFIG_FILE"
        echo "PUSH_INSTALLATION_KEY=$PUSH_KEY" >> "$CONFIG_FILE"
        echo >> "$CONFIG_FILE"  # 空行
    fi

    # -O 参数指定下载文件的保存路径
    wget -O /opt/docker/vaultwarden/compose/compose.yml https://raw.githubusercontent.com/Sm1rkBoy/DockerShell/main/compose/vaultwarden/compose.yml

    # 启动 Docker Compose
    docker compose -f /opt/docker/vaultwarden/compose/compose.yml up -d

    if [ $? -eq 0 ]; then
        echo "vaultwarden 安装成功！"
    else
        echo "vaultwarden 安装失败！"
    fi
    echo "Admin面板的token存储在/opt/docker/vaultwarden/compose/vaultwarden.env文件中"
    echo "Admin面板的token存储在/opt/docker/vaultwarden/compose/vaultwarden.env文件中"
    echo "Admin面板的token存储在/opt/docker/vaultwarden/compose/vaultwarden.env文件中"
}