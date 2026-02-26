"""海报相关数据模型 - 优化版本

设计原则：
1. 精简：只包含必要的字段
2. 一致：统一字段命名规范
3. 验证：添加必要的验证约束
4. 实用：优化数据结构，减少冗余
5. 轮播友好：支持前端轮播展示，包含必要的排序和激活状态
"""

from pydantic import BaseModel, Field, ConfigDict
from datetime import datetime
from typing import Optional, List


class PosterCreate(BaseModel):
    """创建海报请求"""
    title: str = Field(..., min_length=1, max_length=100, description="海报标题")
    link_url: Optional[str] = Field(None, description="点击跳转链接")
    display_order: int = Field(default=0, ge=0, description="显示顺序")
    is_active: bool = Field(default=True, description="是否激活")


class PosterUpdate(BaseModel):
    """更新海报请求"""
    title: Optional[str] = Field(None, min_length=1, max_length=100, description="海报标题")
    link_url: Optional[str] = Field(None, description="点击跳转链接")
    display_order: Optional[int] = Field(None, ge=0, description="显示顺序")
    is_active: Optional[bool] = Field(None, description="是否激活")


class PosterResponse(BaseModel):
    """海报响应 - 用于前端轮播展示
    
    字段说明：
    - id: 海报唯一标识
    - title: 海报标题
    - link_url: 点击跳转链接（可选）
    - image_url: 海报图片URL（由业务层构建）
    - display_order: 显示顺序（数字越小越靠前）
    - is_active: 是否激活（业务层已过滤）
    - created_at: 创建时间
    - updated_at: 更新时间
    
    注意：
    - 前端轮播接口只返回 is_active=True 的海报
    - image_url 由业务层在构建响应时动态生成
    """
    id: int
    title: str = Field(..., description="海报标题")
    link_url: Optional[str] = Field(None, description="点击跳转链接")
    image_url: Optional[str] = Field(None, description="海报图片URL")
    display_order: int = Field(default=0, description="显示顺序，数字越小越靠前")
    is_active: bool = Field(default=True, description="是否激活")
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)


class PosterListResponse(BaseModel):
    """海报列表响应"""
    posters: List[PosterResponse]
    total: int
    page: int = Field(default=1, description="当前页码")
    page_size: int = Field(default=20, description="每页数量")


class PosterImageUpdate(BaseModel):
    """更新海报图片请求"""
    # 图片将通过文件上传单独处理，这里只定义模型结构
    pass
