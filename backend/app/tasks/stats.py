from celery import shared_task
from sqlalchemy import func
from app.db.database import SessionLocal
from app.models.user import User
from app.core.logging import get_logger

logger = get_logger(__name__)


@shared_task(name="stats.user_counts")
def user_counts() -> dict:
    """统计用户数量，用于后台仪表盘或健康检查"""
    db = SessionLocal()
    try:
        from app.services.stats_service import StatsService
        result = StatsService.get_simple_user_counts(db)
        logger.info(f"User stats - total:{result['total']}, active:{result['active']}, superusers:{result['superusers']}")
        return result
    except Exception as e:
        logger.error(f"Failed to gather user counts: {e}")
        raise
    finally:
        db.close()
