"""模型包初始化 - 确保所有模型正确注册避免循环依赖"""

# 基础导入 - 从独立的base模块导入避免循环依赖
from app.models.base import Base

# 按依赖顺序导入模型 - 避免循环依赖
# 1. 基础模型（无依赖）
from app.models.user import User
from app.models.subscription import SubscriptionType, UserSubscription

# 2. 中间模型（依赖基础模型）
from app.models.message import Message
from app.models.user_block import UserBlock

# 3. 高级模型（依赖中间模型）
from app.models.message_favorite import MessageFavorite
from app.models.messageackevent import MessageAckEvent
from app.models.friendship import Friendship
from app.models.adminlog import AdminLog

# 导出所有模型供外部使用
__all__ = [
    "Base",
    "User",
    "SubscriptionType", 
    "UserSubscription",
    "Message",
    "UserBlock",
    "MessageFavorite",
    "MessageAckEvent",
    "Friendship",
    "AdminLog",
]