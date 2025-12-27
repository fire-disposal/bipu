"""订阅处理器基类"""
from abc import ABC, abstractmethod
from datetime import datetime, time
from typing import Dict, Any, List
from sqlalchemy.orm import Session
from app.models.subscription import UserSubscription
from app.models.message import Message, MessageType, MessageStatus
from app.core.logging import get_logger


class BaseSubscriptionHandler(ABC):
    """所有订阅处理器的基类
    
    提供通用的订阅处理流程，具体的订阅类型需要继承此类并实现 generate_message_data 方法。
    """
    
    def __init__(self, subscription_type_name: str):
        """
        初始化订阅处理器
        
        Args:
            subscription_type_name: 订阅类型名称（如 "天气推送", "今日运势"）
        """
        self.subscription_type_name = subscription_type_name
        self.logger = get_logger(__name__)
    
    def is_within_notification_window(self, subscription: UserSubscription) -> bool:
        """检查当前时间是否在通知时间范围内
        
        支持跨午夜的时间范围（例如 22:00 - 06:00）
        
        Args:
            subscription: 用户订阅对象
            
        Returns:
            bool: 是否在通知时间范围内
        """
        try:
            # 获取当前时间
            current_time = datetime.now().time()
            
            # 解析通知时间范围
            start_time = datetime.strptime(subscription.notification_time_start, "%H:%M").time()
            end_time = datetime.strptime(subscription.notification_time_end, "%H:%M").time()
            
            # 检查时间范围
            if start_time <= end_time:
                # 正常范围（不跨午夜）
                return start_time <= current_time <= end_time
            else:
                # 跨午夜范围（例如 22:00 - 06:00）
                return current_time >= start_time or current_time <= end_time
                
        except Exception as e:
            self.logger.error(f"时间范围检查失败 (user_id={subscription.user_id}): {e}", exc_info=True)
            return False
    
    @abstractmethod
    def generate_message_data(
        self,
        user_id: int,
        subscription: UserSubscription,
        db: Session
    ) -> Dict[str, Any]:
        """生成订阅消息数据，子类必须实现
        
        Args:
            user_id: 用户 ID
            subscription: 用户订阅对象
            db: 数据库会话
            
        Returns:
            dict: 消息数据，包含以下字段：
                - title: 消息标题（必需）
                - content: 消息内容（必需）
                - priority: 优先级（可选，默认 3）
                - pattern: 消息模式（可选）
                
        Raises:
            ValueError: 如果生成消息数据失败
        """
        pass
    
    def process_subscriptions(self, subscriptions: List[UserSubscription], db: Session) -> Dict[str, Any]:
        """处理订阅的通用流程
        
        Args:
            subscriptions: 用户订阅列表
            db: 数据库会话
            
        Returns:
            dict: 处理结果，包含：
                - created_count: 成功创建的消息数
                - failed_count: 失败数
                - total_processed: 处理的总数
        """
        created_count = 0
        failed_count = 0
        
        for subscription in subscriptions:
            # 跳过已禁用的订阅
            if not subscription.is_enabled:
                self.logger.debug(f"用户 {subscription.user_id} 的订阅已禁用")
                continue
            
            # 检查是否在通知时间范围内
            if not self.is_within_notification_window(subscription):
                self.logger.debug(
                    f"用户 {subscription.user_id} 不在通知时间范围内 "
                    f"({subscription.notification_time_start}-{subscription.notification_time_end})"
                )
                continue
            
            try:
                # 获取订阅类型的具体数据
                message_data = self.generate_message_data(subscription.user_id, subscription, db)
                
                # 创建并保存消息
                message = self._create_message(subscription, message_data)
                db.add(message)
                created_count += 1
                
            except Exception as e:
                self.logger.error(
                    f"处理用户 {subscription.user_id} 的 {self.subscription_type_name} 订阅失败: {e}",
                    exc_info=True
                )
                failed_count += 1
                continue
        
        try:
            db.commit()
        except Exception as e:
            self.logger.error(f"提交数据库事务失败: {e}", exc_info=True)
            db.rollback()
            raise
        
        return {
            "created_count": created_count,
            "failed_count": failed_count,
            "total_processed": len(subscriptions),
            "subscription_type": self.subscription_type_name
        }
    
    def _create_message(self, subscription: UserSubscription, message_data: Dict[str, Any]) -> Message:
        """创建消息对象
        
        Args:
            subscription: 用户订阅对象
            message_data: 消息数据
            
        Returns:
            Message: 消息对象
        """
        return Message(
            title=message_data["title"],
            content=message_data["content"],
            message_type=MessageType.NOTIFICATION,
            status=MessageStatus.UNREAD,
            priority=message_data.get("priority", 3),
            sender_id=1,  # 系统用户 ID
            receiver_id=subscription.user_id,
            pattern=message_data.get("pattern", {})
        )
