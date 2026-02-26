#!/bin/bash
set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}开始启动 bipupu Backend...${NC}"

# ====================================================
# 初始化环境：确保日志目录可访问
# ====================================================
if [ ! -d "/app/logs" ]; then
    mkdir -p /app/logs
fi
# 确保日志目录对当前用户可写
chmod 755 /app/logs

# 依赖服务自检
echo -e "${YELLOW}正在通过应用配置自检依赖服务...${NC}"
uv run python -m app.check_deps || {
    echo -e "${RED}依赖服务自检失败，请检查配置或网络${NC}"
    exit 1
}

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
            exec uv run uvicorn app.main:app --host 0.0.0.0 --port 8000 --workers 3 --timeout-keep-alive 5 --proxy-headers --forwarded-allow-ips '*'
        fi
        ;;
        
    worker)
        if [ -n "$OVERRIDE_CMD" ]; then
            exec $OVERRIDE_CMD
        else
            echo -e "${GREEN}启动Celery Worker...${NC}"
            exec uv run celery -A app.celery worker --loglevel=info -Q default -c 1
        fi
        ;;
        
    beat)
        if [ -n "$OVERRIDE_CMD" ]; then
            exec $OVERRIDE_CMD
        else
            echo -e "${GREEN}启动Celery Beat...${NC}"
            # 使用临时目录避免权限问题
            exec uv run celery -A app.celery beat -l info \
                --pidfile=/tmp/celerybeat.pid \
                --schedule=/tmp/celerybeat-schedule
        fi
        ;;
        
    *)
        echo -e "${RED}未知的容器角色: ${CONTAINER_ROLE}${NC}"
        echo -e "${YELLOW}可用的角色: backend, worker, beat${NC}"
        exit 1
        ;;
esac