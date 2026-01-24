from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool
import redis.asyncio as redis
from app.core.config import settings
from app.core.logging import get_logger

# 使用独立的base模块，避免循环依赖
from app.models.base import Base

logger = get_logger(__name__)

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


async def get_db():
    """获取数据库会话"""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


async def get_redis():
    """获取Redis连接"""
    global redis_client
    if redis_client is None:
        redis_client = redis.from_url(
            settings.REDIS_URL,
            encoding="utf-8",
            decode_responses=True
        )
    return redis_client


async def init_db():
    """初始化数据库"""
    try:
        # 在函数内部导入模型，确保它们被注册到 Base.metadata
        # 这样可以避免循环导入问题
        from app.models import User, AdminLog 
        
        # 创建所有表
        Base.metadata.create_all(bind=engine)
        logger.info("🌳 数据库表创建成功")
    except Exception as e:
        logger.error(f"❌ 创建数据库表时出错: {e}")
        raise


async def init_redis():
    """初始化Redis连接"""
    global redis_client
    try:
        redis_client = redis.from_url(
            settings.REDIS_URL,
            encoding="utf-8",
            decode_responses=True
        )
        # 测试连接
        await redis_client.ping()
        logger.info("Redis connection established successfully")
    except Exception as e:
        logger.error(f"Error connecting to Redis: {e}")
        raise


async def close_redis():
    """关闭Redis连接"""
    global redis_client
    if redis_client:
        await redis_client.close()
        logger.info("Redis connection closed")