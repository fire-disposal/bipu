"""清理任务"""
from datetime import datetime, timedelta
from sqlalchemy import and_
from celery import shared_task
from app.db.database import SessionLocal
from app.models.message import Message, MessageStatus
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
def cleanup_old_system_notifications():
    """清理旧的系统通知（保留7天）"""
    try:
        db = SessionLocal()
        
        # 计算7天前的日期
        cutoff_date = datetime.utcnow() - timedelta(days=7)
        
        # 删除7天前的系统通知（source_type为system的）
        deleted_count = db.query(Message).filter(
            and_(
                Message.message_type == 'notification',
                Message.pattern.contains({"source_type": "system"}),
                Message.created_at < cutoff_date
            )
        ).delete()
        
        db.commit()
        logger.info(f"清理了 {deleted_count} 条旧系统通知")
        
        return {"deleted_system_notifications": deleted_count}
        
    except Exception as e:
        logger.error(f"清理旧系统通知失败: {e}")
        raise
    finally:
        db.close()


@shared_task
def cleanup_old_subscription_messages():
    """清理旧的订阅消息（保留7天）"""
    try:
        db = SessionLocal()
        
        # 计算7天前的日期
        cutoff_date = datetime.utcnow() - timedelta(days=7)
        
        # 删除7天前的订阅消息（source_type为subscription的）
        deleted_count = db.query(Message).filter(
            and_(
                Message.message_type == 'notification',
                Message.pattern.contains({"source_type": "subscription"}),
                Message.created_at < cutoff_date
            )
        ).delete()
        
        db.commit()
        logger.info(f"清理了 {deleted_count} 条旧订阅消息")
        
        return {"deleted_subscription_messages": deleted_count}
        
    except Exception as e:
        logger.error(f"清理旧订阅消息失败: {e}")
        raise
    finally:
        db.close()