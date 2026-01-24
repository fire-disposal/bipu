from abc import ABC, abstractmethod
from datetime import datetime
from typing import Dict, Any, Optional
from sqlalchemy.orm import Session
from app.models.subscription import UserSubscription
from app.core.logging import get_logger

class BaseSubscriptionHandler(ABC):
    """订阅处理器基类"""
    
    def __init__(self, category: str):
        self.category = category
        self.logger = get_logger(__name__)
    
    def is_within_notification_window(self, subscription: UserSubscription) -> bool:
        """检查当前时间是否在通知时间范围内"""
        try:
            current_time = datetime.now().time()
            start_time = datetime.strptime(subscription.notification_time_start, "%H:%M").time()
            end_time = datetime.strptime(subscription.notification_time_end, "%H:%M").time()
            
            if start_time <= end_time:
                return start_time <= current_time <= end_time
            else:
                # 跨午夜的情况 (e.g. 22:00 - 06:00)
                return current_time >= start_time or current_time <= end_time
        except Exception as e:
            self.logger.error(f"检查通知时间窗口失败: {e}")
            return False

    @abstractmethod
    def generate_message_data(self, user_id: int, subscription: UserSubscription, db: Session) -> Optional[Dict[str, Any]]:
        """生成消息数据
        
        Returns:
            Optional[Dict[str, Any]]: 返回构建好的消息字典，如果不需要发送则返回 None
            字典结构应包含: title, content, pattern (可选), category (可选)
        """
        pass
