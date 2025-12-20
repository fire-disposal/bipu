# Bipupu - 现代蓝牙寻呼机系统

基于 FastAPI + PostgreSQL + Redis + Celery + Flutter 的全栈蓝牙寻呼机管理解决方案。

## 🌟 功能特性

### 后端服务
- 🚀 **FastAPI** - 现代、快速的 Web 框架，支持异步处理
- 🗄️ **PostgreSQL** - 强大的关系型数据库，支持复杂查询
- ⚡ **Redis** - 高性能缓存和消息队列
- 📋 **Celery** - 分布式任务队列，支持定时任务
- 🐳 **Docker** - 容器化部署，一键启动
- 🔧 **Alembic** - 数据库迁移工具，版本控制
- 📊 **SQLAlchemy** - ORM 框架，简化数据库操作
- 📝 **Pydantic** - 数据验证和序列化

### 移动端
- 📱 **Flutter** - 跨平台移动应用开发
- 🔵 **BLE 蓝牙** - 寻呼机设备连接和消息传输
- 🎨 **Material Design** - 现代化 UI 设计
- 🌐 **REST API** - 与后端服务无缝集成

## 📁 项目结构

```
bipupu/
├── backend/                    # FastAPI 后端服务
│   ├── app/                   # 应用代码
│   │   ├── api/              # API 路由
│   │   ├── core/             # 核心配置
│   │   ├── db/               # 数据库相关
│   │   ├── models/           # 数据模型
│   │   ├── schemas/          # Pydantic 模式
│   │   └── tasks/            # Celery 任务
│   ├── alembic/              # 数据库迁移
│   └── Dockerfile           # Docker 镜像配置
├── flutter/                   # Flutter 移动端应用
│   ├── lib/                  # Dart 源代码
│   │   ├── core/             # 核心功能
│   │   ├── features/         # 功能模块
│   │   ├── app_user/         # 用户端应用
│   │   └── app_admin/        # 管理端应用
│   └── pubspec.yaml         # Flutter 依赖配置
├── deployment/                # 部署配置
│   ├── docker/               # Docker Compose 配置
│   ├── nginx/                # Nginx 反向代理配置
│   └── scripts/              # 部署脚本
└── doc/                      # 项目文档
```

## 🚀 快速开始

### 环境要求

- **Docker** 20.10+ 和 **Docker Compose** 2.0+
- **Flutter** 3.0+ (移动端开发)
- **Python** 3.11+ (本地后端开发)

### 一键部署

```bash
# 1. 克隆项目
git clone <your-repo>
cd bipupu

# 2. 配置环境变量
cp .env.example .env
# 编辑 .env 文件，设置必要的配置（数据库密码、JWT密钥等）

# 3. 一键启动所有服务
docker-compose -f deployment/docker/docker-compose.yml up -d

# 4. 查看服务状态
docker-compose -f deployment/docker/docker-compose.yml ps

# 5. 查看日志
docker-compose -f deployment/docker/docker-compose.yml logs -f
```

### 服务访问

- **API 文档**: http://localhost:8084/docs
- **ReDoc**: http://localhost:8084/redoc  
- **健康检查**: http://localhost:8084/health
- **pgAdmin** (可选): http://localhost:8085 (需要启用 tools 配置)

### 可选服务启动

```bash
# 启动包含 pgAdmin 的所有服务
docker-compose -f deployment/docker/docker-compose.yml --profile tools up -d

# 仅启动后端、数据库、Redis（最小化部署）
docker-compose -f deployment/docker/docker-compose.yml up backend db redis -d
```

## 🔧 开发指南

### 后端开发

```bash
# 进入后端目录
cd backend

# 安装依赖
pip install -e .
pip install -e ".[dev]"

# 配置环境变量
cp .env.example .env
# 编辑 .env 文件

# 数据库迁移
alembic upgrade head

# 创建新的迁移
alembic revision --autogenerate -m "描述"

# 启动开发服务器
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

### 移动端开发

```bash
# 进入 Flutter 目录
cd flutter

# 安装依赖
flutter pub get

# 运行用户端应用
flutter run -t lib/main_user.dart

# 运行管理端应用  
flutter run -t lib/main_admin.dart

# 构建 APK
flutter build apk --target-platform android-arm64
```

### 数据库管理

```bash
# 进入数据库容器
docker exec -it bipupu-db psql -U postgres -d bipupu

# 备份数据库
docker exec bipupu-db pg_dump -U postgres bipupu > backup.sql

# 恢复数据库
docker exec -i bipupu-db psql -U postgres -d bipupu < backup.sql
```

## 📊 环境变量配置

### 必填配置
| 变量名 | 说明 | 示例 |
|--------|------|--------|
| `POSTGRES_PASSWORD` | PostgreSQL 密码 | `your-strong-password` |
| `REDIS_PASSWORD` | Redis 密码 | `your-strong-password` |
| `SECRET_KEY` | JWT 密钥 | `32+字符随机字符串` |

### 可选配置
| 变量名 | 说明 | 默认值 |
|--------|------|--------|
| `DEBUG` | 调试模式 | `false` |
| `LOG_LEVEL` | 日志级别 | `INFO` |
| `ACCESS_TOKEN_EXPIRE_MINUTES` | JWT 过期时间 | `30` |
| `MAX_FILE_SIZE` | 最大文件大小 | `10485760` |
| `PGADMIN_EMAIL` | pgAdmin 登录邮箱 | `admin@bipupu.com` |
| `PGADMIN_PASSWORD` | pgAdmin 登录密码 | 必填 |

## 🐳 Docker 命令参考

```bash
# 构建镜像
docker build -t bipupu-backend ./backend

# 查看日志
docker logs -f bipupu-backend

# 重启服务
docker-compose -f deployment/docker/docker-compose.yml restart backend

# 停止所有服务
docker-compose -f deployment/docker/docker-compose.yml down

# 清理数据卷（谨慎操作）
docker-compose -f deployment/docker/docker-compose.yml down -v

# 查看资源使用
docker stats
```

## 📱 Flutter 多端构建

### Android 构建
```bash
cd flutter

# 构建 release APK
flutter build apk --release

# 构建 app bundle (Google Play)
flutter build appbundle --release

# 构建特定架构
flutter build apk --target-platform android-arm64 --release
```

### iOS 构建 (需要 macOS + Xcode)
```bash
cd flutter

# 构建 release 版本
flutter build ios --release

# 构建并打包
flutter build ipa --release
```

### Web 构建
```bash
cd flutter

# 构建 web 版本
flutter build web --release

# 构建结果在 build/web 目录
```

## 🔍 监控和调试

### 健康检查
```bash
# 检查后端服务
curl http://localhost:8084/health

# 检查数据库连接
curl http://localhost:8084/health/db

# 检查 Redis 连接
curl http://localhost:8084/health/redis
```

### 日志查看
```bash
# 查看所有服务日志
docker-compose -f deployment/docker/docker-compose.yml logs -f

# 查看特定服务日志
docker-compose -f deployment/docker/docker-compose.yml logs -f backend

# 查看最近 100 行日志
docker-compose -f deployment/docker/docker-compose.yml logs --tail=100 backend
```

## 🔧 常见问题

### 数据库连接失败
1. 检查 PostgreSQL 是否启动：`docker ps | grep bipupu-db`
2. 检查环境变量中的密码是否正确
3. 查看数据库日志：`docker logs bipupu-db`

### Redis 连接失败
1. 检查 Redis 是否启动：`docker ps | grep bipupu-redis`
2. 检查 REDIS_PASSWORD 是否正确设置
3. 查看 Redis 日志：`docker logs bipupu-redis`

### Flutter 构建失败
1. 检查 Flutter 版本：`flutter --version`
2. 清理构建缓存：`flutter clean`
3. 重新安装依赖：`flutter pub get`
4. 检查 Dart SDK 版本

## 🤝 贡献指南

1. Fork 项目
2. 创建特性分支 (`git checkout -b feature/amazing-feature`)
3. 提交更改 (`git commit -m 'Add some amazing feature'`)
4. 推送到分支 (`git push origin feature/amazing-feature`)
5. 创建 Pull Request

## 📄 许可证

MIT License - 详见 [LICENSE](LICENSE) 文件

## 🆘 支持

如有问题，请在 GitHub Issues 中提交，或联系开发团队。

---

**快速链接**:
[API 文档](http://localhost:8084/docs) |
[数据库管理](http://localhost:8085) |
[Flutter 构建指南](./flutter/README.md)