from pydantic import BaseModel, EmailStr
from datetime import datetime
from typing import Optional


class UserBase(BaseModel):
    """用户基础模式"""
    email: EmailStr
    username: str
    full_name: Optional[str] = None
    is_active: bool = True
    is_superuser: bool = False


class UserCreate(UserBase):
    """创建用户模式"""
    pass


class UserUpdate(UserBase):
    """更新用户模式"""
    pass


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