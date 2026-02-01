"""根目录路由 - 健康检查、文档等"""

from fastapi import APIRouter
from app.core.config import settings

router = APIRouter()

@router.get("/health", tags=["System"])
async def health_check():
    """系统健康检查"""
    return {"status": "healthy", "service": settings.PROJECT_NAME}

@router.get("/ready", tags=["System"])
async def readiness_check():
    """就绪检查端点"""
    return {"status": "ready"}

@router.get("/live", tags=["System"])
async def liveness_check():
    """存活检查端点"""
    return {"status": "alive"}

@router.get("/", tags=["System"])
async def root():
    """根路径 - 返回API信息"""
    return {
        "message": "Welcome to bipupu API",
        "version": settings.VERSION,
        "project": settings.PROJECT_NAME,
        "docs_url": "/api/docs",
        "redoc_url": "/api/redoc"
    }