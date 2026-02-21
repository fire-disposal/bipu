"""数据库初始化数据（最小化，仅创建默认管理员和服务号）"""
import asyncio
from sqlalchemy.orm import Session
from datetime import time
from app.models.user import User
from app.models.service_account import ServiceAccount
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
    """创建默认服务号（幂等性保证）"""
    # 内置服务号配置 - 包含默认推送时间
    services = [
        {
            "name": "weather.service",
            "description": "每日天气预报推送服务",
            "default_push_time": time(9, 0),  # 默认早上9点
            "is_active": True
        },
        {
            "name": "cosmic.fortune",
            "description": "每日运势推送服务",
            "default_push_time": time(9, 0),  # 默认早上9点
            "is_active": True
        }
    ]

    for svc_config in services:
        service_name = svc_config["name"]

        # 检查服务号是否已存在
        existing_service = db.query(ServiceAccount).filter(
            ServiceAccount.name == service_name
        ).first()

        if existing_service:
            # 更新现有服务号（幂等性保证）
            update_needed = False

            # 检查是否需要更新描述
            if svc_config.get("description") and existing_service.description != svc_config["description"]:
                existing_service.description = svc_config["description"]
                update_needed = True

            # 检查是否需要更新默认推送时间
            if svc_config.get("default_push_time") and existing_service.default_push_time != svc_config["default_push_time"]:
                existing_service.default_push_time = svc_config["default_push_time"]
                update_needed = True

            # 检查是否需要更新激活状态
            if "is_active" in svc_config and existing_service.is_active != svc_config["is_active"]:
                existing_service.is_active = svc_config["is_active"]
                update_needed = True

            if update_needed:
                db.add(existing_service)
                logger.info(f"更新服务号: {service_name}")
            else:
                logger.debug(f"服务号已存在且无需更新: {service_name}")
        else:
            # 创建新服务号
            new_service = ServiceAccount(
                name=service_name,
                description=svc_config.get("description"),
                default_push_time=svc_config.get("default_push_time"),
                is_active=svc_config.get("is_active", True)
            )
            db.add(new_service)
            logger.info(f"创建服务号: {service_name}")

    try:
        db.commit()
        logger.info("默认服务号初始化完成")
    except Exception as e:
        db.rollback()
        logger.error(f"创建默认服务号失败: {e}")
        # 不抛出异常，保证初始化不因服务号创建失败而中断

async def init_default_data():
    """初始化默认数据（幂等性保证）"""
    logger.info("开始初始化数据库默认数据...")

    # 动态导入SessionLocal，确保使用最新的数据库配置
    from app.db.database import SessionLocal

    db = SessionLocal()
    try:
        # 创建默认管理员用户（幂等性）
        await create_default_admin_user(db)

        # 创建默认服务号（幂等性）
        await create_default_services(db)

        logger.info("✅ 数据库默认数据初始化完成")
    except Exception as e:
        logger.error(f"❌ 数据库初始化失败: {e}")
        # 不抛出异常，保证应用启动不因初始化失败而中断
        # 记录错误但继续启动
    finally:
        db.close()


if __name__ == "__main__":
    asyncio.run(init_default_data())
