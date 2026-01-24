from typing import List, Dict, Type
from sqlalchemy.orm import Session
from app.models.subscription import UserSubscription
from app.models.message import Message, MessageType, MessageStatus
from app.core.logging import get_logger
from .handlers.base import BaseSubscriptionHandler
from .handlers.weather import WeatherSubscriptionHandler
from .handlers.fortune import FortuneSubscriptionHandler

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
        
        # 获取系统用户作为发送者 (通常是 ID 1 或第一个超级用户)
        # 这里简化处理，假设 ID 1 是系统管理员
        # 实际生产中建议专门创建一个 "System" 用户
        system_sender_id = 1
        
        for sub in subscriptions:
            try:
                # 1. 获取对应的处理器 (通过 category)
                category = sub.subscription_type.category
                handler = self.handlers.get(category)
                
                if not handler:
                    logger.warning(f"未找到订阅类型处理器: {category}")
                    continue
                
                # 2. 检查时间窗口
                if not handler.is_within_notification_window(sub):
                    continue
                
                # 3. 生成消息数据
                msg_data = handler.generate_message_data(sub.user_id, sub, db)
                if not msg_data:
                    continue
                
                # 4. 创建消息记录
                # 确保 pattern 中包含 source_type
                pattern = msg_data.get("pattern", {})
                if "source_type" not in pattern:
                    pattern["source_type"] = "subscription"
                if "subscription_type" not in pattern:
                    pattern["subscription_type"] = sub.subscription_type.category
                
                message = Message(
                    title=msg_data["title"],
                    content=msg_data["content"],
                    message_type=MessageType.NOTIFICATION,
                    status=MessageStatus.UNREAD,
                    pattern=pattern,
                    category=msg_data.get("category", sub.subscription_type.category), # Default to sub category
                    sender_id=system_sender_id,
                    receiver_id=sub.user_id
                )
                db.add(message)
                created_count += 1

            except Exception as e:
                logger.error(f"处理用户 {sub.user_id} 的订阅 {sub.id} 失败: {e}")
                continue
        
        try:
            db.commit()
        except Exception as e:
            logger.error(f"提交订阅消息失败: {e}")
            db.rollback()
            
        return {"created_count": created_count}
