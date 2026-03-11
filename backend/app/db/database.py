"""PostgreSQL 数据库连接管理模块

独立的数据库连接，与 Redis 分离
"""
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker
from contextlib import asynccontextmanager
from typing import AsyncGenerator
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


async def init_db():
    """初始化数据库"""
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

        # 测试数据库连接
        with engine.connect() as conn:
            conn.execute(text("SELECT 1"))
        
        logger.info("✅ PostgreSQL 连接成功")
        
    except Exception as e:
        logger.error(f"❌ 数据库连接失败：{e}")
        raise
