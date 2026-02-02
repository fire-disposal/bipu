import sys
import time
import psycopg2
import redis
from app.core.config import settings
from app.core.logging import get_logger

logger = get_logger(__name__)

def check_db():
    url = settings.DATABASE_URL
    logger.info(f"正在检查数据库连接...")
    start = time.time()
    while time.time() - start < 30:
        try:
            # 从构建好的 DATABASE_URL 直接连接，无需关心内部字段
            conn = psycopg2.connect(url, connect_timeout=3)
            conn.close()
            logger.info("✅ 数据库连接成功")
            return True
        except Exception as e:
            logger.warning(f"⏳ 数据库等待中: {e}")
            time.sleep(2)
    return False

def check_redis():
    url = settings.REDIS_URL
    logger.info(f"正在检查 Redis 连接...")
    start = time.time()
    while time.time() - start < 30:
        try:
            r = redis.from_url(url, socket_timeout=2)
            if r.ping():
                logger.info("✅ Redis 连接成功")
                return True
        except Exception as e:
            logger.warning(f"⏳ Redis 等待中: {e}")
            time.sleep(2)
    return False

if __name__ == "__main__":
    if check_db() and check_redis():
        sys.exit(0)
    else:
        logger.error("❌ 依赖服务自检失败")
        sys.exit(1)
