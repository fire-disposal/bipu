"""用户相关数据模型 - 优化版本

设计原则：
1. 精简：只包含必要的字段
2. 一致：相同概念的字段使用统一命名
3. 验证：添加必要的验证约束
4. 分层：按使用场景分层设计模型
"""

from pydantic import BaseModel, Field, field_validator
from datetime import datetime, date
from typing import Optional
from enum import Enum


class Gender(str, Enum):
    """性别枚举"""
    MALE = "male"
    FEMALE = "female"
    OTHER = "other"


class MessageType(str, Enum):
    """消息类型枚举"""
    NORMAL = "NORMAL"
    VOICE = "VOICE"
    SYSTEM = "SYSTEM"


class UserBase(BaseModel):
    """用户基础信息（用于内部处理和数据库）"""
    username: str = Field(..., min_length=3, max_length=50, description="用户名")
    bipupu_id: str = Field(..., min_length=1, max_length=100, description="用户唯一标识")
    nickname: Optional[str] = Field(None, max_length=50, description="昵称")


class UserCreate(BaseModel):
    """创建用户请求"""
    username: str = Field(..., min_length=3, max_length=50, description="用户名")
    password: str = Field(..., min_length=6, max_length=128, description="密码")
    nickname: Optional[str] = Field(None, max_length=50, description="昵称")


class UserUpdate(BaseModel):
    """更新用户信息请求"""
    nickname: Optional[str] = Field(None, max_length=50, description="昵称")

    # CosmicProfile字段直接作为用户字段
    birthday: Optional[date] = Field(None, description="公历生日，格式 YYYY-MM-DD")
    zodiac: Optional[str] = Field(None, max_length=10, description="西方星座")
    age: Optional[int] = Field(None, ge=0, le=150, description="年龄")
    bazi: Optional[str] = Field(None, max_length=50, description="生辰八字")
    gender: Optional[Gender] = Field(None, description="性别")
    mbti: Optional[str] = Field(None, max_length=4, description="MBTI类型")
    birth_time: Optional[str] = Field(
        None,
        pattern=r'^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$',
        description="出生时间，格式: HH:MM"
    )
    birthplace: Optional[str] = Field(None, max_length=100, description="出生地")

    @field_validator('mbti')
    @classmethod
    def validate_mbti(cls, v: Optional[str]) -> Optional[str]:
        """验证MBTI格式"""
        if v is None:
            return v
        if len(v) != 4:
            raise ValueError('MBTI必须是4个字符')
        return v.upper()


class UserPasswordUpdate(BaseModel):
    """更新密码请求"""
    old_password: str = Field(..., description="原密码")
    new_password: str = Field(..., min_length=6, max_length=128, description="新密码")


class TimezoneUpdate(BaseModel):
    """更新时区请求"""
    timezone: str = Field(
        ...,
        pattern=r'^[A-Za-z_]+/[A-Za-z_]+$',
        description="时区标识符，如 Asia/Shanghai",
        examples=["Asia/Shanghai", "America/New_York", "Europe/London"]
    )


class UserPublic(BaseModel):
    """用户公开信息（对外API响应）"""
    username: str
    bipupu_id: str
    nickname: Optional[str] = None
    avatar_url: Optional[str] = Field(None, description="头像URL")
    is_active: bool = Field(default=True, description="是否活跃")
    created_at: datetime

    class Config:
        from_attributes = True


class UserPrivate(UserPublic):
    """用户私有信息（对用户自己可见）"""
    # CosmicProfile字段
    birthday: Optional[date] = Field(None, description="公历生日")
    zodiac: Optional[str] = Field(None, description="西方星座")
    age: Optional[int] = Field(None, description="年龄")
    bazi: Optional[str] = Field(None, description="生辰八字")
    gender: Optional[Gender] = Field(None, description="性别")
    mbti: Optional[str] = Field(None, description="MBTI类型")
    birth_time: Optional[str] = Field(None, description="出生时间")
    birthplace: Optional[str] = Field(None, description="出生地")

    last_active: Optional[datetime] = None
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True


class UserLogin(BaseModel):
    """用户登录请求"""
    username: str = Field(..., min_length=3, max_length=50, description="用户名")
    password: str = Field(..., description="密码")


class Token(BaseModel):
    """认证令牌响应"""
    access_token: str = Field(..., description="访问令牌")
    refresh_token: Optional[str] = Field(None, description="刷新令牌")
    token_type: str = Field(default="bearer", description="令牌类型")
    expires_in: int = Field(..., description="过期时间（秒）")


class TokenRefresh(BaseModel):
    """刷新令牌请求"""
    refresh_token: str = Field(..., description="刷新令牌")


class BlockUserRequest(BaseModel):
    """拉黑用户请求"""
    bipupu_id: str = Field(..., description="要拉黑的用户ID")


class BlockedUserResponse(BaseModel):
    """被拉黑用户信息"""
    bipupu_id: str
    username: str
    nickname: Optional[str] = None
    avatar_url: Optional[str] = None
    blocked_at: datetime

    class Config:
        from_attributes = True


class UserList(BaseModel):
    """用户列表响应"""
    items: list[UserPublic]
    total: int
    page: int
    size: int
