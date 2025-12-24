"""站内信相关模式"""
from pydantic import BaseModel, Field
from datetime import datetime
from typing import Optional, Dict, Any
from enum import Enum


class NotificationStatus(str, Enum):
    """站内信状态"""
    UNREAD = "unread"
    READ = "read"
    DELETED = "deleted"


class NotificationBase(BaseModel):
    """站内信基础模式"""
    title: str = Field(..., min_length=1, max_length=200)
    content: str = Field(..., min_length=1)
    priority: int = Field(default=0, ge=0, le=10)
    message_id: Optional[int] = None


class NotificationCreate(NotificationBase):
    """创建站内信模式"""
    pass


class NotificationUpdate(BaseModel):
    """更新站内信模式"""
    title: Optional[str] = Field(None, min_length=1, max_length=200)
    content: Optional[str] = Field(None, min_length=1)
    priority: Optional[int] = Field(None, ge=0, le=10)
    status: Optional[NotificationStatus] = None


class NotificationResponse(NotificationBase):
    """站内信响应模式"""
    id: int
    user_id: int
    status: NotificationStatus
    created_at: datetime
    updated_at: Optional[datetime] = None
    read_at: Optional[datetime] = None
    
    class Config:
        from_attributes = True


class NotificationList(BaseModel):
    """站内信列表响应模式"""
    items: list[NotificationResponse]
    total: int
    page: int
    size: int


class NotificationStats(BaseModel):
    """站内信统计信息"""
    total: int
    unread: int
    read: int
    deleted: int