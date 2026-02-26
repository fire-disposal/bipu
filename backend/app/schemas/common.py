"""通用数据模型 - 优化版本

设计原则：
1. 精简：只包含必要的字段
2. 一致：统一字段命名规范
3. 实用：优化数据结构，减少冗余
4. 复用：提供可复用的基础模型
"""

from typing import Generic, TypeVar, List, Optional
from pydantic import BaseModel, Field
from fastapi import Query
from app.core.config import settings
import math

T = TypeVar("T")


class PaginationParams:
    """分页参数"""
    def __init__(
        self,
        page: int = Query(1, ge=1, description="页码"),
        size: int = Query(
            settings.DEFAULT_PAGE_SIZE,
            ge=1,
            le=100,
            description="每页数量"
        ),
    ):
        self.page = page
        self.size = size
        self.skip = (page - 1) * size


class PaginatedResponse(BaseModel, Generic[T]):
    """分页响应"""
    items: List[T]
    total: int
    page: int
    size: int
    pages: int

    @classmethod
    def create(cls, items: List[T], total: int, params: PaginationParams) -> "PaginatedResponse[T]":
        """创建分页响应"""
        pages = math.ceil(total / params.size) if params.size > 0 else 0
        return cls(
            items=items,
            total=total,
            page=params.page,
            size=params.size,
            pages=pages
        )


class StatusResponse(BaseModel):
    """状态响应"""
    message: str = Field(..., description="状态消息")
    code: Optional[int] = Field(None, description="状态码")


class HealthResponse(BaseModel):
    """健康检查响应"""
    status: str = Field(..., description="服务状态")
    service: str = Field(..., description="服务名称")
    timestamp: str = Field(..., description="检查时间")


class ReadyResponse(BaseModel):
    """就绪检查响应"""
    status: str = Field(..., description="就绪状态")
    timestamp: str = Field(..., description="检查时间")


class LiveResponse(BaseModel):
    """存活检查响应"""
    status: str = Field(..., description="存活状态")
    timestamp: str = Field(..., description="检查时间")


class ApiInfoResponse(BaseModel):
    """API信息响应"""
    message: str = Field(..., description="欢迎消息")
    version: str = Field(..., description="API版本")
    project: str = Field(..., description="项目名称")
    docs_url: str = Field(..., description="文档URL")
    redoc_url: str = Field(..., description="Redoc文档URL")
    admin_url: str = Field(..., description="管理后台URL")


class ErrorResponse(BaseModel):
    """错误响应"""
    detail: str = Field(..., description="错误详情")
    code: Optional[str] = Field(None, description="错误代码")
    field: Optional[str] = Field(None, description="错误字段")


class SuccessResponse(BaseModel):
    """成功响应"""
    success: bool = Field(default=True, description="是否成功")
    message: str = Field(..., description="成功消息")
    data: Optional[dict] = Field(None, description="响应数据")


class FileUploadResponse(BaseModel):
    """文件上传响应"""
    filename: str = Field(..., description="文件名")
    size: int = Field(..., description="文件大小（字节）")
    content_type: str = Field(..., description="文件类型")
    url: Optional[str] = Field(None, description="文件URL")


class IdResponse(BaseModel):
    """ID响应"""
    id: int = Field(..., description="记录ID")


class CountResponse(BaseModel):
    """计数响应"""
    count: int = Field(..., description="数量")
