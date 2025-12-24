"""消息相关模式"""
from pydantic import BaseModel, Field
from datetime import datetime
from typing import Optional
from enum import Enum


class MessageType(str, Enum):
    """消息类型"""
    SYSTEM = "system"
    DEVICE = "device"
    USER = "user"
    ALERT = "alert"
    NOTIFICATION = "notification"


class MessageStatus(str, Enum):
    """消息状态"""
    UNREAD = "unread"
    READ = "read"
    ARCHIVED = "archived"


class MessageBase(BaseModel):
    """消息基础模式"""
    title: str = Field(..., min_length=1, max_length=200)
    content: str = Field(..., min_length=1)
    message_type: MessageType
    priority: int = Field(default=0, ge=0, le=10)
    device_id: Optional[int] = None
    pattern: Optional[dict] = None
    sender_id: Optional[int] = None
    receiver_id: Optional[int] = None


class MessageCreate(MessageBase):
    """创建消息模式"""
    pass


class MessageUpdate(BaseModel):
    """更新消息模式"""
    title: Optional[str] = Field(None, min_length=1, max_length=200)
    content: Optional[str] = Field(None, min_length=1)
    message_type: Optional[MessageType] = None
    priority: Optional[int] = Field(None, ge=0, le=10)
    status: Optional[MessageStatus] = None
    is_read: Optional[bool] = None


class MessageResponse(MessageBase):
    """消息响应模式"""
    id: int
    sender_id: int
    receiver_id: int
    status: MessageStatus
    is_read: bool
    created_at: datetime
    updated_at: Optional[datetime] = None
    delivered_at: Optional[datetime] = None
    read_at: Optional[datetime] = None

    class Config:
        from_attributes = True


class MessageList(BaseModel):
    """消息列表响应模式"""
    items: list[MessageResponse]
    total: int
    page: int
    size: int
    unread_count: int


class MessageStats(BaseModel):
    """消息统计信息"""
    total: int
    unread: int
    read: int
    archived: int
    by_type: dict