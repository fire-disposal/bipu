"""服务号相关数据模型 - 优化版本

设计原则：
1. 精简：只包含必要的字段
2. 一致：统一字段命名规范
3. 验证：添加必要的验证约束
4. 实用：优化数据结构，减少冗余
"""

from pydantic import BaseModel, Field
from datetime import datetime
from typing import Optional, List
from enum import Enum


class PushTimeSource(str, Enum):
    """推送时间来源枚举"""
    SUBSCRIPTION = "subscription"  # 用户订阅设置
    SERVICE_DEFAULT = "service_default"  # 服务号默认设置
    NONE = "none"  # 无推送时间


class ServiceAccountBase(BaseModel):
    """服务号基础信息"""
    name: str = Field(..., min_length=1, max_length=50, description="服务号名称")
    description: Optional[str] = Field(None, max_length=200, description="服务号描述")
    avatar_url: Optional[str] = Field(None, description="头像URL")
    is_active: bool = Field(default=True, description="是否激活")


class ServiceAccountResponse(ServiceAccountBase):
    """服务号响应"""
    id: int
    created_at: datetime
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True


class ServiceAccountList(BaseModel):
    """服务号列表响应"""
    items: List[ServiceAccountResponse]
    total: int
    page: int = Field(default=1, description="当前页码")
    page_size: int = Field(default=20, description="每页数量")


class SubscriptionSettingsBase(BaseModel):
    """订阅设置基础模型"""
    push_time: Optional[str] = Field(
        None,
        pattern=r'^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$',
        description="推送时间，格式: HH:MM"
    )
    is_enabled: Optional[bool] = Field(default=True, description="是否启用推送")


class SubscriptionSettingsUpdate(SubscriptionSettingsBase):
    """更新订阅设置请求"""
    pass


class SubscriptionSettingsResponse(SubscriptionSettingsBase):
    """订阅设置响应"""
    service_name: str = Field(..., description="服务号名称")
    service_description: Optional[str] = Field(None, description="服务号描述")
    subscribed_at: datetime = Field(..., description="订阅时间")
    updated_at: Optional[datetime] = Field(None, description="最后更新时间")
    push_time_source: PushTimeSource = Field(
        default=PushTimeSource.NONE,
        description="推送时间来源"
    )


class UserSubscriptionResponse(BaseModel):
    """用户订阅详情响应"""
    service: ServiceAccountResponse
    settings: SubscriptionSettingsResponse


class UserSubscriptionList(BaseModel):
    """用户订阅列表响应"""
    subscriptions: List[UserSubscriptionResponse]
    total: int
    page: int = Field(default=1, description="当前页码")
    page_size: int = Field(default=20, description="每页数量")


class SubscribeRequest(BaseModel):
    """订阅服务号请求"""
    push_time: Optional[str] = Field(
        None,
        pattern=r'^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$',
        description="推送时间，格式: HH:MM"
    )
    is_enabled: bool = Field(default=True, description="是否启用推送")
