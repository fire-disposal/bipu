# Bipupu 部署指南

本文档详细介绍 Bipupu 项目的部署流程，包括后端服务部署、移动端构建发布以及生产环境配置。

---

## 📋 目录

1. [环境准备](#环境准备)
2. [后端部署](#后端部署)
3. [移动端构建](#移动端构建)
4. [生产环境配置](#生产环境配置)
5. [监控与维护](#监控与维护)
6. [故障排除](#故障排除)

---

## 环境准备

### 服务器要求

#### 最低配置

| 组件 | 配置 | 说明 |
|------|------|------|
| CPU | 2 核 | 支持 Docker 运行 |
| 内存 | 4 GB | 建议 8 GB 以上 |
| 磁盘 | 50 GB SSD | 数据库存储 |
| 网络 | 10 Mbps | 公网访问 |
| 系统 | Ubuntu 22.04 LTS | 推荐 |

#### 推荐配置

| 组件 | 配置 | 说明 |
|------|------|------|
| CPU | 4 核 | 高并发场景 |
| 内存 | 8 GB | 稳定运行 |
| 磁盘 | 100 GB SSD | 数据备份 |
| 网络 | 100 Mbps | 低延迟访问 |

### 软件依赖

```bash
# 安装 Docker
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER

# 安装 Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# 验证安装
docker --version
docker-compose --version
```

---

## 后端部署

### 方式一：Docker Compose 部署（推荐）

#### 1. 准备部署目录

```bash
# 创建部署目录
mkdir -p ~/bipupu-deploy
cd ~/bipupu-deploy

# 克隆代码
git clone https://github.com/your-org/bipupu.git
cd bipupu/backend
```

#### 2. 配置环境变量

```bash
# 复制环境变量模板
cp .env.example .env

# 编辑 .env 文件
nano .env
```

**必需配置项**：

```env
# 安全密钥 (必须修改!)
SECRET_KEY=your-64-char-random-string-here-change-in-production

# 管理员账户 (必须修改!)
ADMIN_USERNAME=admin
ADMIN_PASSWORD=your-strong-password-here

# 数据库配置 (可选，使用默认值即可)
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres
POSTGRES_DB=bipupu

# Redis 配置 (可选)
REDIS_HOST=redis
REDIS_PORT=6379
```

#### 3. 启动服务

```bash
# 进入 Docker 配置目录
cd docker

# 启动所有服务
docker-compose up -d

# 查看服务状态
docker-compose ps

# 查看日志
docker-compose logs -f backend
```

#### 4. 验证部署

```bash
# 健康检查
curl http://localhost:8000/api/health

# 预期响应
{"status":"healthy","database":"connected","redis":"connected"}
```

### 方式二：手动部署

#### 1. 安装 Python 依赖

```bash
# 安装 UV
curl -LsSf https://astral.sh/uv/install.sh | sh

# 进入后端目录
cd backend

# 安装依赖
uv sync
```

#### 2. 配置数据库

```bash
# 安装 PostgreSQL 和 Redis
sudo apt update
sudo apt install postgresql-15 redis-server

# 创建数据库
sudo -u postgres psql -c "CREATE DATABASE bipupu;"
sudo -u postgres psql -c "CREATE USER bipupu WITH PASSWORD 'your-password';"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE bipupu TO bipupu;"
```

#### 3. 运行迁移

```bash
uv run alembic upgrade head
```

#### 4. 启动服务

```bash
# 开发模式
uv run uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

# 生产模式
uv run uvicorn app.main:app --host 0.0.0.0 --port 8000 --workers 4
```

### 方式三：CI/CD 自动部署

#### 1. 配置 GitHub Secrets

在 GitHub 仓库设置中添加以下 Secrets：

| Secret | 说明 | 示例 |
|--------|------|------|
| `SERVER_HOST` | 服务器地址 | `123.45.67.89` |
| `SERVER_USER` | SSH 用户名 | `root` |
| `SERVER_SSH_KEY` | SSH 私钥 | `-----BEGIN OPENSSH PRIVATE KEY-----...` |
| `SECRET_KEY` | JWT 密钥 | `a1b2c3d4...` (64位) |
| `ADMIN_USERNAME` | 管理员用户名 | `admin` |
| `ADMIN_PASSWORD` | 管理员密码 | `SecurePass123!` |

#### 2. 触发部署

```bash
# 方式 1: GitHub Actions 页面手动触发
# 进入仓库 -> Actions -> Deploy FastAPI Backend -> Run workflow

# 方式 2: 推送代码自动触发
git push origin main
```

#### 3. 部署流程

```
1. 构建 Docker 镜像
2. 推送镜像到 GHCR
3. SSH 连接服务器
4. 拉取最新镜像
5. 执行数据库迁移
6. 启动新容器
7. 健康检查
8. 失败自动回滚
```

---

## 移动端构建

### Android APK 构建

#### 本地构建

```bash
# 进入移动端目录
cd mobile

# 获取依赖
flutter pub get

# 生成代码
flutter pub run build_runner build --delete-conflicting-outputs

# 构建 APK (分架构)
flutter build apk --split-per-abi

# 产物位置
# build/app/outputs/flutter-apk/
#   ├── app-armeabi-v7a-release.apk
#   ├── app-arm64-v8a-release.apk
#   └── app-x86_64-release.apk
```

#### CI/CD 自动构建

```bash
# 推送 Tag 触发构建
git tag v1.0.0
git push origin v1.0.0

# GitHub Actions 将自动:
# 1. 下载 ASR/TTS 模型
# 2. 构建分架构 APK
# 3. 创建 Release 并上传 APK
```

### iOS 构建

#### 前置要求

- macOS 系统
- Xcode 15+
- Apple ID (免费或开发者账户)
- iPhone 真机 (蓝牙功能需要)

#### 快速构建流程

```bash
# 1. 进入项目目录
cd mobile

# 2. 运行设置脚本
./setup_ios_temporary_build.sh
# 输入 Bundle ID，如: com.yourname.bipupu

# 3. 打开 Xcode
open ios/Runner.xcworkspace

# 4. 在 Xcode 中配置签名
# - 选择 Runner Target
# - Signing & Capabilities
# - 勾选 "Automatically manage signing"
# - Team 选择你的 Apple ID

# 5. 构建并运行
flutter clean
flutter pub get
flutter run
```

#### 远程 Mac 打包

如果没有 Mac 设备，可以远程操作朋友的 Mac：

```bash
# 1. 让朋友准备:
#    - Apple ID
#    - Xcode 已安装
#    - Flutter 已安装
#    - iPhone 连接 Mac

# 2. 远程操作步骤
cd /path/to/bipupu/mobile
./setup_ios_temporary_build.sh
open ios/Runner.xcworkspace

# 3. 指导朋友在 Xcode 中配置签名并运行
```

详细步骤请参考 [mobile/REMOTE_MAC_SETUP_GUIDE.md](../mobile/REMOTE_MAC_SETUP_GUIDE.md)

---

## 生产环境配置

### Nginx 反向代理

```nginx
# /etc/nginx/sites-available/bipupu
server {
    listen 80;
    server_name api.yourdomain.com;
    
    # 重定向到 HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name api.yourdomain.com;
    
    # SSL 证书
    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;
    
    # 安全头
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    
    # API 代理
    location /api/ {
        proxy_pass http://localhost:8000/api/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # 超时设置
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
    
    # 静态文件
    location /static/ {
        alias /path/to/static/files/;
        expires 30d;
    }
}
```

### SSL 证书配置

```bash
# 使用 Certbot 自动获取 Let's Encrypt 证书
sudo apt install certbot python3-certbot-nginx

# 获取证书
sudo certbot --nginx -d api.yourdomain.com

# 自动续期
sudo certbot renew --dry-run
```

### 防火墙配置

```bash
# 允许 SSH
sudo ufw allow 22/tcp

# 允许 HTTP/HTTPS
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# 允许后端服务 (仅本地访问，不暴露公网)
# sudo ufw allow 8000/tcp  # 不推荐暴露

# 启用防火墙
sudo ufw enable

# 查看状态
sudo ufw status
```

### 数据库备份

```bash
# 创建备份脚本
mkdir -p ~/bipupu-backups

# 备份脚本 ~/bipupu-backups/backup.sh
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/root/bipupu-backups"
DB_NAME="bipupu"
DB_USER="postgres"

# 执行备份
docker exec bipupu-db pg_dump -U $DB_USER $DB_NAME > $BACKUP_DIR/backup_$DATE.sql

# 压缩备份
gzip $BACKUP_DIR/backup_$DATE.sql

# 保留最近 30 天的备份
find $BACKUP_DIR -name "backup_*.sql.gz" -mtime +30 -delete

echo "Backup completed: backup_$DATE.sql.gz"
```

```bash
# 添加执行权限
chmod +x ~/bipupu-backups/backup.sh

# 添加到定时任务 (每天凌晨 2 点执行)
crontab -e
# 添加: 0 2 * * * /root/bipupu-backups/backup.sh >> /root/bipupu-backups/backup.log 2>&1
```

---

## 监控与维护

### 日志管理

```bash
# 查看后端日志
docker-compose logs -f backend

# 查看 Celery 日志
docker-compose logs -f celery-worker

# 查看 Nginx 日志
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log
```

### 性能监控

```bash
# 查看容器资源使用
docker stats

# 查看数据库连接数
docker exec bipupu-db psql -U postgres -c "SELECT count(*) FROM pg_stat_activity;"

# 查看 Redis 状态
docker exec bipupu-redis redis-cli info
```

### 健康检查

```bash
# API 健康检查
curl -f http://localhost:8000/api/health || echo "API is down"

# 数据库健康检查
docker exec bipupu-db pg_isready -U postgres

# Redis 健康检查
docker exec bipupu-redis redis-cli ping
```

### 自动重启配置

```yaml
# docker/docker-compose.yml
services:
  backend:
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/api/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
```

---

## 故障排除

### 后端服务无法启动

```bash
# 检查日志
docker-compose logs backend

# 常见问题:
# 1. 数据库连接失败 - 检查数据库服务是否启动
# 2. 端口被占用 - 修改 docker-compose.yml 中的端口映射
# 3. 环境变量错误 - 检查 .env 文件配置
```

### 数据库迁移失败

```bash
# 进入容器
docker exec -it bipupu-backend bash

# 查看迁移状态
uv run alembic current
uv run alembic history

# 回滚到指定版本
uv run alembic downgrade <revision>

# 重新生成迁移
uv run alembic revision --autogenerate -m "fix migration"
uv run alembic upgrade head
```

### 移动端 API 连接失败

```bash
# 检查后端服务
curl http://<server-ip>:8000/api/health

# 检查网络连通性
ping <server-ip>

# 检查防火墙设置
sudo ufw status
```

### 蓝牙功能异常

```bash
# 确认使用真机 (模拟器不支持蓝牙)
# 检查权限是否授予
# 查看移动端日志
flutter logs
```

---

## 升级指南

### 后端升级

```bash
cd ~/bipupu-deploy/bipupu

# 拉取最新代码
git pull origin main

# 重新构建镜像
cd backend/docker
docker-compose down
docker-compose up -d --build

# 执行迁移
docker exec bipupu-backend uv run alembic upgrade head
```

### 移动端升级

```bash
# 更新代码
git pull origin main

# 更新依赖
cd mobile
flutter pub get

# 重新构建
flutter build apk --split-per-abi
```

---

## 安全建议

### 生产环境检查清单

- [ ] 修改默认 SECRET_KEY
- [ ] 修改默认管理员密码
- [ ] 配置 HTTPS/TLS
- [ ] 禁用调试模式
- [ ] 配置防火墙规则
- [ ] 设置数据库备份
- [ ] 配置日志轮转
- [ ] 设置监控告警
- [ ] 定期更新依赖
- [ ] 启用自动安全更新

### 安全更新

```bash
# 更新系统
sudo apt update && sudo apt upgrade -y

# 更新 Docker 镜像
docker-compose pull
docker-compose up -d

# 扫描漏洞
docker scan bipupu-backend
```

---

## 参考文档

- [后端代码审查报告](../backend/BACKEND_CODE_REVIEW.md)
- [连接池优化方案](../backend/CONNECTION_POOL_OPTIMIZATION.md)
- [iOS 打包指南](../mobile/IOS_BUILD_REPORT.md)
- [WebSocket API 文档](./WEBSOCKET_API.md)

---

**最后更新**: 2026年3月24日
**文档版本**: 1.0
