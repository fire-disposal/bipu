"""海报Schema - 极简版本，仿照头像存储方式"""
from pydantic import BaseModel, Field
from datetime import datetime
from typing import Optional


class PosterBase(BaseModel):
    """海报基础Schema"""
    title: str = Field(..., min_length=1, max_length=100, description="海报标题")
    link_url: Optional[str] = Field(None, max_length=500, description="点击跳转链接")
    display_order: int = Field(default=0, ge=0, description="显示顺序，数字越小越靠前")
    is_active: bool = Field(default=True, description="是否激活")


class PosterCreate(PosterBase):
    """创建海报Schema"""
    # 图像数据将通过文件上传单独处理


class PosterUpdate(BaseModel):
    """更新海报Schema"""
    title: Optional[str] = Field(None, min_length=1, max_length=100, description="海报标题")
    link_url: Optional[str] = Field(None, max_length=500, description="点击跳转链接")
    display_order: Optional[int] = Field(None, ge=0, description="显示顺序")
    is_active: Optional[bool] = Field(None, description="是否激活")


class PosterResponse(PosterBase):
    """海报响应Schema"""
    id: int
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class PosterListResponse(BaseModel):
    """海报列表响应"""
    posters: list[PosterResponse]
    total: int
    page: int
    page_size: int
