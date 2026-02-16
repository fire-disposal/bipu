# 远程服务器部署前准备

本文档说明如何在目标服务器上准备部署环境。

## 📋 前置条件

- Ubuntu/Debian Linux 系统
- Docker & Docker Compose 已安装
- 至少 50GB 可用磁盘空间
- SSH 可访问

## 🔧 初始化脚本

### 1. SSH 登录到远程服务器

```bash
ssh user@your-server-ip
```

### 2. 创建部署目录

```bash
# 创建部署目录
mkdir -p ~/bipupu-compose
mkdir -p ~/bipupu-backups

cd ~/bipupu-compose
```

### 3. 从仓库复制 Docker Compose 配置文件

**方式 A：从 GitHub 仓库复制（推荐）**

```bash
# 假设你有 git 访问权限
git clone https://github.com/your-org/your-repo.git
cp your-repo/backend/docker/docker-compose.yml ~/bipupu-compose/
cp your-repo/backend/docker/docker-compose.prod.yml ~/bipupu-compose/
```

**方式 B：手动创建**

```bash
# 或者从本地机器通过 scp 复制
# 在本地机器执行：
scp backend/docker/docker-compose.yml user@server:~/bipupu-compose/
scp backend/docker/docker-compose.prod.yml user@server:~/bipupu-compose/
```

### 4. 验证文件

```bash
cd ~/bipupu-compose
ls -la
# 应该看到：
# - docker-compose.yml
# - docker-compose.prod.yml
```

### 5. 测试 Docker 权限

```bash
# 检查 docker 命令是否可用
docker --version

# 检查 docker compose 命令
docker compose version

# 如果无权限，添加用户到 docker 组
sudo usermod -aG docker $USER
# 然后重新登录或运行：
newgrp docker
```

## 🏗️ 目录结构

部署后，远程服务器上的目录结构应该如下：

```
~/bipupu-compose/
├── docker-compose.yml              # 基础配置
├── docker-compose.prod.yml         # 生产环境覆盖
├── .env                            # 环境变量（由 CI/CD 自动生成）
└── .env.example                    # 示例（可选，用于参考）

~/bipupu-backups/
├── last-image.txt                  # 最后部署的镜像（用于回滚）
└── last-version.txt                # 最后部署的版本号

docker_volumes/
├── bipupu_pg_data/                 # PostgreSQL 数据
├── bipupu_redis_data/              # Redis 数据
├── bipupu_uploads/                 # 上传文件
└── bipupu_logs/                    # 应用日志
```

## 🔐 配置 Docker 登录凭证（可选）

如果使用私有镜像仓库，需要配置登录凭证：

```bash
# 方式 1：交互式登录
docker login ghcr.io
# 输入用户名和密码/Token

# 方式 2：直接指定（注意安全性）
echo "YOUR_GITHUB_TOKEN" | docker login ghcr.io -u YOUR_USERNAME --password-stdin
```

## 📝 创建 .env.example（可选参考文件）

在 `~/bipupu-compose/` 目录创建 `.env.example`：

```bash
cat > .env.example <<'EOF'
# 数据库配置
DB_USER=postgres
DB_PASSWORD=postgres
DB_NAME=bipupu

# 应用配置（需要通过 GitHub Secrets 提供）
SECRET_KEY=your-secret-key-here
ADMIN_PASSWORD=admin-password
ADMIN_USERNAME=admin

# 其他
LOG_LEVEL=INFO
TZ=Asia/Shanghai
EOF
```

## ✅ 验证设置

### 1. 检查 Docker 容器存储

```bash
# 检查 Docker 卷位置（通常在 /var/lib/docker/volumes）
docker volume ls | grep bipupu
```

### 2. 测试 docker compose 命令

```bash
cd ~/bipupu-compose

# 检查配置是否有效
docker compose config > /dev/null && echo "✅ 配置文件有效" || echo "❌ 配置文件有错误"
```

### 3. 检查磁盘空间

```bash
# 检查可用空间
df -h

# 检查 /var/lib/docker 的大小
du -sh /var/lib/docker/
```

### 4. 验证网络配置

```bash
# 检查 docker 网络
docker network ls

# 尝试创建测试网络
docker network create test-network
docker network rm test-network
```

## 🚀 首次部署准备

### 1. 验证 SSH 连接

在 GitHub Actions 工作流测试前，手动验证 SSH：

```bash
# 从本地机器测试（使用你为 CI/CD 配置的同一个密钥）
ssh -i /path/to/private/key user@server "docker --version"
```

### 2. 确认 GitHub Container Registry 访问

```bash
# 在远程服务器测试登录
echo "YOUR_GITHUB_TOKEN" | docker login ghcr.io -u YOUR_USERNAME --password-stdin

# 测试拉取镜像
docker pull ghcr.io/your-org/bipupu-backend:latest
```

### 3. 清理测试镜像

```bash
# 删除测试镜像
docker image prune -f

# 检查剩余镜像
docker images
```

## 📊 监控和维护

### 定期清理旧镜像

```bash
# 手动清理超过 48 小时的镜像
docker image prune -f --filter "until=48h"

# 查看镜像大小
docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}"
```

### 查看卷大小

```bash
# 查看所有卷的大小
docker volume ls --format "table {{.Name}}\t{{.Driver}}" | while read name driver; do
  if [ "$name" != "DRIVER" ]; then
    size=$(docker run --rm -v "$name:/data" -q busybox du -sh /data 2>/dev/null | cut -f1)
    echo "$name: $size"
  fi
done
```

### 查看 Docker 系统使用情况

```bash
# 查看 Docker 系统信息
docker system df

# 查看系统内所有容器、镜像、卷的大小
docker system df -v
```

## 🔄 手动回滚

如果需要手动回滚到之前的版本：

```bash
# 1. 查看备份的镜像
cat ~/bipupu-backups/last-image.txt

# 2. 设置要回滚的镜像
export BACKEND_IMAGE="ghcr.io/your-org/bipupu-backend:abc12345"

# 3. 从 .env 文件获取配置
cd ~/bipupu-compose
source .env

# 4. 执行回滚
docker compose \
  -f docker-compose.yml \
  -f docker-compose.prod.yml \
  --env-file .env \
  -p bipupu-backend \
  up -d --remove-orphans

# 5. 检查状态
docker ps
docker logs bipupu-backend -f
```

## 🆘 常见问题

### Q: `docker compose` 命令找不到

**A:** 确保安装了 Docker Compose v2：
```bash
docker compose version

# 如果没有，更新 Docker
sudo apt update && sudo apt install docker-ce docker-compose-plugin
```

### Q: 权限被拒绝（Permission denied）

**A:** 添加用户到 docker 组：
```bash
sudo usermod -aG docker $USER
newgrp docker
```

### Q: 磁盘空间不足

**A:** 清理旧镜像和卷：
```bash
docker image prune -a -f
docker volume prune -f
```

### Q: 网络连接问题

**A:** 检查防火墙和网络配置：
```bash
# 检查 docker 网络
docker network ls

# 检查容器网络连接
docker exec bipupu-backend ping db
```

## 📞 需要帮助？

请参考主部署指南：[DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)

或查看故障排查部分。
