"""订阅相关任务 - 天气推送和今日运势"""
from datetime import datetime, timedelta
from celery import shared_task
from app.db.database import SessionLocal
from app.models.subscription import UserSubscription, SubscriptionType
from app.models.message import Message, MessageType
from app.core.logging import get_logger
from app.tasks.subscriptions import WeatherSubscriptionHandler, FortuneSubscriptionHandler

logger = get_logger(__name__)


@shared_task
def generate_weather_subscription():
    """生成天气订阅消息"""
    db = None
    try:
        db = SessionLocal()
        
        # 获取天气订阅的用户
        weather_subscriptions = db.query(UserSubscription).join(
            SubscriptionType,
            UserSubscription.subscription_type_id == SubscriptionType.id
        ).filter(
            SubscriptionType.name == "天气推送",
            UserSubscription.is_enabled == True
        ).all()
        
        if not weather_subscriptions:
            logger.info("没有启用的天气订阅")
            return {"created_messages": 0, "weather_data": None}
        
        # 使用新的天气订阅处理器
        weather_handler = WeatherSubscriptionHandler()
        result = weather_handler.process_subscriptions(weather_subscriptions, db)
        
        logger.info(f"天气订阅消息生成完成: 创建了 {result['created_count']} 条消息")
        return result
        
    except Exception as e:
        logger.error(f"生成天气订阅消息失败: {e}")
        raise
    finally:
        if db:
            db.close()


@shared_task
def generate_fortune_subscription():
    """生成今日运势订阅消息"""
    db = None
    try:
        db = SessionLocal()
        
        # 获取运势订阅的用户
        fortune_subscriptions = db.query(UserSubscription).join(
            SubscriptionType,
            UserSubscription.subscription_type_id == SubscriptionType.id
        ).filter(
            SubscriptionType.name == "今日运势",
            UserSubscription.is_enabled == True
        ).all()
        
        if not fortune_subscriptions:
            logger.info("没有启用的运势订阅")
            return {"created_messages": 0}
        
        # 使用新的运势订阅处理器
        fortune_handler = FortuneSubscriptionHandler()
        result = fortune_handler.process_subscriptions(fortune_subscriptions, db)
        
        logger.info(f"运势订阅消息生成完成: 创建了 {result['created_count']} 条消息")
        return result
        
    except Exception as e:
        logger.error(f"生成运势订阅消息失败: {e}")
        raise
    finally:
        if db:
            db.close()


@shared_task
def cleanup_old_subscription_messages():
    """清理旧的订阅消息"""
    try:
        db = SessionLocal()
        
        # 删除7天前的订阅消息
        cutoff_date = datetime.utcnow() - timedelta(days=7)
        
        deleted_count = db.query(Message).filter(
            Message.message_type == MessageType.NOTIFICATION,
            Message.created_at < cutoff_date,
            Message.pattern.contains({"source_type": "subscription"})
        ).delete()
        
        db.commit()
        logger.info(f"清理了 {deleted_count} 条旧订阅消息")
        
        return {"deleted_count": deleted_count}
        
    except Exception as e:
        logger.error(f"清理旧订阅消息失败: {e}")
        raise
    finally:
        db.close()