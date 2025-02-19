#!/bin/bash

install_victoriametrics() {
    # 创建目录
    mkdir -p /opt/docker/victoriametrics/{apps,config,compose,log}

    # 读取用户名和密码
    read -p "请输入 VictoriaMetrics 的用户名: " VM_USERNAME
    read -sp "请输入 VictoriaMetrics 的密码: " VM_PASSWORD
    echo "" # 换行

    # 检查输入是否为空
    if [[ -z "$VM_USERNAME" || -z "$VM_PASSWORD" ]]; then
        echo "错误：用户名和密码不能为空！"
        exit 1
    fi

    # 安装临时的victoriametrics容器
    echo "启动临时 Victoriametrics 容器..."
    docker run -d --name victoriametrics -p 8428:8428 victoriametrics/victoria-metrics:v1.109.0 --storageDataPath=/storage 

    # 等待 Victoriametrics 健康
    echo "等待 Victoriametrics 完全启动..."
    while true; do
        if curl -s -o /dev/null -w "%{http_code}" http://localhost:8428/-/healthy | grep -q "200"; then
            echo "Victoriametrics 完全启动,进行下一步"
            break
        else
            echo "等待 Victoriametrics 完全启动中..."
            sleep 2
        fi
    done

    # 拷贝容器内的文件到本地
    docker cp victoriametrics:/storage/. /opt/docker/victoriametrics/apps

    # 删除临时容器
    docker rm -f victoriametrics
    docker volume prune -a -f

    # -O 参数指定下载文件的保存路径
    wget -O /opt/docker/victoriametrics/compose/compose.yml https://raw.githubusercontent.com/Sm1rkBoy/DockerShell/main/compose/victoriametrics/compose.yml

    # 使用 sed 替换占位符
    sed -i -e "s/__USERNAME__/${VM_USERNAME}/g" -e "s/__PASSWORD__/${VM_PASSWORD}/g" "/opt/docker/victoriametrics/compose/compose.yml"
    
    # 启动 Docker Compose
    docker compose -f /opt/docker/victoriametrics/compose/compose.yml up -d

    if [ $? -eq 0 ]; then
        echo "Victoriametrics 安装成功！"
    else
        echo "Victoriametrics 安装失败！"
    fi
}