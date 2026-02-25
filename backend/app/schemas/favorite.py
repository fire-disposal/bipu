"""收藏相关数据模型 - 优化版本

设计原则：
1. 精简：只包含必要的字段
2. 一致：统一字段命名规范
3. 实用：优化数据结构，减少嵌套
"""

from pydantic import BaseModel, Field
from datetime import datetime
from typing import Optional, List


class FavoriteCreate(BaseModel):
    """创建收藏请求"""
    note: Optional[str] = Field(None, max_length=200, description="备注")


class FavoriteResponse(BaseModel):
    """收藏响应"""
    id: int
    message_id: int
    note: Optional[str] = Field(None, description="备注")
    created_at: datetime

    # 简化消息信息，只包含必要字段
    message_content: str = Field(..., description="消息内容")
    message_sender: str = Field(..., description="发送者ID")
    message_created_at: datetime = Field(..., description="消息创建时间")

    class Config:
        from_attributes = True


class FavoriteListResponse(BaseModel):
    """收藏列表响应"""
    favorites: List[FavoriteResponse]
    total: int
    page: int = Field(default=1, description="当前页码")
    page_size: int = Field(default=20, description="每页数量")
