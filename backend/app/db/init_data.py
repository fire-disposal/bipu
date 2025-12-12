from sqlalchemy.orm import Session
from app.db.database import SessionLocal
from app.models.user import User
from app.core.logging import get_logger

logger = get_logger(__name__)


def init_data():
    """初始化数据库数据"""
    db = SessionLocal()
    try:
        # 检查是否已有数据
        user_count = db.query(User).count()
        if user_count > 0:
            logger.info("Database already contains data, skipping initialization")
            return
        
        # 创建默认用户
        default_user = User(
            email="admin@example.com",
            username="admin",
            full_name="Administrator",
            is_active=True,
            is_superuser=True
        )
        db.add(default_user)
        db.commit()
        
        logger.info("Default user created successfully")
        
    except Exception as e:
        logger.error(f"Error initializing database data: {e}")
        db.rollback()
        raise
    finally:
        db.close()