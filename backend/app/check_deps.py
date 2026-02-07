import sys
import asyncio
import time
from app.core.config import settings
from app.core.logging import get_logger
from app.db.database import init_db, init_redis, current_db_type

logger = get_logger(__name__)

async def check_db():
    """检查数据库连接和初始化"""
    logger.info("🔍 检查数据库连接...")
    start = time.time()
    while time.time() - start < 30:
        try:
            await init_db()
            db_type = "PostgreSQL" if current_db_type == "postgresql" else "SQLite"
            logger.info(f"✅ 数据库初始化成功 (类型: {db_type})")
            return True
        except Exception as e:
            logger.warning(f"⏳ 数据库初始化等待中: {e}")
            await asyncio.sleep(2)
    return False


async def check_redis():
    """检查Redis连接和初始化"""
    logger.info("🔍 检查Redis连接...")
    start = time.time()
    while time.time() - start < 30:
        try:
            await init_redis()
            logger.info("✅ Redis初始化成功")
            return True
        except Exception as e:
            logger.warning(f"⏳ Redis初始化等待中: {e}")
            await asyncio.sleep(2)
    return False

async def main():
    """主检查函数"""
    if await check_db() and await check_redis():
        logger.info("🎉 所有依赖服务检查通过")
        return True
    else:
        logger.error("❌ 依赖服务自检失败")
        return False


if __name__ == "__main__":
    success = asyncio.run(main())
    sys.exit(0 if success else 1)
