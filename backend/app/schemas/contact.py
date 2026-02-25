"""联系人相关数据模型 - 优化版本

设计原则：
1. 精简：只包含必要的字段
2. 一致：统一字段命名规范
3. 验证：添加必要的验证约束
"""

from pydantic import BaseModel, Field
from datetime import datetime
from typing import Optional, List


class ContactCreate(BaseModel):
    """创建联系人请求"""
    contact_id: str = Field(..., min_length=1, max_length=100, description="联系人用户ID")
    alias: Optional[str] = Field(None, max_length=50, description="备注名")


class ContactUpdate(BaseModel):
    """更新联系人请求"""
    alias: Optional[str] = Field(None, max_length=50, description="备注名")


class ContactResponse(BaseModel):
    """联系人响应"""
    id: int
    contact_id: str = Field(..., description="联系人用户ID")
    contact_username: str = Field(..., description="联系人用户名")
    contact_nickname: Optional[str] = Field(None, description="联系人昵称")
    alias: Optional[str] = Field(None, description="备注名")
    created_at: datetime

    class Config:
        from_attributes = True


class ContactListResponse(BaseModel):
    """联系人列表响应"""
    contacts: List[ContactResponse]
    total: int
    page: int = Field(default=1, description="当前页码")
    page_size: int = Field(default=20, description="每页数量")
