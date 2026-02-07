"""数据库初始化数据（最小化，仅创建默认管理员）"""
import asyncio
from sqlalchemy.orm import Session
from app.models.user import User
from app.models.subscription import SubscriptionType
from app.core.security import get_password_hash
from app.core.logging import get_logger
from app.core.config import settings

logger = get_logger(__name__)


async def create_default_subscription_types(db: Session):
    """创建默认订阅类型"""
    default_types = [
        {
            "name": "天气推送",
            "category": "weather",
            "description": "每日天气预报推送",
            "default_settings": {"city": "北京"}
        },
        {
            "name": "今日运势",
            "category": "fortune",
            "description": "每日星座运势推送",
            "default_settings": {"zodiac": "白羊座"}
        }
    ]
    
    for subtype in default_types:
        existing = db.query(SubscriptionType).filter(
            SubscriptionType.category == subtype["category"]
        ).first()
        
        if not existing:
            logger.info(f"创建订阅类型: {subtype['name']}")
            new_type = SubscriptionType(
                name=subtype["name"],
                category=subtype["category"],
                description=subtype["description"],
                default_settings=subtype["default_settings"],
                is_active=True
            )
            db.add(new_type)
        else:
            # Optional: Ensure name/description are up to date if needed, but skipping for now
            pass
            
    db.commit()


async def create_default_admin_user(db: Session):
    """创建默认管理员用户（支持环境变量注入）"""
    admin_email = settings.ADMIN_EMAIL
    admin_password = settings.ADMIN_PASSWORD[:72]
    admin_username = settings.ADMIN_USERNAME
    # 检查是否已存在管理员用户
    admin_user = db.query(User).filter(User.username == admin_username).first()
    
    if not admin_user:
        logger.info("创建默认管理员用户...")
        admin_user = User(
            email=admin_email,
            username=admin_username,
            hashed_password=get_password_hash(admin_password),
            is_active=True,
            is_superuser=True
        )
        db.add(admin_user)
        db.commit()
        logger.info(f"默认管理员用户创建成功: {admin_email}")
    else:
        logger.info("管理员用户已存在，跳过创建")


async def init_default_data():
    """初始化默认数据"""
    logger.info("开始初始化数据库默认数据...")
    
    # 动态导入SessionLocal，确保使用最新的数据库配置
    from app.db.database import SessionLocal
    
    db = SessionLocal()
    try:
        await create_default_admin_user(db)
        await create_default_subscription_types(db)
        logger.info("数据库默认数据初始化完成")
    except Exception as e:
        logger.error(f"数据库初始化失败: {e}")
        db.rollback()
        raise
    finally:
        db.close()


if __name__ == "__main__":
    asyncio.run(init_default_data())