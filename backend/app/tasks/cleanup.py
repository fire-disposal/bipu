"""清理任务"""
from datetime import datetime, timedelta
from sqlalchemy import and_
from celery import shared_task
from app.db.database import SessionLocal
from app.models.message import Message, MessageStatus
from app.models.notification import Notification, NotificationStatus
from app.core.logging import get_logger

logger = get_logger(__name__)


@shared_task
def cleanup_old_messages():
    """清理旧消息（保留30天）"""
    try:
        db = SessionLocal()
        
        # 计算30天前的日期
        cutoff_date = datetime.utcnow() - timedelta(days=30)
        
        # 删除30天前已读的消息
        deleted_count = db.query(Message).filter(
            and_(
                Message.is_read == True,
                Message.created_at < cutoff_date
            )
        ).delete()
        
        db.commit()
        logger.info(f"清理了 {deleted_count} 条旧消息")
        
        return {"deleted_messages": deleted_count}
        
    except Exception as e:
        logger.error(f"清理旧消息失败: {e}")
        raise
    finally:
        db.close()


@shared_task
def cleanup_old_notifications():
    """清理旧通知（保留7天）"""
    try:
        db = SessionLocal()
        
        # 计算7天前的日期
        cutoff_date = datetime.utcnow() - timedelta(days=7)
        
        # 删除7天前已发送或已取消的通知
        deleted_count = db.query(Notification).filter(
            and_(
                Notification.status.in_([NotificationStatus.SENT, NotificationStatus.CANCELLED]),
                Notification.created_at < cutoff_date
            )
        ).delete()
        
        db.commit()
        logger.info(f"清理了 {deleted_count} 条旧通知")
        
        return {"deleted_notifications": deleted_count}
        
    except Exception as e:
        logger.error(f"清理旧通知失败: {e}")
        raise
    finally:
        db.close()


@shared_task
def cleanup_failed_notifications():
    """清理失败的通知（保留3天）"""
    try:
        db = SessionLocal()
        
        # 计算3天前的日期
        cutoff_date = datetime.utcnow() - timedelta(days=3)
        
        # 删除3天前失败的通知
        deleted_count = db.query(Notification).filter(
            and_(
                Notification.status == NotificationStatus.FAILED,
                Notification.created_at < cutoff_date
            )
        ).delete()
        
        db.commit()
        logger.info(f"清理了 {deleted_count} 条失败通知")
        
        return {"deleted_failed_notifications": deleted_count}
        
    except Exception as e:
        logger.error(f"清理失败通知失败: {e}")
        raise
    finally:
        db.close()