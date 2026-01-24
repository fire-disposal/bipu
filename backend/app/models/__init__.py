"""模型包初始化 - 确保所有模型正确注册避免循环依赖"""

# 基础导入 - 从独立的base模块导入避免循环依赖
from app.models.base import Base

# 仅保留用户模型作为通用模板
from app.models.user import User
from app.models.adminlog import AdminLog
from app.models.friendship import Friendship, FriendshipStatus
from app.models.message import Message, MessageType, MessageStatus
from app.models.messageackevent import MessageAckEvent
from app.models.message_favorite import MessageFavorite
from app.models.subscription import SubscriptionType, UserSubscription
from app.models.user_block import UserBlock

__all__ = [
    "Base",
    "User",
    "AdminLog",
    "Friendship", "FriendshipStatus",
    "Message", "MessageType", "MessageStatus",
    "MessageAckEvent",
    "MessageFavorite",
    "SubscriptionType", "UserSubscription",
    "UserBlock",
]