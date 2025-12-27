"""数据库初始化数据"""
import asyncio
from sqlalchemy.orm import Session
from app.db.database import SessionLocal
from app.models.user import User
from app.models.subscription import SubscriptionType, UserSubscription
from app.core.security import get_password_hash
from app.core.logging import get_logger

logger = get_logger(__name__)


async def create_default_admin_user(db: Session):
    """创建默认管理员用户（支持环境变量注入）"""
    import os
    admin_email = os.getenv("ADMIN_EMAIL", "adminemail@qq.com")
    admin_password = os.getenv("ADMIN_PASSWORD", "admin123")[:72]
    admin_username = os.getenv("ADMIN_USERNAME", "admin")
    admin_full_name = os.getenv("ADMIN_FULL_NAME", "Administrator")
    # 检查是否已存在管理员用户
    admin_user = db.query(User).filter(User.username == admin_username).first()
    
    if not admin_user:
        logger.info("创建默认管理员用户...")
        admin_user = User(
            email=admin_email,
            username=admin_username,
            full_name=admin_full_name,
            hashed_password=get_password_hash(admin_password),
            is_active=True,
            is_superuser=True
        )
        db.add(admin_user)
        db.commit()
        logger.info(f"默认管理员用户创建成功: {admin_email}")
    else:
        logger.info("管理员用户已存在，跳过创建")


async def create_default_subscription_types(db: Session):
    """创建默认订阅类型"""
    default_subscriptions = [
        {
            "name": "天气推送",
            "description": "每日天气信息推送，包含温度、湿度、风速等详细信息",
            "category": "weather",
            "default_settings": {
                "frequency": "daily",
                "time": "08:00",
                "include_details": True
            }
        },
        {
            "name": "今日运势",
            "description": "基于星座和生辰八字的个性化运势分析",
            "category": "fortune",
            "default_settings": {
                "frequency": "daily",
                "time": "09:00",
                "include_lucky_info": True
            }
        },
        {
            "name": "宇宙传讯",
            "description": "接收宇宙能量信息和灵性指导",
            "category": "cosmic_messaging",
            "default_settings": {
                "frequency": "daily",
                "time": "10:00",
                "include_energy_readings": True
            }
        },
        {
            "name": "系统通知",
            "description": "系统重要通知和更新信息",
            "category": "system",
            "default_settings": {
                "frequency": "as_needed",
                "priority": "high"
            }
        }
    ]
    
    for sub_data in default_subscriptions:
        existing = db.query(SubscriptionType).filter(
            SubscriptionType.name == sub_data["name"]
        ).first()
        
        if not existing:
            logger.info(f"创建订阅类型: {sub_data['name']}")
            subscription_type = SubscriptionType(
                name=sub_data["name"],
                description=sub_data["description"],
                category=sub_data["category"],
                default_settings=sub_data["default_settings"]
            )
            db.add(subscription_type)
    
    db.commit()
    logger.info("默认订阅类型创建完成")


async def create_default_user_subscriptions(db: Session):
    """为所有用户创建默认订阅"""
    users = db.query(User).all()
    subscription_types = db.query(SubscriptionType).all()
    
    for user in users:
        for sub_type in subscription_types:
            # 检查是否已存在订阅
            existing = db.query(UserSubscription).filter(
                UserSubscription.user_id == user.id,
                UserSubscription.subscription_type_id == sub_type.id
            ).first()
            
            if not existing:
                logger.info(f"为用户 {user.username} 创建订阅: {sub_type.name}")
                user_subscription = UserSubscription(
                    user_id=user.id,
                    subscription_type_id=sub_type.id,
                    is_enabled=True,
                    custom_settings=sub_type.default_settings or {},
                    notification_time_start="08:00",
                    notification_time_end="22:00",
                    timezone="Asia/Shanghai"
                )
                db.add(user_subscription)
    
    db.commit()
    logger.info("默认用户订阅创建完成")


async def init_default_data():
    """初始化默认数据"""
    logger.info("开始初始化数据库默认数据...")
    
    db = SessionLocal()
    try:
        await create_default_admin_user(db)
        await create_default_subscription_types(db)
        await create_default_user_subscriptions(db)
        logger.info("数据库默认数据初始化完成")
    except Exception as e:
        logger.error(f"数据库初始化失败: {e}")
        db.rollback()
        raise
    finally:
        db.close()


if __name__ == "__main__":
    asyncio.run(init_default_data())