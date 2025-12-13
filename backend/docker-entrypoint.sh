#!/bin/bash
set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}开始启动 Bipupu Backend...${NC}"

# 等待数据库就绪
echo -e "${YELLOW}等待数据库连接...${NC}"
timeout 60 bash -c 'until pg_isready -h db -p 5432 -U postgres; do sleep 1; done' || {
    echo -e "${RED}数据库连接失败${NC}"
    exit 1
}
echo -e "${GREEN}数据库连接成功${NC}"

# 等待Redis就绪
echo -e "${YELLOW}等待Redis连接...${NC}"
timeout 60 bash -c 'until redis-cli -h redis -p 6379 -a ${REDIS_PASSWORD} ping; do sleep 1; done' || {
    echo -e "${RED}Redis连接失败${NC}"
    exit 1
}
echo -e "${GREEN}Redis连接成功${NC}"

# 根据容器角色执行不同操作
case "${CONTAINER_ROLE:-backend}" in
    backend)
        echo -e "${YELLOW}运行数据库迁移...${NC}"
        uv run alembic upgrade head || {
            echo -e "${RED}数据库迁移失败${NC}"
            exit 1
        }
        echo -e "${GREEN}数据库迁移完成${NC}"

        echo -e "${YELLOW}初始化数据库数据...${NC}"
        uv run python -c "
import asyncio
from app.db.init_data import init_default_data
asyncio.run(init_default_data())
" || {
            echo -e "${YELLOW}数据库初始化跳过（可能没有初始化脚本）${NC}"
        }
        
        echo -e "${GREEN}启动FastAPI应用...${NC}"
        exec uv run uvicorn app.main:app --host 0.0.0.0 --port 8000 --workers 3 --timeout-keep-alive 5
        ;;
        
    worker)
        echo -e "${GREEN}启动Celery Worker...${NC}"
        exec uv run celery -A app.celery worker --loglevel=info -Q default -c 4
        ;;
        
    beat)
        echo -e "${GREEN}启动Celery Beat...${NC}"
        exec uv run celery -A app.celery beat -l info --pidfile=/app/logs/celerybeat.pid --schedule=/app/logs/celerybeat-schedule
        ;;
        
    *)
        echo -e "${RED}未知的容器角色: ${CONTAINER_ROLE}${NC}"
        echo -e "${YELLOW}可用的角色: backend, worker, beat${NC}"
        exit 1
        ;;
esac