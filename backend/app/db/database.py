from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker
import redis.asyncio as redis
from app.core.config import settings
from app.core.logging import get_logger

# 使用独立的base模块，避免循环依赖
from app.models.base import Base

logger = get_logger(__name__)

# 创建SQLAlchemy引擎
engine = create_engine(
    settings.DATABASE_URL,
    pool_size=20,
    max_overflow=30,
    pool_pre_ping=True,
    echo=False,  # 强制关闭 SQLAlchemy 的 SQL 日志输出
)

# 创建SessionLocal类
SessionLocal = sessionmaker(
    autocommit=False,
    autoflush=False,
    bind=engine
)


# Redis连接池
redis_client = None
memory_cache = {}  # 内存缓存作为Redis的fallback


async def get_db():
    """获取数据库会话"""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


async def get_redis():
    """获取Redis连接，如果失败则使用内存缓存"""
    global redis_client
    if redis_client is None:
        try:
            redis_client = redis.from_url(
                settings.REDIS_URL,
                encoding="utf-8",
                decode_responses=True
            )
            # 测试连接
            await redis_client.ping()
            logger.info("✅ Redis连接成功")
            return redis_client
        except Exception as e:
            logger.warning(f"⚠️ Redis连接失败，使用内存缓存: {e}")
            # 返回内存缓存包装器
            return MemoryCacheWrapper()
    return redis_client


class MemoryCacheWrapper:
    """内存缓存包装器，模拟Redis接口"""

    async def get(self, key):
        return memory_cache.get(key)

    async def set(self, key, value, ex=None):
        memory_cache[key] = value
        # 简单的过期机制（实际项目中可以改进）
        if ex:
            import asyncio
            async def expire():
                await asyncio.sleep(ex)
                memory_cache.pop(key, None)
            asyncio.create_task(expire())
        return True

    async def delete(self, key):
        return memory_cache.pop(key, None) is not None

    async def exists(self, key):
        return key in memory_cache

    async def expire(self, key, time):
        # 简单的过期实现
        if key in memory_cache:
            import asyncio
            async def expire():
                await asyncio.sleep(time)
                memory_cache.pop(key, None)
            asyncio.create_task(expire())
            return True
        return False

    async def ttl(self, key):
        # 内存缓存不支持TTL，返回-1
        return -1 if key in memory_cache else -2

    async def ping(self):
        return True

    async def incr(self, key):
        current = int(memory_cache.get(key, 0))
        memory_cache[key] = current + 1
        return current + 1

    async def close(self):
        pass


async def init_db():
    """初始化数据库"""
    global engine, SessionLocal

    try:
        # 打印数据库连接信息（不含密码）
        db_url = str(engine.url)
        # 隐藏密码信息
        if "@" in db_url:
            # 格式: postgresql://user:password@host:port/dbname
            parts = db_url.split("@")
            auth_part = parts[0]
            if "://" in auth_part:
                protocol = auth_part.split("://")[0] + "://"
                credentials = auth_part.split("://")[1]
                if ":" in credentials:
                    user = credentials.split(":")[0]
                    # 隐藏密码，只显示用户名
                    safe_auth = f"{protocol}{user}:******"
                else:
                    safe_auth = auth_part
            else:
                safe_auth = auth_part
            safe_db_url = f"{safe_auth}@{parts[1]}"
        else:
            safe_db_url = db_url

        logger.info(f"🐘 尝试连接 PostgreSQL: {safe_db_url}")

        # 测试连接
        with engine.connect() as conn:
            conn.execute(text("SELECT 1"))

        logger.info("✅ PostgreSQL连接成功")

        # 在函数内部导入模型，确保它们被注册到 Base.metadata
        # 这样可以避免循环导入问题
        from app.models import User

        logger.info("🌳 数据库连接成功")

    except Exception as e:
        logger.error(f"❌ PostgreSQL数据库初始化失败: {e}")
        raise


async def init_redis():
    """初始化Redis连接"""
    global redis_client

    try:
        # 打印Redis连接信息（不含密码）
        redis_url = settings.REDIS_URL
        # 隐藏密码信息
        if "://" in redis_url:
            protocol = redis_url.split("://")[0] + "://"
            rest = redis_url.split("://")[1]
            if "@" in rest:
                # 有密码: redis://:password@host:port/db
                auth_part = rest.split("@")[0]
                if auth_part.startswith(":"):
                    # 有密码无用户名
                    safe_rest = f":******@{rest.split('@')[1]}"
                else:
                    safe_rest = rest
            else:
                safe_rest = rest
            safe_redis_url = f"{protocol}{safe_rest}"
        else:
            safe_redis_url = redis_url

        logger.info(f"🔗 尝试连接 Redis: {safe_redis_url}")

        redis_client = redis.from_url(
            settings.REDIS_URL,
            encoding="utf-8",
            decode_responses=True
        )
        # 测试连接
        await redis_client.ping()
        logger.info("✅ Redis连接成功")
    except Exception as e:
        logger.warning(f"⚠️ Redis连接失败，使用内存缓存: {e}")
        # 使用内存缓存作为fallback
        redis_client = MemoryCacheWrapper()


async def get_redis_client():
    """获取Redis客户端"""
    global redis_client
    if redis_client is None:
        await init_redis()
    return redis_client
