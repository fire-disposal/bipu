from pydantic import BaseModel, Field
from datetime import datetime
from typing import Optional, Dict, Any, List


class UserBase(BaseModel):
    """用户基础模式"""
    username: str
    bipupu_id: str
    nickname: Optional[str] = None
    avatar_url: Optional[str] = None
    cosmic_profile: Optional[Dict[str, Any]] = None
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


class UserResponse(UserBase):
    """用户响应模式"""
    id: int
    created_at: datetime
    updated_at: Optional[datetime] = None

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
    """令牌响应模式"""
    access_token: str
    refresh_token: Optional[str] = None
    token_type: str = "bearer"
    expires_in: int
    user: Optional[UserResponse] = None


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
    user_id: int


class BlockedUserResponse(BaseModel):
    """被拉黑用户响应模型"""
    id: int
    bipupu_id: str
    username: str
    nickname: Optional[str] = None
    avatar_url: Optional[str] = None
    blocked_at: datetime