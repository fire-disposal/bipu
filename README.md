# Bipupu - 蓝牙传呼机应用

<p align="center">
  <img src="mobile/assets/icon/app_icon.png" width="120" alt="Bipupu Logo">
</p>

**Bipupu** 是一款蓝牙传呼机应用，支持通过蓝牙低功耗（BLE）与硬件设备通信，实现消息的实时转发与显示。

---

## 📁 项目结构

```
bipupu/
├── backend/          # FastAPI 后端服务
├── mobile/           # Flutter 移动端应用
├── plans/            # 项目规划文档
└── .github/workflows # CI/CD 配置
```

---

## 🖥️ 后端服务 (Backend)

### 技术栈

| 组件 | 版本 | 说明 |
|------|------|------|
| **Python** | 3.13 | 运行时环境 |
| **FastAPI** | 0.122+ | Web 框架 |
| **PostgreSQL** | 15 | 主数据库 |
| **Redis** | 7 | 缓存与消息队列 |
| **Celery** | 5.5+ | 异步任务队列 |
| **SQLAlchemy** | 2.0+ | ORM |
| **UV** | latest | 包管理器 |

### 服务架构

后端采用容器化部署，包含以下服务：

- **backend** - FastAPI 主服务 (端口 8000)
- **celery-worker** - 异步任务处理
- **celery-beat** - 定时任务调度
- **db** - PostgreSQL 数据库
- **redis** - Redis 缓存服务

### 本地开发启动

```bash
cd backend

# 1. 安装依赖 (使用 uv)
uv sync

# 2. 启动数据库服务 (需要 Docker)
docker compose -f docker/docker-compose.yml up db redis -d

# 3. 运行数据库迁移
uv run alembic upgrade head

# 4. 启动开发服务器
uv run uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

### Docker 部署

```bash
cd backend

# 构建镜像
docker build -t bipupu-backend:local .

# 启动所有服务
cd docker
docker compose -p bipupu-backend up -d
```

### 环境变量

| 变量名 | 必需 | 说明 | 默认值 |
|--------|------|------|--------|
| `SECRET_KEY` | ✅ | JWT 签名密钥 | - |
| `ADMIN_USERNAME` | ✅ | 管理员用户名 | - |
| `ADMIN_PASSWORD` | ✅ | 管理员密码 | - |
| `POSTGRES_USER` | ❌ | 数据库用户 | `postgres` |
| `POSTGRES_PASSWORD` | ❌ | 数据库密码 | `postgres` |
| `POSTGRES_SERVER` | ❌ | 数据库地址 | `db` |
| `POSTGRES_PORT` | ❌ | 数据库端口 | `5432` |
| `POSTGRES_DB` | ❌ | 数据库名 | `bipupu` |
| `REDIS_HOST` | ❌ | Redis 地址 | `redis` |
| `REDIS_PORT` | ❌ | Redis 端口 | `6379` |

### API 文档

服务启动后访问：
- Swagger UI: `http://localhost:8000/api/docs`
- ReDoc: `http://localhost:8000/api/redoc`
- OpenAPI JSON: `http://localhost:8000/api/openapi.json`

---

## 📱 移动端应用 (Mobile)

### 技术栈

| 组件 | 版本 | 说明 |
|------|------|------|
| **Flutter** | 3.10+ | UI 框架 |
| **Dart** | 3.10+ | 开发语言 |
| **flutter_bloc** | 9.1+ | 状态管理 |
| **flutter_blue_plus** | 2.0+ | 蓝牙 BLE 通信 |
| **go_router** | 17.0+ | 路由管理 |
| **Hive** | 2.2+ | 本地存储 |

### 核心功能

- 🔗 **蓝牙设备绑定与管理** - 支持 Nordic UART Service (NUS) 协议
- 📨 **消息实时转发** - IM 消息自动转发至蓝牙设备
- 🎙️ **语音识别 (ASR)** - 离线语音转文字 (Sherpa-ONNX)
- 🔊 **语音合成 (TTS)** - 离线文字转语音
- 📟 **传呼机界面** - 模拟传统传呼机交互

### 本地开发启动

```bash
cd mobile

# 1. 获取依赖
flutter pub get

# 2. 生成代码 (API 客户端、JSON 序列化等)
flutter pub run build_runner build --delete-conflicting-outputs

# 3. 运行应用
flutter run
```

### 构建 APK

```bash
cd mobile

# 构建分架构 APK
flutter build apk --split-per-abi

# 产物位置
# mobile/build/app/outputs/flutter-apk/
#   ├── app-armeabi-v7a-release.apk  (32位 ARM)
#   ├── app-arm64-v8a-release.apk    (64位 ARM)
#   └── app-x86_64-release.apk       (x86_64 模拟器)
```

### 模型文件

ASR/TTS 功能需要 ONNX 模型文件，放置于：

```
mobile/assets/models/
├── asr/    # 语音识别模型
└── tts/    # 语音合成模型
```

> ⚠️ 模型文件较大，不包含在代码仓库中。CI/CD 会自动从 Release v1.0.0 下载。

---

## 🔄 CI/CD 配置

项目使用 GitHub Actions 实现自动化部署。

### 后端部署 (`deploy-fastapi-backend.yml`)

**触发方式**: 手动触发 (workflow_dispatch)

**必需的 Secrets**:

| Secret 名称 | 说明 |
|-------------|------|
| `SECRET_KEY` | JWT 签名密钥 (建议 64 位随机字符串) |
| `ADMIN_USERNAME` | 管理员用户名 |
| `ADMIN_PASSWORD` | 管理员密码 |
| `SERVER_HOST` | 部署服务器 IP/域名 |
| `SERVER_USER` | SSH 登录用户名 |
| `SERVER_SSH_KEY` | SSH 私钥 (用于部署) |

**部署流程**:
1. 构建 Docker 镜像并推送至 GHCR
2. SSH 连接服务器
3. 拉取最新镜像并启动服务
4. 健康检查
5. 失败自动回滚

### 移动端发布 (`deploy-flutter-user.yml`)

**触发方式**: 
- 推送 Tag (格式: `v*` 或 `x.x.x`)
- 手动触发

**必需的 Secrets**:

| Secret 名称 | 说明 |
|-------------|------|
| `GITHUB_TOKEN` | 自动提供，用于发布 Release |

**发布流程**:
1. 下载 ASR/TTS 模型 (从 v1.0.0 Release)
2. 构建分架构 APK
3. 创建 GitHub Release 并上传 APK

---

## 🔧 快速配置 CI/CD

### 1. 配置 GitHub Secrets

进入仓库 **Settings** → **Secrets and variables** → **Actions**，添加以下 Secrets:

```
# 后端部署必需
SECRET_KEY=<your-64-char-random-string>
ADMIN_USERNAME=<admin-username>
ADMIN_PASSWORD=<strong-password>
SERVER_HOST=<your-server-ip>
SERVER_USER=<ssh-username>
SERVER_SSH_KEY=<ssh-private-key-content>
```

### 2. 生成 SECRET_KEY

```bash
# Linux/macOS
openssl rand -hex 32

# Python
python -c "import secrets; print(secrets.token_hex(32))"
```

### 3. 服务器准备

确保部署服务器已安装：
- Docker 20.10+
- Docker Compose v2

```bash
# 创建工作目录
mkdir -p ~/bipupu-compose ~/bipupu-backups
```

---

## 📄 API Schema

后端 OpenAPI 规范文件位于 `backend/openapi.json`，可用于：
- 生成客户端代码
- API 文档导入 (Postman, Insomnia)
- 前端 TypeScript 类型生成

---

## 📝 License

MIT License

---

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！
