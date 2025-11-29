#!/bin/bash

# ========================================
# DockerShell - Docker容器管理工具
# 版本: 2.0
# 作者: Sm1rkBoy
# ========================================

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# 配置变量
GITHUB_SCRIPTS_BASE="https://raw.githubusercontent.com/Sm1rkBoy/DockerShell/main/scripts"
DOCKER_DATA_DIR="/opt/docker"
NETWORK_NAME="universal"

# 支持的容器列表
declare -A CONTAINERS=(
    ["mysql"]="MySQL 数据库"
    ["postgresql"]="PostgreSQL 数据库"
    ["redis"]="Redis 缓存"
    ["nginx"]="Nginx 反向代理"
    ["watchtower"]="Watchtower 自动更新"
    ["phpmyadmin"]="phpMyAdmin 管理工具"
    ["vaultwarden"]="Vaultwarden 密码管理"
    ["grafana"]="Grafana 监控面板"
    ["prometheus"]="Prometheus 监控系统"
    ["victoriametrics"]="VictoriaMetrics 时序数据库"
)

# ========================================
# 工具函数
# ========================================

# 打印带颜色的消息
print_color() {
    local color=$1
    shift
    echo -e "${color}$@${NC}"
}

# 打印标题
print_header() {
    clear
    echo -e "${CYAN}"
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║                    DockerShell v2.0                            ║"
    echo "║                   Docker 容器管理工具                            ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# 打印成功消息
print_success() {
    print_color $GREEN "✓ $1"
}

# 打印错误消息
print_error() {
    print_color $RED "✗ $1"
}

# 打印警告消息
print_warning() {
    print_color $YELLOW "⚠ $1"
}

# 打印信息消息
print_info() {
    print_color $BLUE "ℹ $1"
}

# 检查命令是否存在
command_exists() {
    command -v "$1" &> /dev/null
}

# ========================================
# Docker 检查和初始化
# ========================================

# 检查 Docker 是否安装
check_docker() {
    print_info "检查 Docker 环境..."

    if ! command_exists docker; then
        print_error "Docker 未安装"
        echo ""
        print_info "请先安装 Docker："
        echo "  curl -fsSL https://get.docker.com | sh"
        exit 1
    fi

    # 检查 Docker 服务是否运行
    if ! docker info &> /dev/null; then
        print_error "Docker 服务未运行"
        echo ""
        print_info "请启动 Docker 服务："
        echo "  systemctl start docker"
        exit 1
    fi

    print_success "Docker 环境检查通过"
}

# 检查并创建 Docker 网络
check_docker_network() {
    print_info "检查 Docker 网络..."

    if docker network inspect "$NETWORK_NAME" &> /dev/null; then
        print_success "网络 $NETWORK_NAME 已存在"
    else
        print_info "创建网络 $NETWORK_NAME..."
        if docker network create "$NETWORK_NAME" &> /dev/null; then
            print_success "网络创建成功"
        else
            print_error "网络创建失败"
            exit 1
        fi
    fi
}

# 检查并创建数据目录
check_data_directory() {
    print_info "检查数据目录..."

    if [ ! -d "$DOCKER_DATA_DIR" ]; then
        mkdir -p "$DOCKER_DATA_DIR"
        print_success "数据目录已创建: $DOCKER_DATA_DIR"
    else
        print_success "数据目录已存在: $DOCKER_DATA_DIR"
    fi
}

# 初始化环境
init_environment() {
    print_header
    echo ""
    check_docker
    check_docker_network
    check_data_directory
    echo ""
    print_success "环境初始化完成"
    echo ""
    sleep 1
}

# ========================================
# 容器管理函数
# ========================================

# 获取容器状态
get_container_status() {
    local container=$1

    if docker ps -a --format '{{.Names}}' | grep -q "^${container}$"; then
        local status=$(docker inspect --format='{{.State.Status}}' "$container" 2>/dev/null)
        case $status in
            running)
                echo -e "${GREEN}●${NC} 运行中"
                ;;
            exited)
                echo -e "${RED}●${NC} 已停止"
                ;;
            paused)
                echo -e "${YELLOW}●${NC} 已暂停"
                ;;
            *)
                echo -e "${YELLOW}●${NC} $status"
                ;;
        esac
    else
        echo -e "${WHITE}○${NC} 未安装"
    fi
}

# 检查容器是否存在
container_exists() {
    docker ps -a --format '{{.Names}}' | grep -q "^$1$"
}

# 检查容器是否运行
container_running() {
    local status=$(docker inspect --format='{{.State.Status}}' "$1" 2>/dev/null)
    [ "$status" = "running" ]
}

# 下载并执行安装脚本
install_container() {
    local container=$1
    local script_url="$GITHUB_SCRIPTS_BASE/$container.sh"

    print_info "正在下载 $container 安装脚本..."

    # 检查脚本是否存在
    if ! curl -s --head "$script_url" | grep -q "HTTP/.*200"; then
        print_error "安装脚本不存在: $script_url"
        return 1
    fi

    # 下载并执行脚本
    print_info "正在安装 $container..."
    echo ""
    if source <(curl -s "$script_url"); then
        local install_function="install_$container"
        if declare -f "$install_function" > /dev/null; then
            $install_function
            local result=$?
            echo ""
            if [ $result -eq 0 ]; then
                print_success "$container 安装成功"
                return 0
            else
                print_error "$container 安装失败"
                return 1
            fi
        else
            print_error "安装函数 $install_function 未找到"
            return 1
        fi
    else
        print_error "脚本下载失败"
        return 1
    fi
}

# 启动容器
start_container() {
    local container=$1

    if ! container_exists "$container"; then
        print_error "容器 $container 不存在，请先安装"
        return 1
    fi

    if container_running "$container"; then
        print_warning "容器 $container 已在运行"
        return 0
    fi

    print_info "正在启动 $container..."
    if docker start "$container" &> /dev/null; then
        print_success "$container 启动成功"
        return 0
    else
        print_error "$container 启动失败"
        return 1
    fi
}

# 停止容器
stop_container() {
    local container=$1

    if ! container_exists "$container"; then
        print_error "容器 $container 不存在"
        return 1
    fi

    if ! container_running "$container"; then
        print_warning "容器 $container 未运行"
        return 0
    fi

    print_info "正在停止 $container..."
    if docker stop "$container" &> /dev/null; then
        print_success "$container 停止成功"
        return 0
    else
        print_error "$container 停止失败"
        return 1
    fi
}

# 重启容器
restart_container() {
    local container=$1

    if ! container_exists "$container"; then
        print_error "容器 $container 不存在"
        return 1
    fi

    print_info "正在重启 $container..."
    if docker restart "$container" &> /dev/null; then
        print_success "$container 重启成功"
        return 0
    else
        print_error "$container 重启失败"
        return 1
    fi
}

# 删除容器
remove_container() {
    local container=$1

    if ! container_exists "$container"; then
        print_warning "容器 $container 不存在"
        return 0
    fi

    # 确认删除
    echo ""
    print_warning "确定要删除容器 $container 吗？"
    print_warning "这将删除容器但保留数据目录"
    read -p "输入 'yes' 确认删除: " confirm

    if [ "$confirm" != "yes" ]; then
        print_info "取消删除"
        return 1
    fi

    # 强制停止容器（即使在 restarting 状态）
    print_info "正在停止 $container..."
    docker stop -t 5 "$container" &> /dev/null || docker kill "$container" &> /dev/null || true

    # 强制删除容器
    print_info "正在删除 $container..."
    if docker rm -f "$container" &> /dev/null; then
        print_success "$container 删除成功"

        # 询问是否删除数据
        echo ""
        print_warning "是否同时删除数据目录 $DOCKER_DATA_DIR/$container ?"
        read -p "输入 'yes' 确认删除数据: " confirm_data

        if [ "$confirm_data" = "yes" ]; then
            rm -rf "$DOCKER_DATA_DIR/$container"
            print_success "数据目录已删除"
        fi

        return 0
    else
        print_error "$container 删除失败"
        return 1
    fi
}

# 查看容器日志
view_logs() {
    local container=$1

    if ! container_exists "$container"; then
        print_error "容器 $container 不存在"
        return 1
    fi

    clear
    print_header
    print_info "容器 $container 日志 (按 Ctrl+C 退出)"
    echo ""
    docker logs -f --tail=100 "$container"
}

# 查看容器详情
view_container_info() {
    local container=$1

    if ! container_exists "$container"; then
        print_error "容器 $container 不存在"
        read -p "按回车键继续..."
        return 1
    fi

    clear
    print_header
    echo -e "${CYAN}容器名称:${NC} $container"
    echo -e "${CYAN}容器状态:${NC} $(get_container_status $container)"
    echo ""

    # 获取容器信息
    local info=$(docker inspect "$container" 2>/dev/null)

    # 显示基本信息
    echo -e "${YELLOW}=== 基本信息 ===${NC}"
    echo -e "镜像: $(echo "$info" | grep -m1 '"Image"' | awk -F'"' '{print $4}')"
    echo -e "创建时间: $(docker inspect --format='{{.Created}}' "$container" 2>/dev/null)"
    echo ""

    # 显示端口映射
    echo -e "${YELLOW}=== 端口映射 ===${NC}"
    docker port "$container" 2>/dev/null || echo "无端口映射"
    echo ""

    # 显示挂载卷
    echo -e "${YELLOW}=== 数据卷 ===${NC}"
    docker inspect --format='{{range .Mounts}}{{.Source}} -> {{.Destination}}{{"\n"}}{{end}}' "$container" 2>/dev/null
    echo ""

    # 显示网络
    echo -e "${YELLOW}=== 网络 ===${NC}"
    docker inspect --format='{{range $k, $v := .NetworkSettings.Networks}}{{$k}}{{"\n"}}{{end}}' "$container" 2>/dev/null
    echo ""

    # 显示资源使用
    echo -e "${YELLOW}=== 资源使用 ===${NC}"
    docker stats --no-stream "$container" 2>/dev/null
    echo ""

    read -p "按回车键继续..."
}

# ========================================
# 菜单系统
# ========================================

# 显示容器列表菜单
show_container_list() {
    print_header
    echo -e "${YELLOW}当前容器状态:${NC}"
    echo ""

    local index=1
    printf "%-5s %-20s %-30s %-15s\n" "序号" "容器名称" "描述" "状态"
    echo "────────────────────────────────────────────────────────────────────"

    for container in $(echo "${!CONTAINERS[@]}" | tr ' ' '\n' | sort); do
        local desc="${CONTAINERS[$container]}"
        local status=$(get_container_status "$container")
        printf "%-5s %-20s %-30s %-15s\n" "$index" "$container" "$desc" "$status"
        ((index++))
    done

    echo ""
}

# 主菜单
main_menu() {
    while true; do
        show_container_list

        echo -e "${CYAN}请选择操作:${NC}"
        echo "  1) 安装容器"
        echo "  2) 管理容器 (启动/停止/重启/删除)"
        echo "  3) 查看容器信息"
        echo "  4) 查看容器日志"
        echo "  5) 系统管理"
        echo "  0) 退出"
        echo ""

        read -p "请输入选项 [0-5]: " choice

        case $choice in
            1) install_menu ;;
            2) manage_menu ;;
            3) info_menu ;;
            4) logs_menu ;;
            5) system_menu ;;
            0)
                print_info "退出程序"
                exit 0
                ;;
            *)
                print_error "无效选项"
                sleep 1
                ;;
        esac
    done
}

# 安装菜单
install_menu() {
    while true; do
        show_container_list

        echo -e "${CYAN}请选择要安装的容器:${NC}"
        echo "  (输入容器名称，如: mysql, 或输入 'back' 返回)"
        echo ""

        read -p "容器名称: " container

        if [ "$container" = "back" ]; then
            return
        fi

        if [ -z "$container" ]; then
            print_error "请输入容器名称"
            sleep 1
            continue
        fi

        if [ -z "${CONTAINERS[$container]}" ]; then
            print_error "不支持的容器: $container"
            sleep 2
            continue
        fi

        if container_exists "$container"; then
            print_warning "容器 $container 已安装"
            sleep 2
            continue
        fi

        echo ""
        install_container "$container"
        echo ""
        read -p "按回车键继续..."
    done
}

# 管理菜单
manage_menu() {
    while true; do
        show_container_list

        echo -e "${CYAN}容器管理:${NC}"
        echo "  (输入容器名称，如: mysql, 或输入 'back' 返回)"
        echo ""

        read -p "容器名称: " container

        if [ "$container" = "back" ]; then
            return
        fi

        if [ -z "$container" ]; then
            print_error "请输入容器名称"
            sleep 1
            continue
        fi

        if [ -z "${CONTAINERS[$container]}" ]; then
            print_error "不支持的容器: $container"
            sleep 2
            continue
        fi

        if ! container_exists "$container"; then
            print_warning "容器 $container 未安装"
            sleep 2
            continue
        fi

        # 显示操作菜单
        while true; do
            clear
            print_header
            echo -e "${YELLOW}容器:${NC} $container"
            echo -e "${YELLOW}状态:${NC} $(get_container_status $container)"
            echo ""
            echo -e "${CYAN}请选择操作:${NC}"
            echo "  1) 启动"
            echo "  2) 停止"
            echo "  3) 重启"
            echo "  4) 删除"
            echo "  0) 返回"
            echo ""

            read -p "请输入选项 [0-4]: " action

            case $action in
                1)
                    echo ""
                    start_container "$container"
                    echo ""
                    read -p "按回车键继续..."
                    ;;
                2)
                    echo ""
                    stop_container "$container"
                    echo ""
                    read -p "按回车键继续..."
                    ;;
                3)
                    echo ""
                    restart_container "$container"
                    echo ""
                    read -p "按回车键继续..."
                    ;;
                4)
                    echo ""
                    remove_container "$container"
                    echo ""
                    read -p "按回车键继续..."
                    break
                    ;;
                0)
                    break
                    ;;
                *)
                    print_error "无效选项"
                    sleep 1
                    ;;
            esac
        done
    done
}

# 信息查看菜单
info_menu() {
    while true; do
        show_container_list

        echo -e "${CYAN}查看容器信息:${NC}"
        echo "  (输入容器名称，如: mysql, 或输入 'back' 返回)"
        echo ""

        read -p "容器名称: " container

        if [ "$container" = "back" ]; then
            return
        fi

        if [ -z "$container" ]; then
            print_error "请输入容器名称"
            sleep 1
            continue
        fi

        if [ -z "${CONTAINERS[$container]}" ]; then
            print_error "不支持的容器: $container"
            sleep 2
            continue
        fi

        view_container_info "$container"
    done
}

# 日志查看菜单
logs_menu() {
    while true; do
        show_container_list

        echo -e "${CYAN}查看容器日志:${NC}"
        echo "  (输入容器名称，如: mysql, 或输入 'back' 返回)"
        echo ""

        read -p "容器名称: " container

        if [ "$container" = "back" ]; then
            return
        fi

        if [ -z "$container" ]; then
            print_error "请输入容器名称"
            sleep 1
            continue
        fi

        if [ -z "${CONTAINERS[$container]}" ]; then
            print_error "不支持的容器: $container"
            sleep 2
            continue
        fi

        view_logs "$container"
    done
}

# 系统管理菜单
system_menu() {
    while true; do
        clear
        print_header

        echo -e "${CYAN}系统管理:${NC}"
        echo "  1) 查看 Docker 信息"
        echo "  2) 清理未使用的容器和镜像"
        echo "  3) 备份所有容器数据"
        echo "  4) 查看数据目录大小"
        echo "  0) 返回"
        echo ""

        read -p "请输入选项 [0-4]: " choice

        case $choice in
            1)
                clear
                print_header
                docker info
                echo ""
                docker ps -a
                echo ""
                read -p "按回车键继续..."
                ;;
            2)
                echo ""
                print_warning "这将清理所有未使用的容器、镜像、网络和卷"
                read -p "输入 'yes' 确认: " confirm
                if [ "$confirm" = "yes" ]; then
                    print_info "正在清理..."
                    docker system prune -a -f
                    docker volume prune -f
                    print_success "清理完成"
                fi
                echo ""
                read -p "按回车键继续..."
                ;;
            3)
                echo ""
                print_info "正在备份数据..."
                local backup_file="/tmp/docker_backup_$(date +%Y%m%d_%H%M%S).tar.gz"
                if tar -czf "$backup_file" -C "$DOCKER_DATA_DIR" . 2>/dev/null; then
                    print_success "备份完成: $backup_file"
                else
                    print_error "备份失败"
                fi
                echo ""
                read -p "按回车键继续..."
                ;;
            4)
                clear
                print_header
                echo -e "${YELLOW}数据目录大小:${NC}"
                echo ""
                du -sh "$DOCKER_DATA_DIR"/* 2>/dev/null | sort -h
                echo ""
                echo -e "${YELLOW}总计:${NC}"
                du -sh "$DOCKER_DATA_DIR"
                echo ""
                read -p "按回车键继续..."
                ;;
            0)
                return
                ;;
            *)
                print_error "无效选项"
                sleep 1
                ;;
        esac
    done
}

# ========================================
# 命令行参数处理
# ========================================

# 显示帮助信息
show_help() {
    echo -e "${CYAN}DockerShell v2.0 - Docker 容器管理工具${NC}"
    echo ""
    echo "用法:"
    echo "  $0                                    # 交互式菜单"
    echo "  $0 <操作> <容器名1> [容器名2] ...      # 命令行模式（支持批量）"
    echo ""
    echo "支持的容器:"
    for container in $(echo "${!CONTAINERS[@]}" | tr ' ' '\n' | sort); do
        printf "  %-20s %s\n" "$container" "${CONTAINERS[$container]}"
    done
    echo ""
    echo "支持的操作:"
    echo "  install                     # 安装容器"
    echo "  remove                      # 删除容器"
    echo "  start                       # 启动容器"
    echo "  stop                        # 停止容器"
    echo "  restart                     # 重启容器"
    echo "  logs                        # 查看日志（仅单个容器）"
    echo "  info                        # 查看详情（仅单个容器）"
    echo "  status                      # 查看状态"
    echo ""
    echo "示例:"
    echo "  $0 install mysql                      # 安装 MySQL"
    echo "  $0 start mysql redis nginx            # 批量启动多个容器"
    echo "  $0 stop mysql redis                   # 批量停止多个容器"
    echo "  $0 restart mysql                      # 重启 MySQL"
    echo "  $0 status mysql redis postgresql      # 批量查看状态"
    echo "  $0 logs mysql                         # 查看 MySQL 日志"
    echo ""
}

# 命令行模式处理（支持批量操作）
handle_command_line() {
    local action=$1
    shift
    local containers=("$@")

    # 检查操作是否需要单个容器
    local single_only_actions="logs info"
    if [[ " $single_only_actions " =~ " $action " ]] && [ ${#containers[@]} -gt 1 ]; then
        print_error "操作 '$action' 仅支持单个容器"
        exit 1
    fi

    # 验证所有容器名
    for container in "${containers[@]}"; do
        if [ -z "${CONTAINERS[$container]}" ]; then
            print_error "不支持的容器: $container"
            echo ""
            echo "支持的容器列表:"
            for c in $(echo "${!CONTAINERS[@]}" | tr ' ' '\n' | sort); do
                echo "  - $c"
            done
            exit 1
        fi
    done

    # 执行操作（批量处理）
    local exit_code=0
    case $action in
        install)
            for container in "${containers[@]}"; do
                echo -e "${CYAN}>>> 正在处理: $container${NC}"
                if container_exists "$container"; then
                    print_warning "容器 $container 已安装"
                    continue
                fi
                install_container "$container"
                [ $? -ne 0 ] && exit_code=1
                echo ""
            done
            exit $exit_code
            ;;
        remove)
            for container in "${containers[@]}"; do
                echo -e "${CYAN}>>> 正在处理: $container${NC}"
                remove_container "$container"
                [ $? -ne 0 ] && exit_code=1
                echo ""
            done
            exit $exit_code
            ;;
        start)
            for container in "${containers[@]}"; do
                echo -e "${CYAN}>>> 正在处理: $container${NC}"
                start_container "$container"
                [ $? -ne 0 ] && exit_code=1
                echo ""
            done
            exit $exit_code
            ;;
        stop)
            for container in "${containers[@]}"; do
                echo -e "${CYAN}>>> 正在处理: $container${NC}"
                stop_container "$container"
                [ $? -ne 0 ] && exit_code=1
                echo ""
            done
            exit $exit_code
            ;;
        restart)
            for container in "${containers[@]}"; do
                echo -e "${CYAN}>>> 正在处理: $container${NC}"
                restart_container "$container"
                [ $? -ne 0 ] && exit_code=1
                echo ""
            done
            exit $exit_code
            ;;
        logs)
            view_logs "${containers[0]}"
            exit $?
            ;;
        info)
            view_container_info "${containers[0]}"
            exit 0
            ;;
        status)
            for container in "${containers[@]}"; do
                if ! container_exists "$container"; then
                    print_error "容器 $container 不存在"
                    exit_code=1
                else
                    echo -e "容器: ${CYAN}$container${NC}"
                    echo -e "状态: $(get_container_status $container)"
                fi
                echo ""
            done
            exit $exit_code
            ;;
        *)
            print_error "不支持的操作: $action"
            echo ""
            echo "支持的操作: install, remove, start, stop, restart, logs, info, status"
            exit 1
            ;;
    esac
}

# ========================================
# 主程序入口
# ========================================

# 检查是否为 root 用户
if [ "$EUID" -ne 0 ]; then
    print_error "请使用 root 用户运行此脚本"
    exit 1
fi

# 初始化环境
init_environment

# 处理命令行参数
if [ $# -eq 0 ]; then
    # 无参数，显示交互式菜单
    main_menu
elif [ $# -eq 1 ] && [ "$1" = "help" -o "$1" = "-h" -o "$1" = "--help" ]; then
    # 显示帮助
    show_help
elif [ $# -ge 2 ]; then
    # 命令行模式（支持批量操作）
    handle_command_line "$@"
else
    print_error "参数错误"
    echo ""
    show_help
    exit 1
fi
