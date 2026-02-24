from pydantic import BaseModel, Field
from datetime import datetime, date
from typing import Optional, Dict, Any, List


class CosmicProfile(BaseModel):
    """结构化的宇宙信息（可在未来扩展）"""
    birthday: Optional[date] = Field(None, description="公历生日，格式 YYYY-MM-DD")
    zodiac: Optional[str] = Field(None, description="西方星座，例如 '白羊座'")
    age: Optional[int] = Field(None, description="年龄（整数岁）")
    bazi: Optional[str] = Field(None, description="生辰八字字符串（可由用户提供或第三方服务计算）")
    gender: Optional[str] = Field(None, description="性别，例如 'male','female','other'，可选")
    mbti: Optional[str] = Field(None, description="MBTI 类型，例如 'INTJ'")
    birth_time: Optional[str] = Field(None, description="出生时间，例如 '08:30'")
    birthplace: Optional[str] = Field(None, description="出生地，城市/经纬度等")


class UserBase(BaseModel):
    """用户基础模式"""
    username: str
    bipupu_id: str
    nickname: Optional[str] = None
    avatar_url: Optional[str] = None
    cosmic_profile: Optional[CosmicProfile] = None
    is_active: bool = True
    is_superuser: bool = False
    last_active: Optional[datetime] = Field(None, description="最后活跃时间")



class UserCreate(BaseModel):
    """创建用户模式"""
    username: str
    password: str = Field(..., min_length=6, max_length=128)
    nickname: Optional[str] = None


class UserUpdate(BaseModel):
    """更新用户模式"""
    nickname: Optional[str] = None
    cosmic_profile: Optional[Dict[str, Any]] = None


class UserPasswordUpdate(BaseModel):
    """用户密码更新"""
    old_password: str
    new_password: str = Field(..., min_length=6, max_length=128)





class TimezoneUpdate(BaseModel):
    """时区更新"""
    timezone: str = Field(
        ...,
        description="时区标识符，例如 'Asia/Shanghai', 'America/New_York', 'Europe/London'",
        examples=["Asia/Shanghai", "America/New_York", "Europe/London", "UTC"]
    )


class UserResponse(UserBase):
    """用户响应模式"""
    id: int
    created_at: datetime
    updated_at: Optional[datetime] = None
    avatar_version: int = Field(default=0, description="头像版本号，用于缓存失效")

    class Config:
        from_attributes = True


class UserList(BaseModel):
    """用户列表响应模式"""
    items: list[UserResponse]
    total: int
    page: int
    size: int


class UserLogin(BaseModel):
    """用户登录模式"""
    username: str
    password: str


class Token(BaseModel):
    """OAuth 2.0标准令牌响应模式"""
    access_token: str
    refresh_token: Optional[str] = None
    token_type: str = "bearer"
    expires_in: int
    # scope: Optional[str] = None  # 可选：权限范围


class TokenRefresh(BaseModel):
    """刷新令牌模式"""
    refresh_token: str


class TokenData(BaseModel):
    """令牌数据模式"""
    username: Optional[str] = None


class JWTPayload(BaseModel):
    """JWT载荷模式"""
    sub: str
    exp: int
    type: str


class UserStatusUpdate(BaseModel):
    """用户状态更新请求"""
    is_active: bool


class BlockUserRequest(BaseModel):
    """黑名单用户请求"""
    bipupu_id: str


class BlockedUserResponse(BaseModel):
    """被拉黑用户响应模型"""
    id: int
    bipupu_id: str
    username: str
    nickname: Optional[str] = None
    avatar_url: Optional[str] = None
    blocked_at: datetime
