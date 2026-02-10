"""模型包初始化 - 确保所有模型正确注册避免循环依赖"""

# 基础导入 - 从独立的base模块导入避免循环依赖
from app.models.base import Base

# 仅保留用户模型作为通用模板
from app.models.user import User
from app.models.message import Message
from app.models.user_block import UserBlock
from app.models.trusted_contact import TrustedContact
from app.models.favorite import Favorite

__all__ = [
    "Base",
    "User",
    "Message",
    "UserBlock",
    "TrustedContact",
    "Favorite",
]