from typing import List, Dict, Type
import asyncio
from datetime import date
from sqlalchemy.orm import Session
from app.models.subscription import UserSubscription
from app.models.message import Message, MessageType, MessageStatus
from app.core.logging import get_logger
from .handlers.base import BaseSubscriptionHandler
from .handlers.weather import WeatherSubscriptionHandler
from .handlers.fortune import FortuneSubscriptionHandler
from app.services.redis_service import RedisService

logger = get_logger(__name__)

class SubscriptionManager:
    """订阅服务管理器"""
    
    def __init__(self):
        self.handlers: Dict[str, BaseSubscriptionHandler] = {}
        self._register_handlers()
    
    def _register_handlers(self):
        """注册所有订阅处理器"""
        self.register_handler("weather", WeatherSubscriptionHandler())
        self.register_handler("fortune", FortuneSubscriptionHandler())
        
    def register_handler(self, category: str, handler: BaseSubscriptionHandler):
        self.handlers[category] = handler

    def process_subscriptions(self, subscriptions: List[UserSubscription], db: Session) -> Dict[str, int]:
        """处理订阅列表并生成消息"""
        created_count = 0
        system_sender_id = 1  # 系统用户ID
        created_messages: List[Message] = []
        
        for sub in subscriptions:
            try:
                handler = self.handlers.get(sub.subscription_type.category)
                if not handler:
                    logger.warning(f"未找到订阅类型处理器: {sub.subscription_type.category}")
                    continue
                
                if not handler.is_within_notification_window(sub):
                    continue
                
                msg_data = handler.generate_message_data(sub.user_id, sub, db)
                if not msg_data:
                    continue
                
                # 构建消息模式
                pattern = msg_data.get("pattern", {})
                pattern.update({
                    "source_type": "subscription",
                    "subscription_type": sub.subscription_type.category,
                    # 基于(订阅类型, 日期)的简单去重键，避免同日重复推送
                    "dedupe_key": f"{sub.subscription_type.category}:{date.today().isoformat()}",
                    "date": date.today().isoformat(),
                })

                # 去重：同一用户同一订阅类型，同一天仅推送一次
                existing = (
                    db.query(Message.id)
                    .filter(
                        Message.receiver_id == sub.user_id,
                        Message.message_type == MessageType.NOTIFICATION,
                        Message.is_deleted == False,
                        Message.pattern["source_type"].astext == "subscription",
                        Message.pattern["subscription_type"].astext == sub.subscription_type.category,
                        Message.pattern["dedupe_key"].astext == pattern["dedupe_key"],
                    )
                    .first()
                )
                if existing:
                    continue
                
                message = Message(
                    title=msg_data["title"],
                    content=msg_data["content"],
                    message_type=MessageType.NOTIFICATION,
                    status=MessageStatus.UNREAD,
                    pattern=pattern,
                    sender_id=system_sender_id,
                    receiver_id=sub.user_id
                )
                db.add(message)
                # 预分配ID，便于后续发布通知
                db.flush()
                created_messages.append(message)
                created_count += 1

            except Exception as e:
                logger.error(f"处理用户 {sub.user_id} 的订阅 {sub.id} 失败: {e}")
                continue
        
        try:
            db.commit()
        except Exception as e:
            logger.error(f"提交订阅消息失败: {e}")
            db.rollback()
            created_messages = []
            
        # 发布到Redis并增加未读计数（异步）
        for msg in created_messages:
            try:
                asyncio.run(RedisService.publish_message(msg))
                asyncio.run(RedisService.increment_unread_count(msg.receiver_id))
            except Exception as e:
                logger.error(f"发布订阅消息到Redis失败: {e}")

        return {"created_count": created_count}
