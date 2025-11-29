# DockerShell v2.0

<div align="center">

![License](https://img.shields.io/github/license/Sm1rkBoy/DockerShell.svg?style=flat-square)
![Shell](https://img.shields.io/badge/Shell-Bash-green.svg?style=flat-square)
![Docker](https://img.shields.io/badge/Docker-Compose-blue.svg?style=flat-square)

一个功能强大、界面美观的 Docker 容器管理工具

</div>

## 📖 项目简介

DockerShell 是一个基于 **纯 Shell 脚本** 的 Docker 容器一键安装和管理工具，类似于 1Panel 商店，但更加轻量和灵活。

### ✨ 主要特性

- **🎨 美观的 TUI 界面** - 使用彩色输出和表格布局，提供清晰的视觉体验
- **🚀 一键安装** - 支持多种常用服务的快速部署
- **🔧 完整的容器管理** - 启动、停止、重启、删除容器
- **📦 批量操作** - 支持命令行批量管理多个容器
- **📊 实时监控** - 查看容器状态、日志和资源使用情况
- **💾 数据备份** - 内置备份和恢复功能
- **🔐 安全配置** - 自动生成安全密码，配置文件分离
- **📝 详细文档** - 每个容器安装后都有完整的使用说明

## 🎯 支持的容器

| 容器 | 描述 | 默认端口 |
|------|------|----------|
| MySQL | MySQL 数据库 | 3306 |
| PostgreSQL | PostgreSQL 数据库 | 5432 |
| Redis | Redis 缓存 | 6379 |
| Nginx | Nginx 反向代理 | 80/443 |
| Watchtower | 容器自动更新 | - |
| phpMyAdmin | MySQL 管理工具 | 8080 |
| Vaultwarden | 密码管理器 | 8000 |
| Grafana | 监控面板 | 3000 |
| Prometheus | 监控系统 | 9090 |
| VictoriaMetrics | 时序数据库 | 8428 |

## 🚀 快速开始

### 前置要求

- Linux 操作系统
- Docker 和 Docker Compose 已安装
- Root 用户权限

### 一键运行

```bash
bash <(curl -sSL https://raw.githubusercontent.com/Sm1rkBoy/DockerShell/main/start.sh)
```

或者下载到本地运行：

```bash
# 下载脚本
wget https://raw.githubusercontent.com/Sm1rkBoy/DockerShell/main/start.sh

# 添加执行权限
chmod +x start.sh

# 运行脚本
./start.sh
```

## 📚 使用说明

### 交互式模式

运行脚本（不带参数）后，你会看到一个美观的交互式主菜单：

```
╔════════════════════════════════════════════════════════════════╗
║                    DockerShell v2.0                           ║
║                  Docker 容器管理工具                           ║
╚════════════════════════════════════════════════════════════════╝

当前容器状态:

序号  容器名称              描述                           状态
────────────────────────────────────────────────────────────────────
1     mysql                MySQL 数据库                   ● 运行中
2     nginx                Nginx 反向代理                 ○ 未安装
3     redis                Redis 缓存                     ● 运行中
...

请选择操作:
  1) 安装容器
  2) 管理容器 (启动/停止/重启/删除)
  3) 查看容器信息
  4) 查看容器日志
  5) 系统管理
  0) 退出
```

### 命令行模式（批量操作）

支持通过命令行参数直接操作容器，**可以批量处理多个容器**：

```bash
# 基本用法
./start.sh <操作> <容器名1> [容器名2] [容器名3] ...

# 批量启动多个容器
./start.sh start mysql redis nginx

# 批量停止多个容器
./start.sh stop mysql redis

# 批量重启容器
./start.sh restart mysql nginx

# 批量查看状态
./start.sh status mysql redis postgresql

# 批量安装容器
./start.sh install mysql redis

# 单个容器操作
./start.sh install mysql
./start.sh logs mysql
./start.sh info nginx
```

**支持的操作：**
- `install` - 安装容器（支持批量）
- `start` - 启动容器（支持批量）
- `stop` - 停止容器（支持批量）
- `restart` - 重启容器（支持批量）
- `remove` - 删除容器（支持批量）
- `status` - 查看状态（支持批量）
- `logs` - 查看日志（仅单个）
- `info` - 查看详情（仅单个）

### 交互式模式功能说明

#### 1. 安装容器

- 输入容器名称（如 `mysql`、`redis`）
- 根据提示配置参数（端口、密码等）
- 系统自动创建配置文件和数据目录
- 自动启动容器并验证运行状态

#### 2. 管理容器

- **启动**：启动已安装但未运行的容器
- **停止**：停止正在运行的容器
- **重启**：重启容器
- **删除**：删除容器（可选择是否删除数据）

#### 3. 查看容器信息

显示容器的详细信息：
- 基本信息（镜像、创建时间）
- 端口映射
- 数据卷挂载
- 网络配置
- 资源使用情况

#### 4. 查看容器日志

实时查看容器日志输出（`Ctrl+C` 退出）

#### 5. 系统管理

- 查看 Docker 信息和所有容器
- 清理未使用的容器和镜像
- 备份所有容器数据
- 查看数据目录大小

## 📁 目录结构

所有容器数据保存在 `/opt/docker` 目录下：

```
/opt/docker/
├── compose/              # Docker Compose 配置文件
│   ├── mysql/
│   │   ├── compose.yml
│   │   └── mysql.env
│   ├── redis/
│   └── ...
├── mysql/                # MySQL 容器数据
│   ├── apps/            # 数据文件
│   ├── config/          # 配置文件
│   ├── log/             # 日志文件
│   ├── backup/          # 备份目录
│   └── README.txt       # 使用说明
├── redis/
└── ...
```

## 🔐 安全说明

- **密码管理**：所有密码都保存在对应容器的 `.env` 文件和 `README.txt` 中
- **自动生成**：如果不输入密码，系统会自动生成强密码
- **权限控制**：脚本需要 root 权限运行
- **网络隔离**：所有容器运行在独立的 `universal` 网络中

## 💾 备份与恢复

### 备份容器数据

```bash
# 使用系统管理菜单中的备份功能
# 或手动备份
tar -czf docker_backup.tar.gz /opt/docker
```

### 恢复容器数据

```bash
# 恢复备份
tar -xzf docker_backup.tar.gz -C /

# 重新启动容器
docker compose -f /opt/docker/compose/mysql/compose.yml up -d
```

## 🗑️ 卸载

### 删除单个容器

使用主菜单的"管理容器"功能，选择"删除"选项。

### 完全卸载

```bash
# 停止所有容器
docker stop $(docker ps -aq)

# 删除所有容器
docker rm $(docker ps -aq)

# 删除数据目录（危险操作！）
rm -rf /opt/docker

# 清理 Docker 系统
docker system prune -a -f
docker volume prune -f
```

## 🔧 自定义配置

### 修改容器配置

1. 编辑配置文件：`/opt/docker/<容器名>/config/`
2. 重启容器使配置生效：
   ```bash
   docker restart <容器名>
   ```

### 修改端口

1. 编辑环境文件：`/opt/docker/compose/<容器名>/<容器名>.env`
2. 重新创建容器：
   ```bash
   docker compose -f /opt/docker/compose/<容器名>/compose.yml up -d --force-recreate
   ```

## 📊 示例用法

### 交互式模式 - 安装 MySQL

```bash
# 运行主脚本
./start.sh

# 选择 1) 安装容器
# 输入容器名称: mysql
# 按提示输入密码和端口（或使用默认值）
# 等待安装完成

# 查看安装信息
cat /opt/docker/mysql/README.txt
```

### 命令行模式 - 批量操作示例

```bash
# 批量安装数据库组件
./start.sh install mysql redis postgresql

# 批量启动服务
./start.sh start mysql redis nginx

# 批量停止服务
./start.sh stop mysql redis

# 批量重启
./start.sh restart mysql nginx redis

# 批量查看状态
./start.sh status mysql redis nginx postgresql

# 查看单个容器日志
./start.sh logs mysql

# 查看单个容器详情
./start.sh info nginx
```

### 典型使用场景

#### 场景1：快速部署 Web 应用环境

```bash
# 一次性安装并启动所需服务
./start.sh install mysql redis nginx
```

#### 场景2：统一重启相关服务

```bash
# 重启所有数据库服务
./start.sh restart mysql postgresql redis
```

#### 场景3：批量查看服务状态

```bash
# 检查所有核心服务状态
./start.sh status mysql redis nginx
```

### 连接到 MySQL

```bash
# 使用客户端连接
mysql -h 127.0.0.1 -P 3306 -u root -p

# 或进入容器
docker exec -it mysql bash
mysql -u root -p
```

### 查看容器日志

```bash
# 使用主菜单的"查看容器日志"功能
# 或使用命令行
./start.sh logs mysql

# 或直接使用 Docker 命令
docker logs -f mysql
```

## 🛠️ 故障排除

### 容器无法启动

1. 查看容器日志：`docker logs <容器名>`
2. 检查端口是否被占用：`netstat -tulpn | grep <端口>`
3. 检查配置文件是否正确：`/opt/docker/<容器名>/config/`

### 端口冲突

1. 修改环境文件中的端口配置
2. 重新创建容器

### 权限问题

```bash
# 确保数据目录权限正确
chown -R root:root /opt/docker
chmod -R 755 /opt/docker
```

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

## 📄 许可证

本项目采用 MIT 许可证开源，请遵守开源协议。

详见 [LICENSE](LICENSE) 文件。

## 🌟 Star History

[![Star History Chart](https://api.star-history.com/svg?repos=Sm1rkBoy/DockerShell&type=Timeline)](https://star-history.com/#Sm1rkBoy/DockerShell&Timeline)

## 📮 联系方式

如有问题或建议，请通过 GitHub Issues 反馈。

---

<div align="center">

Made with ❤️ by Sm1rkBoy

</div>
