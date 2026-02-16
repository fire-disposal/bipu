from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool
import redis.asyncio as redis
from app.core.config import settings
from app.core.logging import get_logger

# 使用独立的base模块，避免循环依赖
from app.models.base import Base

logger = get_logger(__name__)

# 全局变量用于存储当前使用的数据库类型
current_db_type = "unknown"
fallback_used = False

# 创建SQLAlchemy引擎
connect_args = {}
if settings.DATABASE_URL.startswith("sqlite"):
    connect_args = {"check_same_thread": False}

engine = create_engine(
    settings.DATABASE_URL,
    poolclass=StaticPool,
    pool_pre_ping=True,
    echo=False,  # 强制关闭 SQLAlchemy 的 SQL 日志输出
    connect_args=connect_args,
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
    """初始化数据库，支持自动回退到SQLite"""
    global current_db_type, fallback_used, engine, SessionLocal
    
    try:
        # 首先尝试PostgreSQL
        if not settings.DATABASE_URL.startswith("sqlite"):
            logger.info("🐘 尝试连接 PostgreSQL...")
            # 测试连接
            with engine.connect() as conn:
                conn.execute(text("SELECT 1"))
            
            current_db_type = "postgresql"
            logger.info("✅ PostgreSQL连接成功")
        else:
            current_db_type = "sqlite"
            logger.info("🗄️ 使用 SQLite 数据库")
        
        # 在函数内部导入模型，确保它们被注册到 Base.metadata
        # 这样可以避免循环导入问题
        from app.models import User 
        
        # 创建所有表
        Base.metadata.create_all(bind=engine)
        logger.info("🌳 数据库表创建成功")
        
    except Exception as e:
        if not fallback_used and not settings.DATABASE_URL.startswith("sqlite"):
            logger.warning(f"❌ PostgreSQL连接失败，尝试回退到SQLite: {e}")
            fallback_used = True
            
            # 重新配置为SQLite
            sqlite_url = f"sqlite:///{settings.SQLITE_DB_PATH}"
            logger.info(f"🗄️ 回退到 SQLite: {sqlite_url}")
            
            # 重新创建引擎
            engine = create_engine(
                sqlite_url,
                poolclass=StaticPool,
                pool_pre_ping=True,
                echo=False,
                connect_args={"check_same_thread": False},
            )
            
            # 重新创建SessionLocal
            SessionLocal = sessionmaker(
                autocommit=False,
                autoflush=False,
                bind=engine
            )
            
            current_db_type = "sqlite"
            
            try:
                # 创建所有表
                Base.metadata.create_all(bind=engine)
                logger.info("🌳 SQLite数据库表创建成功")
            except Exception as sqlite_e:
                logger.error(f"❌ SQLite数据库初始化失败: {sqlite_e}")
                raise
        else:
            logger.error(f"❌ 创建数据库表时出错: {e}")
            raise


async def init_redis():
    """初始化Redis连接，支持内存缓存fallback"""
    global redis_client
    
    try:
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
        # 不抛出异常，让应用继续运行
        redis_client = MemoryCacheWrapper()
        logger.info("✅ 已启用内存缓存作为Redis替代方案")


async def get_redis_client():
    """获取Redis客户端，支持自动回退到内存缓存"""
    global redis_client
    if redis_client is None:
        await init_redis()
    return redis_client