# FastAPI Backend

基于 FastAPI + PostgreSQL + Redis + Celery 的现代化后端服务。

## 功能特性

- 🚀 **FastAPI** - 现代、快速的 Web 框架
- 🗄️ **PostgreSQL** - 强大的关系型数据库
- ⚡ **Redis** - 高性能缓存和消息队列
- 📋 **Celery** - 分布式任务队列
- 🐳 **Docker** - 容器化部署
- 🔧 **Alembic** - 数据库迁移工具
- 📊 **SQLAlchemy** - ORM 框架
- 📝 **Pydantic** - 数据验证和序列化

## 项目结构

```
.
├── app/
│   ├── api/              # API 路由
│   ├── core/             # 核心配置
│   ├── db/               # 数据库相关
│   ├── models/           # 数据模型
│   ├── schemas/          # Pydantic 模式
│   ├── tasks/            # Celery 任务
│   ├── main.py           # FastAPI 应用入口
│   └── celery.py         # Celery 配置
├── alembic/              # 数据库迁移
├── nginx_build/          # Nginx 配置
├── docker-compose.yml    # Docker Compose 配置
├── Dockerfile           # Docker 镜像配置
└── pyproject.toml       # 项目依赖
```

## 快速开始

### 环境要求

- Docker 和 Docker Compose
- Python 3.11+ (本地开发)

### 1. 克隆项目

```bash
git clone <your-repo>
cd fastapi-backend
```

### 2. 配置环境变量

```bash
cp .env.example .env
# 编辑 .env 文件，设置必要的配置
```

### 3. 使用 Docker Compose 启动

```bash
# 构建并启动所有服务
docker-compose up -d

# 查看日志
docker-compose logs -f

# 停止服务
docker-compose down
```

### 4. 本地开发 (可选)

```bash
# 安装依赖
pip install -e .

# 安装开发依赖
pip install -e ".[dev]"

# 运行数据库迁移
alembic upgrade head

# 启动开发服务器
uvicorn app.main:app --reload
```

## API 文档

启动服务后，可以访问：

- Swagger UI: http://localhost:8084/docs
- ReDoc: http://localhost:8084/redoc
- 健康检查: http://localhost:8084/health

## 数据库迁移

```bash
# 创建新的迁移
alembic revision --autogenerate -m "描述"

# 应用迁移
alembic upgrade head

# 回滚迁移
alembic downgrade -1
```

## Celery 任务

```bash
# 启动 worker (在容器中自动启动)
celery -A app.celery worker -l info

# 启动 beat (在容器中自动启动)
celery -A app.celery beat -l info
```

## 环境变量

| 变量名 | 说明 | 默认值 |
|--------|------|--------|
| `POSTGRES_PASSWORD` | PostgreSQL 密码 | 必填 |
| `REDIS_PASSWORD` | Redis 密码 | 必填 |
| `SECRET_KEY` | FastAPI 密钥 | 必填 |
| `DEBUG` | 调试模式 | `false` |
| `LOG_LEVEL` | 日志级别 | `INFO` |

## 部署

### 生产环境部署

1. 设置生产环境变量
2. 使用 Docker Compose 启动服务
3. 配置反向代理 (Nginx 已包含)
4. 设置 SSL/TLS 证书

### Docker 命令

```bash
# 构建镜像
docker build -t fastapi-backend .

# 运行容器
docker run -d -p 8000:8000 --env-file .env fastapi-backend
```

## 开发指南

### 代码风格

使用 Black 和 isort 进行代码格式化：

```bash
black app/
isort app/
```

### 类型检查

```bash
mypy app/
```

### 测试

```bash
pytest
```

## 贡献

1. Fork 项目
2. 创建特性分支 (`git checkout -b feature/amazing-feature`)
3. 提交更改 (`git commit -m 'Add some amazing feature'`)
4. 推送到分支 (`git push origin feature/amazing-feature`)
5. 创建 Pull Request

## 许可证

MIT License