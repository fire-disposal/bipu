from pydantic import BaseModel
from typing import Optional, Dict, Any, List
from datetime import datetime

class SubscriptionTypeBase(BaseModel):
    name: str
    description: Optional[str] = None
    category: str
    is_active: bool = True
    default_settings: Dict[str, Any] = {}

class SubscriptionTypeCreate(SubscriptionTypeBase):
    pass

class SubscriptionTypeUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    category: Optional[str] = None
    is_active: Optional[bool] = None
    default_settings: Optional[Dict[str, Any]] = None

class SubscriptionTypeResponse(SubscriptionTypeBase):
    id: int
    created_at: datetime
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True

class UserSubscriptionBase(BaseModel):
    is_enabled: bool = True
    custom_settings: Dict[str, Any] = {}
    notification_time_start: str = "09:00"
    notification_time_end: str = "22:00"
    timezone: str = "Asia/Shanghai"

class UserSubscriptionCreate(UserSubscriptionBase):
    subscription_type_id: int

class UserSubscriptionUpdate(UserSubscriptionBase):
    pass

class UserSubscriptionModelResponse(UserSubscriptionBase):
    id: int
    user_id: int
    subscription_type_id: int
    created_at: datetime
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True

class UserSubscriptionResponse(BaseModel):
    subscription_type: SubscriptionTypeResponse
    user_subscription: Optional[UserSubscriptionModelResponse] = None
    is_subscribed: bool


class SubscribeRequest(BaseModel):
    """订阅请求"""
    is_enabled: bool = True
    custom_settings: Optional[Dict[str, Any]] = None
    notification_time_start: Optional[str] = "09:00"
    notification_time_end: Optional[str] = "22:00"
    timezone: Optional[str] = "Asia/Shanghai"


class SubscribeResponse(BaseModel):
    """订阅响应"""
    message: str
    subscription: Optional[UserSubscriptionModelResponse] = None


class MySubscriptionItem(BaseModel):
    """我的订阅列表项"""
    subscription_type: SubscriptionTypeResponse
    user_subscription: Optional[UserSubscriptionModelResponse] = None
    is_subscribed: bool

    class Config:
        from_attributes = True


class PopularSubscriptionItem(BaseModel):
    """热门订阅项"""
    id: int
    name: str
    subscriber_count: int


class SubscriptionStatsSummary(BaseModel):
    """订阅统计概要"""
    total: int
    active: int
    inactive: int


class SubscriptionOverviewResponse(BaseModel):
    """订阅系统概览响应"""
    subscription_types: SubscriptionStatsSummary
    user_subscriptions: SubscriptionStatsSummary
    by_category: Dict[str, int]
    popular_subscriptions: List[PopularSubscriptionItem]

