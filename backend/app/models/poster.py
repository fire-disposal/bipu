"""海报轮播模型 - 极简版本，使用base64存储图像"""
from sqlalchemy import Column, Integer, String, DateTime, Boolean, LargeBinary
from sqlalchemy.sql import func
from app.models.base import Base
from typing import Optional, Dict, Any


class Poster(Base):
    """海报模型 - 用于前端轮播展示，仿照头像存储方式"""
    __tablename__ = "posters"

    # 主键
    id = Column(Integer, primary_key=True, index=True)

    # 基础信息
    title = Column(String(100), nullable=False, comment="海报标题")

    # 图像存储 - 仿照avatar_data使用LargeBinary
    image_data = Column(LargeBinary, nullable=False, comment="海报图像数据（base64编码）")

    # 链接信息
    link_url = Column(String(500), nullable=True, comment="点击跳转链接")

    # 显示控制
    display_order = Column(Integer, default=0, index=True, comment="显示顺序，数字越小越靠前")
    is_active = Column(Boolean, default=True, index=True, comment="是否激活")

    # 时间戳
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)

    def __repr__(self):
        return f"<Poster(id={self.id}, title='{self.title}', active={self.is_active})>"

    def model_dump(self, **kwargs) -> Dict[str, Any]:
        """将模型转换为字典 - 传统方案，兼容Pydantic v2
        
        返回包含所有字段的字典，image_url 动态生成
        """
        return {
            'id': self.id,
            'title': self.title,
            'link_url': self.link_url,
            'image_url': f"/api/posters/{self.id}/image" if self.id else None,
            'display_order': self.display_order,
            'is_active': self.is_active,
            'created_at': self.created_at,
            'updated_at': self.updated_at
        }
