"""数据库初始化数据"""
import asyncio
from sqlalchemy.orm import Session
from app.db.database import get_db
from app.models.user import User
from app.core.security import get_password_hash
from app.core.logging import get_logger

logger = get_logger(__name__)


async def create_default_admin_user(db: Session):
    """创建默认管理员用户"""
    # 检查是否已存在管理员用户
    admin_user = db.query(User).filter(User.username == "admin").first()
    
    if not admin_user:
        logger.info("创建默认管理员用户...")
        admin_user = User(
            email="admin@example.com",
            username="admin",
            full_name="Administrator",
            hashed_password=get_password_hash("admin123"),
            is_active=True,
            is_superuser=True
        )
        db.add(admin_user)
        db.commit()
        logger.info("默认管理员用户创建成功")
    else:
        logger.info("管理员用户已存在，跳过创建")


async def init_default_data():
    """初始化默认数据"""
    logger.info("开始初始化数据库默认数据...")
    
    async for db in get_db():
        try:
            await create_default_admin_user(db)
            logger.info("数据库默认数据初始化完成")
            break
        except Exception as e:
            logger.error(f"数据库初始化失败: {e}")
            raise
        finally:
            db.close()


if __name__ == "__main__":
    asyncio.run(init_default_data())