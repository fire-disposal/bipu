from fastapi import APIRouter, Depends
from sqlalchemy import text
from sqlalchemy.orm import Session

from app.db.database import get_db, get_redis
from app.core.logging import get_logger

router = APIRouter()
logger = get_logger(__name__)


@router.get("/")
async def health_check(db: Session = Depends(get_db)):
    """健康检查端点"""
    try:
        # 检查数据库连接
        db.execute(text("SELECT 1"))
        
        # 检查Redis连接
        redis_client = await get_redis()
        await redis_client.ping()
        
        return {
            "status": "healthy",
            "database": "connected",
            "redis": "connected",
            "service": "bipupu-backend"
        }
    except Exception as e:
        logger.error(f"Health check failed: {e}")
        return {
            "status": "unhealthy",
            "error": str(e),
            "service": "bipupu-backend"
        }


@router.get("/ready")
async def readiness_check():
    """就绪检查端点"""
    return {"status": "ready"}


@router.get("/live")
async def liveness_check():
    """存活检查端点"""
    return {"status": "alive"}