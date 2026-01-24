from pydantic import BaseModel, EmailStr, Field
from datetime import datetime
from typing import Optional


class UserBase(BaseModel):
    """用户基础模式"""
    email: EmailStr
    username: str
    nickname: Optional[str] = None
    is_active: bool = True
    is_superuser: bool = False
    role: str = Field(default="user", description="角色（user/admin）")
    last_active: Optional[datetime] = Field(None, description="最后活跃时间")


class UserCreate(UserBase):
    """创建用户模式"""
    password: str = Field(..., min_length=6, max_length=128)
    nickname: Optional[str] = None


class UserUpdate(BaseModel):
    """更新用户模式"""
    email: Optional[EmailStr] = None
    username: Optional[str] = None
    nickname: Optional[str] = None
    is_active: Optional[bool] = None
    is_superuser: Optional[bool] = None
    password: Optional[str] = Field(None, min_length=6, max_length=128)


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
    user: Optional[dict] = None


class TokenRefresh(BaseModel):
    """刷新令牌模式"""
    refresh_token: str


class TokenData(BaseModel):
    """令牌数据模式"""
    username: Optional[str] = None


class UserProfile(BaseModel):
    """用户详细资料模式"""
    id: int
    username: str
    email: EmailStr
    nickname: Optional[str]
    is_active: bool
    is_superuser: bool
    role: str
    last_active: Optional[datetime]
    created_at: datetime
    updated_at: Optional[datetime]