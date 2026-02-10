"""根目录路由 - 健康检查、文档等"""

from fastapi import APIRouter
from app.core.config import settings
from app.schemas.common import HealthResponse, ReadyResponse, LiveResponse, ApiInfoResponse

router = APIRouter()

@router.get("/health", response_model=HealthResponse, tags=["系统"])
async def health_check():
    """系统健康检查"""
    return {"status": "healthy", "service": settings.PROJECT_NAME}

@router.get("/ready", response_model=ReadyResponse, tags=["系统"])
async def readiness_check():
    """就绪检查端点"""
    return {"status": "ready"}

@router.get("/live", response_model=LiveResponse, tags=["系统"])
async def liveness_check():
    """存活检查端点"""
    return {"status": "alive"}

@router.get("/", response_model=ApiInfoResponse, tags=["系统"])
async def root():
    """根路径 - 返回API信息"""
    return {
        "message": "欢迎使用 bipupu API",
        "version": settings.VERSION,
        "project": settings.PROJECT_NAME,
        "docs_url": "/api/docs",
        "redoc_url": "/api/redoc",
        "admin_url": "/admin"
    }