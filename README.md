# DockerShell

## 是什么?

基于 `compose.yml` 的Docker容器一键启动的纯shell脚本,类似于`1panel商店`,只需输入数字勾选容器即可安装.

## 快速开始
如果你的设备有 Docker 环境,使用`root`用户运行如下的命令从而使用脚本

```bash
bash <(curl -sSL https://raw.githubusercontent.com/Sm1rkBoy/DockerShell/main/start.sh)
```

## 备份or卸载
容器的各类数据均保存在`/opt/docker`目录中,对应关系如下所示

- `/opt/docker/apps` 容器的数据保存目录
- `/opt/docker/log` 容器的日志保存目录
- `/opt/docker/compose` 容器的启动`compose.yml`保存目录
- `/opt/docker/config` 容器启动所需的额外配置文件保存目录
- `/opt/docker/backup` 容器备份目录,**目前暂未启用**
- `etc`

目前脚本暂未提供卸载,预计在未来实现卸载功能,如果想要实现卸载功能可以参考如下命令

```bash
# 卸载mysql容器
docker rm -f mysql

# 危险操作!!!!!!
# 删除mysql容器的数据
rm -rf /opt/docker/{apps,log,compose,config}/mysql

# 卸载全部容器
docker rm -f $(docker ps -aq)

# 删除所有文件
rm -rf /opt/docker

# 清除docker残留
docker system prune -a -f
docker volume prune -a -f
```

## 致谢

特别感谢 [YxVM](https://yxvm.com) 提供的免费服务器支持！

![YxVM Logo](https://yxvm.com/assets/img/logo.png)

## 许可证

[![license](https://img.shields.io/github/license/Sm1rkBoy/DockerShell.svg?style=flat-square)](https://github.com/Sm1rkBoy/DockerShell/main/LICENSE)

DockerShell 使用 MIT 协议开源,请遵守开源协议!

## Star History

[![Star History Chart](https://api.star-history.com/svg?repos=Sm1rkBoy/DockerShell&type=Timeline)](https://star-history.com/#Sm1rkBoy/DockerShell&Timeline)