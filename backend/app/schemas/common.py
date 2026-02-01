from typing import Generic, TypeVar, List
from pydantic.generics import GenericModel
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

class PaginatedResponse(GenericModel, Generic[T]):
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

class StatusResponse(GenericModel):
    """通用状态响应"""
    message: str

class HealthResponse(GenericModel):
    """健康检查响应"""
    status: str
    service: str

class ReadyResponse(GenericModel):
    """就绪检查响应"""
    status: str

class LiveResponse(GenericModel):
    """存活检查响应"""
    status: str

class ApiInfoResponse(GenericModel):
    """根路径 API 信息响应"""
    message: str
    version: str
    project: str
    docs_url: str
    redoc_url: str

class UserStatsResponse(GenericModel):
    """用户统计响应"""
    total_users: int
    active_users: int
    inactive_users: int
    superusers: int
    today_new_users: int
    recent_active_users_7d: int
    activation_rate: float
