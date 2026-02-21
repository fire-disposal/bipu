from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime, time

class ServiceAccountBase(BaseModel):
    name: str
    description: Optional[str] = None
    avatar_url: Optional[str] = None
    is_active: bool = True

class ServiceAccountResponse(ServiceAccountBase):
    id: int
    created_at: datetime
    updated_at: Optional[datetime] = None


    class Config:
        from_attributes = True

class ServiceAccountList(BaseModel):
    items: List[ServiceAccountResponse]
    total: int


class SubscriptionSettingsBase(BaseModel):
    """订阅设置基础模型"""
    push_time: Optional[str] = Field(None, description="推送时间，格式: HH:MM", pattern=r'^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$')
    is_enabled: Optional[bool] = Field(True, description="是否启用推送")


class SubscriptionSettingsUpdate(SubscriptionSettingsBase):
    """更新订阅设置"""
    pass


class SubscriptionSettingsResponse(SubscriptionSettingsBase):
    """订阅设置响应"""
    service_name: str
    service_description: Optional[str]
    subscribed_at: datetime
    updated_at: Optional[datetime]
    push_time_source: Optional[str] = Field(None, description="推送时间来源: subscription(订阅设置), service_default(服务号默认), none(无)")


class UserSubscriptionResponse(BaseModel):
    """用户订阅详情响应"""
    service: ServiceAccountResponse
    settings: SubscriptionSettingsResponse


class UserSubscriptionList(BaseModel):
    """用户订阅列表响应"""
    subscriptions: List[UserSubscriptionResponse]
    total: int
