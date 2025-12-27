"""统一的消息构建器"""
from typing import Dict, Optional, Any
from app.models.message import Message, MessageType, MessageStatus
from app.core.logging import get_logger


class NotificationMessageBuilder:
    """统一的消息构建器
    
    提供标准化的消息构建流程，确保所有消息格式一致。
    """
    
    logger = get_logger(__name__)
    
    # 消息标题最大长度
    MAX_TITLE_LENGTH = 200
    # 消息内容最大长度
    MAX_CONTENT_LENGTH = 5000
    # 优先级范围
    MIN_PRIORITY = 0
    MAX_PRIORITY = 10
    
    @staticmethod
    def build(
        title: str,
        content: str,
        receiver_id: int,
        subscription_type: str,
        subscription_id: int,
        priority: int = 3,
        rgb: Optional[Dict[str, int]] = None,
        vibe: Optional[Dict[str, int]] = None,
        custom_data: Optional[Dict[str, Any]] = None
    ) -> Message:
        """构建标准化的消息对象
        
        Args:
            title: 消息标题
            content: 消息内容
            receiver_id: 接收者 ID
            subscription_type: 订阅类型（如 "weather", "fortune"）
            subscription_id: 订阅 ID
            priority: 优先级（0-10，默认 3）
            rgb: RGB 颜色，格式 {"r": 255, "g": 100, "b": 100}（可选）
            vibe: 振动模式，格式 {"intensity": 50, "duration": 2000}（可选）
            custom_data: 自定义数据（可选）
            
        Returns:
            Message: 构建好的消息对象
            
        Raises:
            ValueError: 如果输入验证失败
        """
        # 验证标题
        if not title or not isinstance(title, str):
            raise ValueError("标题必须是非空字符串")
        if len(title) > NotificationMessageBuilder.MAX_TITLE_LENGTH:
            raise ValueError(f"标题长度不能超过 {NotificationMessageBuilder.MAX_TITLE_LENGTH} 个字符")
        
        # 验证内容
        if not content or not isinstance(content, str):
            raise ValueError("内容必须是非空字符串")
        if len(content) > NotificationMessageBuilder.MAX_CONTENT_LENGTH:
            raise ValueError(f"内容长度不能超过 {NotificationMessageBuilder.MAX_CONTENT_LENGTH} 个字符")
        
        # 验证优先级
        if not isinstance(priority, int) or not (
            NotificationMessageBuilder.MIN_PRIORITY <= priority <= NotificationMessageBuilder.MAX_PRIORITY
        ):
            raise ValueError(
                f"优先级必须是 {NotificationMessageBuilder.MIN_PRIORITY}-"
                f"{NotificationMessageBuilder.MAX_PRIORITY} 之间的整数"
            )
        
        # 验证 RGB
        if rgb is not None:
            if not isinstance(rgb, dict):
                raise ValueError("RGB 必须是字典格式")
            required_keys = {"r", "g", "b"}
            if not all(key in rgb for key in required_keys):
                raise ValueError(f"RGB 必须包含 {required_keys} 键")
            for key, value in rgb.items():
                if not isinstance(value, int) or not (0 <= value <= 255):
                    raise ValueError(f"RGB 值必须是 0-255 之间的整数，{key}={value}")
        
        # 验证振动
        if vibe is not None:
            if not isinstance(vibe, dict):
                raise ValueError("振动必须是字典格式")
            if "intensity" in vibe:
                if not isinstance(vibe["intensity"], int) or not (0 <= vibe["intensity"] <= 100):
                    raise ValueError("振动强度必须是 0-100 之间的整数")
            if "duration" in vibe:
                if not isinstance(vibe["duration"], int) or vibe["duration"] <= 0:
                    raise ValueError("振动持续时间必须是正整数（毫秒）")
        
        # 验证接收者 ID
        if not isinstance(receiver_id, int) or receiver_id <= 0:
            raise ValueError("接收者 ID 必须是正整数")
        
        # 验证订阅 ID
        if not isinstance(subscription_id, int) or subscription_id <= 0:
            raise ValueError("订阅 ID 必须是正整数")
        
        # 构建标准 pattern
        pattern = {
            "source_type": "subscription",
            "source_id": subscription_id,
            "subscription_type": subscription_type,
            "rgb": rgb or {"r": 100, "g": 150, "b": 200},
            "vibe": vibe or {"intensity": 30, "duration": 1500},
            **(custom_data or {})
        }
        
        # 构建消息对象
        message = Message(
            title=title.strip(),
            content=content.strip(),
            message_type=MessageType.NOTIFICATION,
            status=MessageStatus.UNREAD,
            priority=priority,
            sender_id=1,  # 系统用户 ID
            receiver_id=receiver_id,
            pattern=pattern
        )
        
        NotificationMessageBuilder.logger.debug(
            f"消息构建成功: title={title}, receiver_id={receiver_id}, subscription_type={subscription_type}"
        )
        
        return message
