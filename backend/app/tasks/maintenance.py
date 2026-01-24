from datetime import datetime, timedelta
from celery import shared_task
from app.db.database import SessionLocal
from app.models.adminlog import AdminLog
from app.core.logging import get_logger

logger = get_logger(__name__)


@shared_task(name="maintenance.cleanup_admin_logs")
def cleanup_admin_logs(older_than_days: int = 30) -> int:
    """清理过旧的管理员操作日志，默认保留近30天"""
    cutoff = datetime.utcnow() - timedelta(days=older_than_days)
    db = SessionLocal()
    try:
        deleted = db.query(AdminLog).filter(AdminLog.created_at < cutoff).delete()
        db.commit()
        logger.info(f"Cleaned {deleted} admin logs older than {older_than_days} days")
        return deleted
    except Exception as e:
        db.rollback()
        logger.error(f"Failed to cleanup admin logs: {e}")
        raise
    finally:
        db.close()
