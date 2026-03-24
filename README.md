# Bipupu - 蓝牙传呼机应用

<p align="center">
  <img src="mobile/assets/icon/app_icon.png" width="120" alt="Bipupu Logo">
</p>

<p align="center">
  <strong>一款支持蓝牙低功耗（BLE）通信的传呼机应用</strong>
</p>

<p align="center">
  <a href="#-功能特性">功能特性</a> •
  <a href="#-项目结构">项目结构</a> •
  <a href="#-快速开始">快速开始</a> •
  <a href="#-部署指南">部署指南</a> •
  <a href="#-api文档">API文档</a>
</p>

---

## 📋 项目简介

**Bipupu** 是一款创新的蓝牙传呼机应用，通过蓝牙低功耗（BLE）技术与硬件设备通信，实现消息的实时转发与显示。应用包含完整的后端服务、移动端应用，支持消息推送、语音识别、语音合成等智能功能。

### 核心特性

- 🔗 **蓝牙设备管理** - 支持 Nordic UART Service (NUS) 协议
- 📨 **实时消息转发** - IM 消息自动推送至蓝牙设备
- 🎙️ **语音识别 (ASR)** - 离线语音转文字 (Sherpa-ONNX)
- 🔊 **语音合成 (TTS)** - 离线文字转语音
- 📟 **传呼机界面** - 模拟传统传呼机交互体验
- 👥 **联系人管理** - 添加、编辑、删除联系人
- 🚫 **黑名单功能** - 拦截指定用户消息
- 📱 **服务号订阅** - 订阅服务号接收推送

---

## 🏗️ 项目结构

```
bipupu/
├── 📁 backend/          # FastAPI 后端服务
│   ├── app/             # 应用代码
│   ├── docker/          # Docker 配置
│   ├── docs/            # 后端文档
│   ├── tests/           # 测试代码
│   ├── alembic/         # 数据库迁移
│   └── openapi.json     # OpenAPI 规范
│
├── 📁 mobile/           # Flutter 移动端应用
│   ├── android/         # Android 配置
│   ├── ios/             # iOS 配置
│   ├── lib/             # Dart 源代码
│   ├── assets/          # 资源文件
│   └── docs/            # 移动端文档
│
├── 📁 docs/             # 项目文档
│   ├── DEPLOYMENT.md    # 部署指南
│   ├── WEBSOCKET_API.md # WebSocket API 文档
│   └── ARCHITECTURE.md  # 架构设计文档
│
└── 📁 .github/
    └── workflows/       # CI/CD 配置
```

---

## 🖥️ 后端服务 (Backend)

### 技术栈

| 组件 | 版本 | 说明 |
|------|------|------|
| **Python** | 3.13+ | 运行时环境 |
| **FastAPI** | 0.122+ | Web 框架 |
| **PostgreSQL** | 15+ | 主数据库 |
| **Redis** | 7+ | 缓存与消息队列 |
| **Celery** | 5.5+ | 异步任务队列 |
| **SQLAlchemy** | 2.0+ | ORM |
| **UV** | latest | 包管理器 |
| **Docker** | 20.10+ | 容器化部署 |

### 服务架构

```
┌─────────────────────────────────────────────────────────────┐
│                        客户端层                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │   Flutter    │  │   Web 管理   │  │   蓝牙设备   │      │
│  │    App       │  │    后台      │  │              │      │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘      │
└─────────┼─────────────────┼─────────────────┼──────────────┘
          │                 │                 │
          └─────────────────┼─────────────────┘
                            │ HTTPS/WSS
┌───────────────────────────▼───────────────────────────────┐
│                      API 网关层                            │
│              Nginx / Traefik (反向代理)                     │
└───────────────────────────┬───────────────────────────────┘
                            │
┌───────────────────────────▼───────────────────────────────┐
│                     应用服务层                             │
│  ┌─────────────────────────────────────────────────────┐  │
│  │              FastAPI 主服务 (Port 8000)              │  │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────┐            │  │
│  │  │ 认证模块 │ │ 消息模块 │ │ 用户模块 │            │  │
│  │  └──────────┘ └──────────┘ └──────────┘            │  │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────┐            │  │
│  │  │ 联系模块 │ │ 服务号   │ │ 管理后台 │            │  │
│  │  └──────────┘ └──────────┘ └──────────┘            │  │
│  └─────────────────────────────────────────────────────┘  │
│  ┌─────────────────────────────────────────────────────┐  │
│  │           WebSocket 服务 (实时推送)                  │  │
│  └─────────────────────────────────────────────────────┘  │
└───────────────────────────┬───────────────────────────────┘
                            │
┌───────────────────────────▼───────────────────────────────┐
│                     数据处理层                             │
│  ┌─────────────────┐  ┌─────────────────────────────────┐ │
│  │  Celery Worker  │  │         Celery Beat             │ │
│  │  (异步任务处理)  │  │        (定时任务调度)            │ │
│  └─────────────────┘  └─────────────────────────────────┘ │
└───────────────────────────┬───────────────────────────────┘
                            │
┌───────────────────────────▼───────────────────────────────┐
│                      数据存储层                            │
│  ┌─────────────────┐  ┌─────────────────────────────────┐ │
│  │   PostgreSQL    │  │             Redis               │ │
│  │    (主数据库)    │  │      (缓存/消息队列/会话)        │ │
│  └─────────────────┘  └─────────────────────────────────┘ │
└───────────────────────────────────────────────────────────┘
```

### 核心功能模块

| 模块 | 功能 | 端点 |
|------|------|------|
| **认证** | 注册、登录、令牌刷新 | `/api/public/*` |
| **消息** | 发送、接收、收藏、轮询 | `/api/messages/*` |
| **联系人** | 添加、编辑、删除 | `/api/contacts/*` |
| **黑名单** | 拉黑、解除拉黑 | `/api/blocks/*` |
| **用户** | 资料、头像、搜索 | `/api/users/*` |
| **服务号** | 列表、订阅、推送 | `/api/service_accounts/*` |
| **海报** | 创建、更新、删除 | `/api/posters/*` |
| **管理** | 用户、消息、服务号管理 | `/api/admin/*` |
| **WebSocket** | 实时消息推送 | `/api/ws` |

### 本地开发

#### 环境要求

- Python 3.13+
- PostgreSQL 15+
- Redis 7+
- UV 包管理器

#### 安装步骤

```bash
# 1. 进入后端目录
cd backend

# 2. 安装依赖 (使用 uv)
uv sync

# 3. 配置环境变量
cp .env.example .env
# 编辑 .env 文件，设置必要的环境变量

# 4. 启动数据库服务 (需要 Docker)
docker compose -f docker/docker-compose.yml up db redis -d

# 5. 运行数据库迁移
uv run alembic upgrade head

# 6. 启动开发服务器
uv run uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

#### 环境变量

| 变量名 | 必需 | 说明 | 默认值 |
|--------|------|------|--------|
| `SECRET_KEY` | ✅ | JWT 签名密钥 (64位随机字符串) | - |
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

- **Swagger UI**: `http://localhost:8000/api/docs`
- **ReDoc**: `http://localhost:8000/api/redoc`
- **OpenAPI JSON**: `http://localhost:8000/api/openapi.json`

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
| **sherpa_onnx** | 1.10+ | 离线语音识别 |

### 功能模块

```
lib/
├── 📁 core/                    # 核心功能
│   ├── constants/              # 常量定义
│   ├── network/                # 网络层 (Dio + API 客户端)
│   ├── services/               # 服务层
│   └── utils/                  # 工具函数
│
├── 📁 features/                # 功能模块
│   ├── auth/                   # 认证模块
│   ├── bluetooth/              # 蓝牙模块
│   ├── contacts/               # 联系人模块
│   ├── messages/               # 消息模块
│   ├── profile/                # 个人资料模块
│   ├── service_accounts/       # 服务号模块
│   └── voice/                  # 语音模块 (ASR/TTS)
│
└── 📁 presentation/            # 表现层
    ├── pages/                  # 页面
    ├── widgets/                # 组件
    └── blocs/                  # BLoC 状态管理
```

### 本地开发

#### 环境要求

- Flutter SDK 3.10+
- Dart 3.10+
- Android Studio / Xcode
- 真机设备（蓝牙功能需要）

#### 安装步骤

```bash
# 1. 进入移动端目录
cd mobile

# 2. 获取依赖
flutter pub get

# 3. 生成代码 (API 客户端、JSON 序列化等)
flutter pub run build_runner build --delete-conflicting-outputs

# 4. 运行应用
flutter run
```

#### 模型文件

ASR/TTS 功能需要 ONNX 模型文件：

```
mobile/assets/models/
├── asr/                        # 语音识别模型
│   ├── model.onnx
│   └── tokens.txt
└── tts/                        # 语音合成模型
    ├── model.onnx
    └── tokens.txt
```

> ⚠️ 模型文件较大，不包含在代码仓库中。CI/CD 会自动从 Release v1.0.0 下载。

### 构建发布

#### Android APK

```bash
# 构建分架构 APK
flutter build apk --split-per-abi

# 产物位置
# mobile/build/app/outputs/flutter-apk/
#   ├── app-armeabi-v7a-release.apk  (32位 ARM)
#   ├── app-arm64-v8a-release.apk    (64位 ARM)
#   └── app-x86_64-release.apk       (x86_64 模拟器)
```

#### iOS

```bash
# 构建 iOS 应用
flutter build ios --release

# 详细打包指南请参考 mobile/IOS_BUILD_REPORT.md
```

---

## 🚀 快速开始

### 1. 克隆项目

```bash
git clone https://github.com/your-org/bipupu.git
cd bipupu
```

### 2. 启动后端服务

```bash
cd backend

# 使用 Docker Compose 一键启动
docker compose -f docker/docker-compose.yml up -d

# 或使用本地开发模式
uv sync
uv run alembic upgrade head
uv run uvicorn app.main:app --reload
```

### 3. 启动移动端应用

```bash
cd mobile
flutter pub get
flutter run
```

---

## 📚 文档导航

### 项目文档

| 文档 | 说明 |
|------|------|
| [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md) | 完整部署指南 |
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | 系统架构设计 |
| [docs/WEBSOCKET_API.md](docs/WEBSOCKET_API.md) | WebSocket API 文档 |

### 后端文档

| 文档 | 说明 |
|------|------|
| [backend/BACKEND_CODE_REVIEW.md](backend/BACKEND_CODE_REVIEW.md) | 代码审查报告 |
| [backend/CONNECTION_POOL_OPTIMIZATION.md](backend/CONNECTION_POOL_OPTIMIZATION.md) | 连接池优化方案 |
| [backend/POLLING_OPTIMIZATION_REPORT.md](backend/POLLING_OPTIMIZATION_REPORT.md) | 轮询优化报告 |
| [backend/API_SCHEMA_FIX_REPORT.md](backend/API_SCHEMA_FIX_REPORT.md) | API Schema 修复报告 |
| [backend/docs/BLOCKS_API.md](backend/docs/BLOCKS_API.md) | 黑名单 API 文档 |

### 移动端文档

| 文档 | 说明 |
|------|------|
| [mobile/IOS_BUILD_REPORT.md](mobile/IOS_BUILD_REPORT.md) | iOS 打包检测报告 |
| [mobile/REMOTE_MAC_SETUP_GUIDE.md](mobile/REMOTE_MAC_SETUP_GUIDE.md) | 远程 Mac 打包指南 |
| [mobile/QUICK_REFERENCE.md](mobile/QUICK_REFERENCE.md) | iOS 打包快速参考 |
| [mobile/docs/BLUETOOTH_PROTOCOL_QUICK_REFERENCE.md](mobile/docs/BLUETOOTH_PROTOCOL_QUICK_REFERENCE.md) | 蓝牙协议快速参考 |
| [mobile/docs/BLUETOOTH_PROTOCOL_EMBEDDED_GUIDE.md](mobile/docs/BLUETOOTH_PROTOCOL_EMBEDDED_GUIDE.md) | 嵌入式蓝牙协议指南 |

---

## 🔄 CI/CD 配置

项目使用 GitHub Actions 实现自动化部署。

### 后端部署

**工作流**: `.github/workflows/deploy-fastapi-backend.yml`

**触发方式**: 手动触发 (workflow_dispatch)

**必需 Secrets**:

| Secret | 说明 |
|--------|------|
| `SECRET_KEY` | JWT 签名密钥 |
| `ADMIN_USERNAME` | 管理员用户名 |
| `ADMIN_PASSWORD` | 管理员密码 |
| `SERVER_HOST` | 部署服务器 IP/域名 |
| `SERVER_USER` | SSH 登录用户名 |
| `SERVER_SSH_KEY` | SSH 私钥 |

### 移动端发布

**工作流**: `.github/workflows/deploy-flutter-user.yml`

**触发方式**:
- 推送 Tag (格式: `v*` 或 `x.x.x`)
- 手动触发

**发布流程**:
1. 下载 ASR/TTS 模型
2. 构建分架构 APK
3. 创建 GitHub Release 并上传 APK

---

## 🔐 安全配置

### 生产环境检查清单

- [ ] 修改默认 `SECRET_KEY` (64位随机字符串)
- [ ] 修改默认管理员密码
- [ ] 配置 HTTPS/TLS
- [ ] 配置防火墙规则
- [ ] 禁用调试模式
- [ ] 配置日志轮转
- [ ] 设置数据库备份
- [ ] 配置监控告警

### 生成 SECRET_KEY

```bash
# Linux/macOS
openssl rand -hex 32

# Python
python -c "import secrets; print(secrets.token_hex(32))"
```

---

## 🛠️ 故障排除

### 后端常见问题

| 问题 | 解决方案 |
|------|----------|
| 数据库连接失败 | 检查 PostgreSQL 服务是否启动，环境变量是否正确 |
| Redis 连接失败 | 检查 Redis 服务是否启动，端口是否被占用 |
| 迁移失败 | 删除 `alembic/versions` 目录，重新生成迁移 |
| 端口被占用 | 修改 `docker-compose.yml` 中的端口映射 |

### 移动端常见问题

| 问题 | 解决方案 |
|------|----------|
| 蓝牙无法扫描 | 确认使用真机，检查权限是否授予 |
| 模型加载失败 | 确认模型文件已放置在正确位置 |
| API 连接失败 | 检查后端服务是否启动，网络配置是否正确 |
| iOS 签名失败 | 参考 mobile/IOS_BUILD_REPORT.md 进行配置 |

---

## 🤝 贡献指南

1. Fork 本仓库
2. 创建功能分支 (`git checkout -b feature/amazing-feature`)
3. 提交更改 (`git commit -m 'Add amazing feature'`)
4. 推送分支 (`git push origin feature/amazing-feature`)
5. 创建 Pull Request

---

## 📄 许可证

本项目采用 [MIT](LICENSE) 许可证。

---

## 📞 联系我们

- 问题反馈: [GitHub Issues](https://github.com/your-org/bipupu/issues)
- 文档更新: Pull Requests
- 技术讨论: Discussions

---

<p align="center">
  Made with ❤️ by Bipupu Team
</p>
