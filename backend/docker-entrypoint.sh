#!/bin/bash
set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}开始启动 bipupu Backend...${NC}"

# 设置默认值
DB_HOST=${POSTGRES_SERVER:-db}
DB_PORT=${POSTGRES_PORT:-5432}
DB_USER=${POSTGRES_USER:-postgres}
REDIS_HOST=${REDIS_HOST:-redis}
REDIS_PORT=${REDIS_PORT:-6379}

# 等待数据库就绪
echo -e "${YELLOW}等待数据库连接 (${DB_HOST}:${DB_PORT})...${NC}"
uv run python -c "
import sys, time, psycopg2, os
host = os.getenv('POSTGRES_SERVER', 'db')
port = os.getenv('POSTGRES_PORT', '5432')
user = os.getenv('POSTGRES_USER', 'postgres')
password = os.getenv('POSTGRES_PASSWORD', 'postgres')
dbname = os.getenv('POSTGRES_DB', 'bipupu')

start = time.time()
while time.time() - start < 60:
    try:
        conn = psycopg2.connect(host=host, port=port, user=user, password=password, dbname=dbname)
        conn.close()
        sys.exit(0)
    except Exception:
        time.sleep(1)
sys.exit(1)
" || {
    echo -e "${RED}数据库连接失败${NC}"
    exit 1
}
echo -e "${GREEN}数据库连接成功${NC}"

# 等待Redis就绪
echo -e "${YELLOW}等待Redis连接 (${REDIS_HOST}:${REDIS_PORT})...${NC}"
uv run python -c "
import sys, time, redis, os
host = os.getenv('REDIS_HOST', 'redis')
port = int(os.getenv('REDIS_PORT', '6379'))
password = os.getenv('REDIS_PASSWORD') or None

start = time.time()
while time.time() - start < 60:
    try:
        r = redis.Redis(host=host, port=port, password=password, socket_timeout=1)
        if r.ping():
            sys.exit(0)
    except Exception:
        time.sleep(1)
sys.exit(1)
" || {
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
        
        if [ -n "$OVERRIDE_CMD" ]; then
            exec $OVERRIDE_CMD
        else
            echo -e "${GREEN}启动FastAPI应用...${NC}"
            exec uv run uvicorn app.main:app --host 0.0.0.0 --port 8000 --workers 3 --timeout-keep-alive 5
        fi
        ;;
        
    worker)
        if [ -n "$OVERRIDE_CMD" ]; then
            exec $OVERRIDE_CMD
        else
            echo -e "${GREEN}启动Celery Worker...${NC}"
            exec uv run celery -A app.celery worker --loglevel=info -Q default -c 4
        fi
        ;;
        
    beat)
        if [ -n "$OVERRIDE_CMD" ]; then
            exec $OVERRIDE_CMD
        else
            echo -e "${GREEN}启动Celery Beat...${NC}"
            exec uv run celery -A app.celery beat -l info --pidfile=/app/logs/celerybeat.pid --schedule=/app/logs/celerybeat-schedule
        fi
        ;;
        
    *)
        echo -e "${RED}未知的容器角色: ${CONTAINER_ROLE}${NC}"
        echo -e "${YELLOW}可用的角色: backend, worker, beat${NC}"
        exit 1
        ;;
esac