from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.db.database import get_db
from app.services.stats_service import StatsService

router = APIRouter()


@router.get("/")
async def health_check(db: Session = Depends(get_db)):
    """健康检查端点"""
    return await StatsService.check_system_health(db)


@router.get("/ready")
async def readiness_check():
    """就绪检查端点"""
    return {"status": "ready"}


@router.get("/live")
async def liveness_check():
    """存活检查端点"""
    return {"status": "alive"}