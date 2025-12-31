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

### 移动端与前端 (Flutter)
- 📱 **Flutter User App** - 面向普通用户的移动端应用 (Android/iOS)，集成蓝牙寻呼与 AI 语音功能。
- 🖥️ **Flutter Admin App** - 面向管理员的管理端应用 (Windows/Web)，提供数据管理与监控面板。
- 📦 **Flutter Core** - 共享核心库，包含通用的数据模型、API 客户端与基础服务。

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
├── flutter_core/              # [核心库] Flutter 共享代码包
│   ├── lib/
│   │   ├── models/           # 通用数据模型
│   │   ├── repositories/     # 数据仓库
│   │   ├── core/             # 基础服务 (Auth, Theme, Network)
│   │   └── utils/            # 工具类
├── flutter_user/              # [用户端] Flutter 移动应用 (Android/iOS)
│   ├── lib/
│   │   ├── features/         # 用户端业务模块
│   │   └── services/         # 硬件相关服务 (Bluetooth, Speech, Background)
│   └── assets/               # AI 模型与资源文件
├── flutter_admin/             # [管理端] Flutter 桌面/Web 应用 (Windows/Web)
│   ├── lib/
│   │   └── features/         # 管理端业务模块
├── deployment/                # 部署配置
│   ├── docker/               # Docker Compose 配置
│   ├── nginx/                # Nginx 反向代理配置
│   └── scripts/              # 部署脚本
└── doc/                      # 项目文档
```

## 🚀 快速开始

### 环境要求

- **Docker** 20.10+ 和 **Docker Compose** 2.0+
- **Flutter** 3.10+ (移动端开发)
- **Python** 3.11+ (本地后端开发)

### 一键部署 (后端)

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
```

### 服务访问

- **API 文档**: http://localhost:8084/docs
- **ReDoc**: http://localhost:8084/redoc  
- **健康检查**: http://localhost:8084/health
- **pgAdmin** (可选): http://localhost:8085 (需要启用 tools 配置)

## 🔧 Flutter 开发指南

本项目采用 **Monorepo** 风格的多包架构，分为核心库、用户端和管理端。

### 1. 核心库 (flutter_core)
包含所有通用的业务逻辑、数据模型和 API 封装。

```bash
cd flutter_core
flutter pub get
flutter analyze
```

### 2. 用户端 (flutter_user)
面向 C 端用户，包含蓝牙通信、语音识别等重型功能。支持 Android 和 iOS。

```bash
cd flutter_user
flutter pub get

# 运行 (连接真机或模拟器)
flutter run

# 构建 APK
flutter build apk --release
```

### 3. 管理端 (flutter_admin)
面向 B 端管理员，轻量级，移除不必要的原生依赖。支持 Windows 和 Web。

```bash
cd flutter_admin
flutter pub get

# 运行 Windows 版
flutter run -d windows

# 运行 Web 版
flutter run -d chrome

# 构建 Windows 安装包
flutter build windows

# 构建 Web 产物
flutter build web
```

## 🔧 后端开发指南

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

# 启动开发服务器
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
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
```

- **pgAdmin** (可选): http://localhost:8085 (需要启用 tools 配置)