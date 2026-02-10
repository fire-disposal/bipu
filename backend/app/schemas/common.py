from typing import Generic, TypeVar, List
from pydantic import BaseModel
from fastapi import Query
from app.core.config import settings
import math

T = TypeVar("T")

class PaginationParams:
    def __init__(
        self,
        page: int = Query(1, ge=1, description="页码"),
        size: int = Query(settings.DEFAULT_PAGE_SIZE, ge=1, le=100, description="每页数量"),
    ):
        self.page = page
        self.size = size
        self.skip = (page - 1) * size

class PaginatedResponse(BaseModel, Generic[T]):
    items: List[T]
    total: int
    page: int
    size: int
    pages: int

    @classmethod
    def create(cls, items: List[T], total: int, params: PaginationParams) -> "PaginatedResponse[T]":
        pages = math.ceil(total / params.size) if params.size > 0 else 0
        return cls(
            items=items,
            total=total,
            page=params.page,
            size=params.size,
            pages=pages
        )

class StatusResponse(BaseModel):
    """通用状态响应"""
    message: str

class HealthResponse(BaseModel):
    """健康检查响应"""
    status: str
    service: str

class ReadyResponse(BaseModel):
    """就绪检查响应"""
    status: str

class LiveResponse(BaseModel):
    """存活检查响应"""
    status: str

class ApiInfoResponse(BaseModel):
    """根路径 API 信息响应"""
    message: str
    version: str
    project: str
    docs_url: str
    redoc_url: str