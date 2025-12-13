"""通知相关模式"""
from pydantic import BaseModel, Field, EmailStr
from datetime import datetime
from typing import Optional, Dict, Any
from enum import Enum


class NotificationType(str, Enum):
    """通知类型"""
    PUSH = "push"
    EMAIL = "email"
    SMS = "sms"
    WEBHOOK = "webhook"


class NotificationStatus(str, Enum):
    """通知状态"""
    PENDING = "pending"
    SENT = "sent"
    FAILED = "failed"
    CANCELLED = "cancelled"


class NotificationBase(BaseModel):
    """通知基础模式"""
    title: str = Field(..., min_length=1, max_length=200)
    content: str = Field(..., min_length=1)
    notification_type: NotificationType
    priority: int = Field(default=0, ge=0, le=10)
    target: str = Field(..., min_length=1, max_length=500)
    config: Optional[Dict[str, Any]] = None
    scheduled_at: Optional[datetime] = None
    message_id: Optional[int] = None


class NotificationCreate(NotificationBase):
    """创建通知模式"""
    pass


class NotificationUpdate(BaseModel):
    """更新通知模式"""
    title: Optional[str] = Field(None, min_length=1, max_length=200)
    content: Optional[str] = Field(None, min_length=1)
    notification_type: Optional[NotificationType] = None
    priority: Optional[int] = Field(None, ge=0, le=10)
    status: Optional[NotificationStatus] = None
    target: Optional[str] = Field(None, min_length=1, max_length=500)
    config: Optional[Dict[str, Any]] = None
    scheduled_at: Optional[datetime] = None
    retry_count: Optional[int] = Field(None, ge=0)
    result: Optional[str] = None
    error_message: Optional[str] = None


class NotificationResponse(NotificationBase):
    """通知响应模式"""
    id: int
    user_id: int
    status: NotificationStatus
    retry_count: int
    max_retries: int
    created_at: datetime
    updated_at: Optional[datetime] = None
    sent_at: Optional[datetime] = None
    result: Optional[str] = None
    error_message: Optional[str] = None
    
    class Config:
        from_attributes = True


class NotificationList(BaseModel):
    """通知列表响应模式"""
    items: list[NotificationResponse]
    total: int
    page: int
    size: int


class NotificationStats(BaseModel):
    """通知统计信息"""
    total: int
    pending: int
    sent: int
    failed: int
    cancelled: int
    by_type: dict


class EmailNotification(BaseModel):
    """邮件通知模式"""
    to_email: EmailStr
    subject: str
    body: str
    html_body: Optional[str] = None


class PushNotification(BaseModel):
    """推送通知模式"""
    device_token: str
    title: str
    body: str
    data: Optional[Dict[str, Any]] = None


class SMSNotification(BaseModel):
    """短信通知模式"""
    phone_number: str
    message: str


class WebhookNotification(BaseModel):
    """Webhook通知模式"""
    url: str
    method: str = "POST"
    headers: Optional[Dict[str, str]] = None
    body: Optional[Dict[str, Any]] = None