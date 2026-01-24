"""用户设置相关模式"""
from pydantic import BaseModel, Field, validator
from datetime import date, datetime
from typing import Optional, Dict, Any
from enum import Enum


class ProfileVisibility(str, Enum):
    """个人资料可见性"""
    PUBLIC = "public"
    FRIENDS = "friends"
    PRIVATE = "private"


class PrivacySettings(BaseModel):
    """隐私设置"""
    profile_visibility: ProfileVisibility = ProfileVisibility.FRIENDS
    message_protection: bool = True
    cooldown_enabled: bool = True
    cooldown_duration: int = Field(default=300, ge=60, le=3600)  # 60秒到1小时
    
    @validator('cooldown_duration')
    def validate_cooldown_duration(cls, v):
        if v < 60 or v > 3600:
            raise ValueError('冷却时间必须在60秒到1小时之间')
        return v


class SubscriptionSettings(BaseModel):
    """订阅设置"""
    cosmic_messaging: bool = True
    notification_time_start: str = Field(default="09:00", pattern=r"^([01]\d|2[0-3]):([0-5]\d)$")
    notification_time_end: str = Field(default="22:00", pattern=r"^([01]\d|2[0-3]):([0-5]\d)$")
    timezone: str = "Asia/Shanghai"
    
    @validator('notification_time_end')
    def validate_time_range(cls, v, values):
        if 'notification_time_start' in values and v <= values['notification_time_start']:
            raise ValueError('结束时间必须晚于开始时间')
        return v


class CosmicProfile(BaseModel):
    """宇宙传讯信息"""
    energy_type: Optional[str] = Field(None, max_length=50)
    life_path: Optional[str] = Field(None, max_length=50)
    soul_urge: Optional[str] = Field(None, max_length=50)
    destiny_number: Optional[int] = Field(None, ge=1, le=9)
    personal_year: Optional[int] = Field(None, ge=1, le=9)


class BirthChart(BaseModel):
    """生辰八字"""
    year: Optional[str] = Field(None, max_length=10)
    month: Optional[str] = Field(None, max_length=10)
    day: Optional[str] = Field(None, max_length=10)
    hour: Optional[str] = Field(None, max_length=10)
    element: Optional[str] = Field(None, max_length=10)
    animal: Optional[str] = Field(None, max_length=10)


class UserProfileUpdate(BaseModel):
    """用户资料更新"""
    nickname: Optional[str] = Field(None, max_length=50)
    full_name: Optional[str] = Field(None, max_length=100)
    avatar_url: Optional[str] = Field(None, max_length=500)
    birth_date: Optional[date] = None
    zodiac_sign: Optional[str] = Field(None, max_length=20)
    mbti_type: Optional[str] = Field(None, max_length=10)
    birth_chart: Optional[BirthChart] = None
    cosmic_profile: Optional[CosmicProfile] = None
    privacy_settings: Optional[PrivacySettings] = None
    subscription_settings: Optional[SubscriptionSettings] = None


class UserProfileResponse(BaseModel):
    """用户资料响应"""
    id: int
    email: str
    username: str
    nickname: Optional[str]
    full_name: Optional[str]
    avatar_url: Optional[str]
    birth_date: Optional[date]
    zodiac_sign: Optional[str]
    mbti_type: Optional[str]
    birth_chart: Optional[BirthChart]
    cosmic_profile: Optional[CosmicProfile]
    privacy_settings: PrivacySettings
    subscription_settings: SubscriptionSettings
    terms_accepted: bool
    terms_accepted_at: Optional[datetime]
    is_active: bool
    role: str
    last_active: Optional[datetime]
    created_at: datetime
    updated_at: Optional[datetime]

    class Config:
        from_attributes = True


class UserSettingsUpdate(BaseModel):
    """用户设置更新"""
    privacy_settings: Optional[PrivacySettings] = None
    subscription_settings: Optional[SubscriptionSettings] = None


class PasswordChange(BaseModel):
    """密码修改"""
    current_password: str = Field(..., min_length=6, max_length=128)
    new_password: str = Field(..., min_length=6, max_length=128)
    
    @validator('new_password')
    def validate_new_password(cls, v, values):
        if 'current_password' in values and v == values['current_password']:
            raise ValueError('新密码不能与当前密码相同')
        return v


class TermsAcceptance(BaseModel):
    """用户协议接受"""
    accepted: bool = True
    ip_address: Optional[str] = None
    user_agent: Optional[str] = None


class BlockUserRequest(BaseModel):
    """拉黑用户请求"""
    user_id: int
    reason: Optional[str] = Field(None, max_length=500)


class BlockedUserResponse(BaseModel):
    """被拉黑用户响应"""
    id: int
    username: str
    nickname: Optional[str]
    avatar_url: Optional[str]
    blocked_at: datetime

    class Config:
        from_attributes = True


class UserBlockList(BaseModel):
    """用户黑名单列表"""
    items: list[BlockedUserResponse]
    total: int
    page: int
    size: int


class ExportMessagesRequest(BaseModel):
    """导出消息请求"""
    message_type: Optional[str] = None  # sent, received, all
    date_from: Optional[datetime] = None
    date_to: Optional[datetime] = None
    format: str = Field(default="json", pattern=r"^(json|csv|txt)$")
    include_content: bool = True
    include_metadata: bool = True


class ExportMessagesResponse(BaseModel):
    """导出消息响应"""
    download_url: str
    file_size: int
    record_count: int
    expires_at: datetime


class MessageStatsRequest(BaseModel):
    """消息统计请求"""
    date_from: Optional[datetime] = None
    date_to: Optional[datetime] = None
    group_by: str = Field(default="day", pattern=r"^(day|week|month)$")


class MessageStatsResponse(BaseModel):
    """消息统计响应"""
    total_sent: int
    total_received: int
    total_favorites: int
    by_type: Dict[str, int]
    by_date: Dict[str, int]