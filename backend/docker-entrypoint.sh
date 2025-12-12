#!/bin/bash

# 确保任何命令失败时脚本立即退出
set -e

# =================================================================
# 📋 容器角色判断和初始化逻辑 (FastAPI版本)
# =================================================================

# 从环境变量获取容器角色，默认为 'backend'
CONTAINER_ROLE="${CONTAINER_ROLE:-backend}"
# 定义用于数据库检查的硬编码密码，必须与 docker-compose.yml 中 db 服务 POSTGRES_PASSWORD 匹配
DB_CHECK_PASSWORD="1919810" 

echo "==================================================="
echo "🚀 Starting FastAPI Container - Role: $CONTAINER_ROLE"
echo "==================================================="

# -----------------------------------------------------------------
# 🔍 数据库连接等待 (Application Level Wait)
# -----------------------------------------------------------------
echo "⏳ Waiting for PostgreSQL connection to be ready..."
MAX_ATTEMPTS=30
ATTEMPTS=0
# 循环检查：连接到默认的 'postgres' 数据库
until [ $ATTEMPTS -ge $MAX_ATTEMPTS ]; do
    # 使用 PGPASSWORD=... 传递密码
    if PGPASSWORD=$DB_CHECK_PASSWORD psql -h db -U postgres -d postgres -c "SELECT 1;" > /dev/null 2>&1; then
        echo "✅ Database connection established."
        break
    fi

    ATTEMPTS=$((ATTEMPTS + 1))
    echo "   Attempt $ATTEMPTS/$MAX_ATTEMPTS: Waiting for DB..."
    sleep 1
done

# 如果循环结束仍未成功连接，则退出
if [ $ATTEMPTS -eq $MAX_ATTEMPTS ]; then
    echo "❌ Failed to connect to database after $MAX_ATTEMPTS attempts."
    exit 1
fi

# 确保目标数据库存在 (连接到默认数据库 postgres 来执行 CREATE DATABASE)
echo "🔍 Ensuring database 'bipupu' exists..."
PGPASSWORD=$DB_CHECK_PASSWORD psql -h db -U postgres -d postgres -c "SELECT 1 FROM pg_database WHERE datname = 'bipupu';" | grep -q 1 || \
PGPASSWORD=$DB_CHECK_PASSWORD psql -h db -U postgres -d postgres -c "CREATE DATABASE bipupu;" > /dev/null 2>&1 || true

# -----------------------------------------------------------------
# 🔄 主后端容器执行初始化操作 (仅由 backend 容器执行)
# -----------------------------------------------------------------
if [ "$CONTAINER_ROLE" = "backend" ]; then
    echo "--- Initializing FastAPI Backend Service ---"
    
    # 1. 数据库表创建 (使用Alembic迁移)
    echo "🔄 Running database migrations..."
    # 注意：Alembic/uvicorn 会读取 DATABASE_URL 变量来连接数据库
    uv run alembic upgrade head
    
    
    echo "✅ FastAPI Backend initialization complete."
fi

# -----------------------------------------------------------------
# 🏃 根据容器角色执行相应命令 (使用 exec 确保信号处理)
# -----------------------------------------------------------------
echo "---------------------------------------------------"
case "$CONTAINER_ROLE" in
    "worker")
        echo "// [🔄️ Starting Celery Worker] //"
        exec uv run celery -A app.celery worker -l info -Q default
        ;;
    "beat")
        echo "// [❤️ Starting Celery Beat] //"
        exec uv run celery -A app.celery beat -l info --scheduler celery.beat:PersistentScheduler
        ;;
    "backend")
        echo "// [🌱 Starting FastAPI Backend] //"
        
        # Banner 展示
        cat << 'FASTAPI_BANNER'        
        _____________                               
        ___  __ )__(_)___________  _____________  __
        __  __  |_  /___  __ \  / / /__  __ \  / / /
        _  /_/ /_  / __  /_/ / /_/ /__  /_/ / /_/ / 
        /_____/ /_/  _  .___/\__,_/ _  .___/\__,_/  
                    /_/            /_/             
                    
            FastAPI + PostgreSQL + Redis + Celery
FASTAPI_BANNER
        
        # 使用 exec 启动 FastAPI
        exec uv run uvicorn app.main:app --host 0.0.0.0 --port 8000 --workers 3 --timeout-keep-alive 5
        ;;
    *)
        echo "⚠️ Unknown container role: $CONTAINER_ROLE. Executing default command."
        exec "$@"
        ;;
esac