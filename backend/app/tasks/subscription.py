"""订阅相关任务"""
from datetime import datetime, timedelta
from celery import shared_task
from app.db.database import SessionLocal
from app.models.subscription import UserSubscription, SubscriptionType
from app.models.message import Message, MessageType
from app.core.logging import get_logger
from app.services.subscriptions.manager import SubscriptionManager

logger = get_logger(__name__)

@shared_task
def generate_weather_subscription():
    """生成天气订阅消息"""
    return _process_subscription_task("weather")

@shared_task
def generate_fortune_subscription():
    """生成今日运势订阅消息"""
    return _process_subscription_task("fortune")

def _process_subscription_task(category: str):
    """处理特定类型的订阅任务通用逻辑"""
    db = None
    try:
        db = SessionLocal()
        
        # 1. 获取该类型的所有启用订阅
        subscriptions = db.query(UserSubscription).join(
            SubscriptionType,
            UserSubscription.subscription_type_id == SubscriptionType.id
        ).filter(
            SubscriptionType.category == category,
            UserSubscription.is_enabled == True
        ).all()
        
        if not subscriptions:
            logger.info(f"没有启用的 {category} 订阅")
            return {"created_count": 0}
        
        # 2. 使用管理器处理
        manager = SubscriptionManager()
        result = manager.process_subscriptions(subscriptions, db)
        
        logger.info(f"{category} 订阅消息生成完成: 创建了 {result['created_count']} 条消息")
        return result
        
    except Exception as e:
        logger.error(f"生成 {category} 订阅消息失败: {e}")
        raise
    finally:
        if db:
            db.close()

@shared_task
def cleanup_old_subscription_messages():
    """清理旧的订阅消息"""
    db = None
    try:
        db = SessionLocal()
        
        # 删除7天前的订阅消息
        cutoff_date = datetime.utcnow() - timedelta(days=7)
        
        deleted_count = db.query(Message).filter(
            Message.message_type == MessageType.NOTIFICATION,
            Message.created_at < cutoff_date,
            Message.pattern.contains({"source_type": "subscription"})
        ).delete(synchronize_session=False)
        
        db.commit()
        logger.info(f"清理了 {deleted_count} 条旧订阅消息")
        return {"deleted_count": deleted_count}
    except Exception as e:
        logger.error(f"清理旧订阅消息失败: {e}")
        raise
    finally:
        if db:
            db.close()