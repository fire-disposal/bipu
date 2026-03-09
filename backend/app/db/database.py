from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker
from contextlib import asynccontextmanager
from typing import AsyncGenerator, Dict, Any, Optional
import redis.asyncio as redis
import asyncio
import time
from app.core.config import settings
from app.core.logging import get_logger
from app.models.base import Base

logger = get_logger(__name__)

# ========== 数据库连接池配置（1C1G 优化） ==========
engine = create_engine(
    settings.DATABASE_URL,
    pool_size=settings.DB_POOL_SIZE,           # 5 → 节省内存
    max_overflow=settings.DB_MAX_OVERFLOW,     # 10 → 节省内存
    pool_pre_ping=True,                        # 检查连接有效性
    pool_recycle=settings.DB_POOL_RECYCLE,     # 1800 秒 = 30 分钟
    pool_timeout=settings.DB_POOL_TIMEOUT,     # 10 秒快速失败
    echo=False,                                # 关闭 SQL 日志
)

SessionLocal = sessionmaker(
    autocommit=False,
    autoflush=False,
    bind=engine
)


# ========== 统一依赖注入（1C1G 优化版） ==========
@asynccontextmanager
async def get_db_context() -> AsyncGenerator:
    """
    统一数据库会话上下文管理器
    
    用法：
        async with get_db_context() as db:
            users = db.query(User).all()
    
    优势：
    - 自动提交/回滚
    - 自动关闭连接
    - 异常安全
    - 内存占用低（使用后立即释放）
    """
    db = SessionLocal()
    try:
        yield db
        db.commit()
    except Exception:
        db.rollback()
        raise
    finally:
        db.close()


async def get_db():
    """FastAPI 依赖注入版本 - 使用上下文管理器"""
    async with get_db_context() as db:
        yield db


async def query_messages_for_user(
    user_bipupu_id: str,
    last_msg_id: int,
    limit: int = 20
) -> list:
    """
    轻量级消息查询函数 - 用于长轮询
    
    优势：
    - 快速申请/释放连接（占用时间 < 100ms）
    - 不持有会话状态
    - 内存占用极低
    - 立即序列化（避免持有 ORM 对象）
    """
    async with get_db_context() as db:
        from app.models.message import Message
        
        messages = db.query(Message).filter(
            Message.receiver_bipupu_id == user_bipupu_id,
            Message.id > last_msg_id
        ).order_by(Message.id.asc()).limit(limit).all()
        
        # 立即序列化后返回（避免持有 ORM 对象，节省内存）
        return [
            {
                'id': msg.id,
                'sender_bipupu_id': msg.sender_bipupu_id,
                'receiver_bipupu_id': msg.receiver_bipupu_id,
                'content': msg.content,
                'message_type': msg.message_type,
                'created_at': msg.created_at.isoformat(),
                'pattern': msg.pattern,
                'waveform': msg.waveform,
            }
            for msg in messages
        ]


# ========== Redis 连接（1C1G 优化版） ==========
redis_client = None
_redis_init_lock = asyncio.Lock()  # 🔒 异步锁，防止竞态条件


async def get_redis():
    """
    获取 Redis 客户端 - 1C1G 轻量化版本
    
    优化点：
    1. 使用 asyncio.Lock 避免竞态条件
    2. 连接参数最小化（减少内存占用）
    3. Redis 失败时优雅降级到内存缓存
    4. 双重检查锁定模式
    """
    global redis_client
    
    # 快速路径：已初始化
    if redis_client is not None:
        return redis_client
    
    # 慢速路径：需要初始化
    async with _redis_init_lock:
        # 第二次检查（防止重复初始化）
        if redis_client is not None:
            return redis_client
        
        try:
            # 1C1G 轻量化配置
            redis_client = redis.Redis.from_url(
                settings.REDIS_URL,
                encoding="utf-8",
                decode_responses=True,
                # 🔧 关键优化：减少连接池大小
                max_connections=settings.REDIS_MAX_CONNECTIONS,  # 10
                # 🔧 快速失败（避免长时间阻塞）
                socket_connect_timeout=settings.REDIS_SOCKET_TIMEOUT,  # 3 秒
                socket_timeout=settings.REDIS_SOCKET_TIMEOUT,
                # 🔧 简化重试（1C1G 下快速失败更好）
                retry_on_timeout=False,
            )
            
            # 测试连接（ping() 返回布尔值，不是协程）
            result = redis_client.ping()
            if asyncio.iscoroutine(result):
                await result
            
            logger.info("✅ Redis 连接成功")
            return redis_client
            
        except Exception as e:
            logger.warning(f"⚠️ Redis 连接失败，使用内存缓存：{e}")
            redis_client = MemoryCacheWrapper()
            return redis_client


# ========== 线程安全的内存缓存（1C1G 轻量化） ==========
class MemoryCacheWrapper:
    """
    1C1G 轻量化内存缓存 - 线程安全版本
    
    优化点：
    1. 使用 asyncio.Lock 保护并发访问
    2. 集中过期检查（不创建定时任务）
    3. 极简实现（代码量 < 150 行）
    4. 惰性清理（访问时检查过期）
    """
    
    def __init__(self):
        self._cache: Dict[str, Any] = {}
        self._expiry: Dict[str, float] = {}  # key → 过期时间戳
        self._lock = asyncio.Lock()
    
    async def get(self, key: str) -> Optional[Any]:
        """获取缓存值，自动检查过期"""
        async with self._lock:
            # 检查是否过期
            if key in self._expiry:
                if time.time() > self._expiry[key]:
                    # 已过期，清理
                    del self._cache[key]
                    del self._expiry[key]
                    return None
            
            return self._cache.get(key)
    
    async def set(self, key: str, value: Any, ex: Optional[int] = None) -> bool:
        """设置缓存值，支持过期时间"""
        async with self._lock:
            self._cache[key] = value
            
            if ex:
                self._expiry[key] = time.time() + ex
            elif key in self._expiry:
                # 移除过期时间
                del self._expiry[key]
            
            return True
    
    async def setex(self, key: str, expire: int, value: Any) -> bool:
        """Redis 兼容接口：设置键值并指定过期时间（秒）"""
        return await self.set(key, value, ex=expire)
    
    async def delete(self, *keys: str) -> int:
        """删除一个或多个键"""
        async with self._lock:
            count = 0
            for key in keys:
                if key in self._cache:
                    del self._cache[key]
                    if key in self._expiry:
                        del self._expiry[key]
                    count += 1
            return count
    
    async def exists(self, key: str) -> bool:
        """检查键是否存在"""
        async with self._lock:
            return key in self._cache
    
    async def incr(self, key: str) -> int:
        """原子自增"""
        async with self._lock:
            current = int(self._cache.get(key, 0))
            self._cache[key] = current + 1
            return current + 1
    
    async def publish(self, channel: str, message: str) -> int:
        """发布消息到频道（内存缓存中模拟）"""
        logger.debug(f"MemoryCache: 发布到 {channel}（模拟）")
        return 1
    
    async def scan(self, cursor: int, match: Optional[str] = None, count: Optional[int] = None):
        """SCAN 兼容接口（返回所有匹配键）"""
        async with self._lock:
            keys = list(self._cache.keys())
            
            if match:
                import fnmatch
                keys = [k for k in keys if fnmatch.fnmatch(k, match)]
            
            # 1C1G 下数据量小，简单返回所有结果
            return 0, keys
    
    async def ttl(self, key: str) -> int:
        """获取键的剩余生存时间（秒）"""
        async with self._lock:
            if key not in self._cache:
                return -2  # 不存在
            
            if key not in self._expiry:
                return -1  # 永不过期
            
            remaining = int(self._expiry[key] - time.time())
            return max(0, remaining)
    
    async def expire(self, key: str, time_seconds: int) -> bool:
        """设置键的过期时间"""
        async with self._lock:
            if key in self._cache:
                self._expiry[key] = time.time() + time_seconds
                return True
            return False
    
    async def close(self):
        """关闭连接，清理缓存"""
        async with self._lock:
            self._cache.clear()
            self._expiry.clear()


# ========== 数据库初始化 ==========
async def init_db():
    """初始化数据库"""
    global engine, SessionLocal

    try:
        # 打印数据库连接信息（不含密码）
        db_url = str(engine.url)
        # 隐藏密码信息
        if "@" in db_url:
            parts = db_url.split("@")
            auth_part = parts[0]
            if "://" in auth_part:
                protocol = auth_part.split("://")[0] + "://"
                credentials = auth_part.split("://")[1]
                if ":" in credentials:
                    user = credentials.split(":")[0]
                    safe_auth = f"{protocol}{user}:******"
                else:
                    safe_auth = auth_part
            else:
                safe_auth = auth_part
            safe_db_url = f"{safe_auth}@{parts[1]}"
        else:
            safe_db_url = db_url

        logger.info(f"🐘 尝试连接 PostgreSQL: {safe_db_url}")

        # 测试连接（ping() 返回布尔值）
        result = redis_client.ping()
        if asyncio.iscoroutine(result):
            await result
        
        logger.info("✅ Redis 连接成功")
        
    except Exception as e:
        logger.warning(f"⚠️ Redis 连接失败，使用内存缓存：{e}")
        redis_client = MemoryCacheWrapper()


async def get_redis_client():
    """获取 Redis 客户端"""
    global redis_client
    if redis_client is None:
        await init_redis()
    return redis_client
