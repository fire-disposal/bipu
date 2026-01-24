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
