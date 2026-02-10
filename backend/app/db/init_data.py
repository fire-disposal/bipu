"""数据库初始化数据（最小化，仅创建默认管理员）"""
import asyncio
from sqlalchemy.orm import Session
from app.models.user import User
from app.core.security import get_password_hash
from app.core.logging import get_logger
from app.core.config import settings

logger = get_logger(__name__)


async def create_default_admin_user(db: Session):
    """创建默认管理员用户（支持环境变量注入）"""
    admin_password = settings.ADMIN_PASSWORD[:72]
    admin_username = settings.ADMIN_USERNAME
    # 检查是否已存在管理员用户
    admin_user = db.query(User).filter(User.username == admin_username).first()
    
    if not admin_user:
        logger.info("创建默认管理员用户...")
        from app.core.user_utils import generate_bipupu_id
        bipupu_id = generate_bipupu_id(db)
        
        admin_user = User(
            username=admin_username,
            bipupu_id=bipupu_id,
            hashed_password=get_password_hash(admin_password),
            is_active=True,
            is_superuser=True
        )
        db.add(admin_user)
        db.commit()
        db.refresh(admin_user)
        logger.info(f"默认管理员用户创建成功: username={admin_username} (bipupu_id: {bipupu_id})")
    else:
        logger.info("管理员用户已存在，跳过创建")


async def create_default_services(db: Session):
    """创建默认服务号"""
    from app.models.service_account import ServiceAccount
    
    services = [
        {
            "name": "weather.service",
            "description": "提供每日天气预报服务",
            "is_active": True
        },
        {
            "name": "cosmic.fortune",
            "description": "提供每日运势解读",
            "is_active": True
        }
    ]
    
    for svc in services:
        existing = db.query(ServiceAccount).filter(ServiceAccount.name == svc["name"]).first()
        if not existing:
            new_svc = ServiceAccount(
                name=svc["name"],
                description=svc["description"],
                is_active=svc["is_active"]
            )
            db.add(new_svc)
            logger.info(f"Created service account: {svc['name']}")
    
    db.commit()

async def init_default_data():
    """初始化默认数据"""
    logger.info("开始初始化数据库默认数据...")
    
    # 动态导入SessionLocal，确保使用最新的数据库配置
    from app.db.database import SessionLocal
    
    db = SessionLocal()
    try:
        await create_default_admin_user(db)
        await create_default_services(db)
        logger.info("数据库默认数据初始化完成")
    except Exception as e:
        logger.error(f"数据库初始化失败: {e}")
        db.rollback()
        raise
    finally:
        db.close()


if __name__ == "__main__":
    asyncio.run(init_default_data())